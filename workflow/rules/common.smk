#################
import errno
import multiprocessing
import os.path
import psutil
import yaml as yaml
from snakemake.utils import validate


report: "../report/workflow.rst"

validate(config, schema="../schemas/config.schema.yaml")

with open(config["samples"],'r') as file:
    samples_master = yaml.load(file, Loader=yaml.FullLoader)
    samples_master.keys()
samples=list(samples_master.keys())

def total_physical_mem_size():
    mem = psutil.virtual_memory()
    return mem.total

def cpu_count():
    return multiprocessing.cpu_count()

def expand_filepath(filepath):
    filepath = os.path.expandvars(os.path.expanduser(filepath))
    if not os.path.isabs(filepath):
        raise FileNotFoundError(
            errno.ENOENT, os.strerror(errno.ENOENT)+" (path must be absolute)", filepath)
    return filepath

def conservative_cpu_count(reserve_cores=1, max_cores=5):
    cores = max_cores if cpu_count() > max_cores else cpu_count()
    return max(cores - reserve_cores, 1)

def tmp_path(path=''):
    """
    if does not exists, create path and return it. If any errors, return
    default path
    :param path: path
    :return: path
    """
    default_path = os.getenv('TMPDIR', config.get("processing").get("base_tmp"))
    if path:
        try:
            os.makedirs(path)
        except OSError as e:
            if e.errno != errno.EEXIST:
                return default_path
        return path
    return default_path

def java_params(tmp_dir='', percentage_to_preserve=20, stock_mem=1024 ** 3,
                stock_cpu=2, multiply_by=1):
    """
    Set Java params
    :param tmp_dir: path to tmpdir
    :param percentage_to_preserve: percentage of resources to preserve
    :param stock_mem: min memory to preserve
    :param stock_cpu: min cpu to preserve
    :param multiply_by: multiply base resource by this param
    :return: string to return to configure java environments
    """

    def bytes2human(n):
        # http://code.activestate.com/recipes/578019
        # >>> bytes2human(10000)
        # '9.8K'
        # >>> bytes2human(100001221)
        # '95.4M'
        symbols = ('K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y')
        prefix = {}
        for i, s in enumerate(symbols):
            prefix[s] = 1 << (i + 1) * 10
        for s in reversed(symbols):
            if n >= prefix[s]:
                value = float(n) / prefix[s]
                return '%.0f%s' % (value, s)
        return "%sB" % n

    def preserve(resource, percentage, stock):
        preserved = resource - max(resource * percentage // 100, stock)
        return preserved if preserved != 0 else stock

    # def preserve(resource, percentage, stock):
    #     return resource - max(resource * percentage // 100, stock)

    params_template = "'-Xms{} -Xmx{} -XX:ParallelGCThreads={} " \
                      "-Djava.io.tmpdir={}'"

    mem_min = 1024 ** 3 * 2  # 2GB

    mem_size = preserve(total_physical_mem_size(), percentage_to_preserve,
                        stock_mem)
    cpu_nums = preserve(cpu_count(), percentage_to_preserve, stock_cpu)
    tmpdir = tmp_path(tmp_dir)

    return params_template.format(bytes2human(mem_min).lower(),
                                  bytes2human(max(mem_size//cpu_nums*multiply_by,
                                                  mem_min)).lower(),
                                  min(cpu_nums, multiply_by),
                                  tmpdir)

def references_abs_path(ref='ref'):
    references = config.get(ref)
    basepath = expand_filepath(references['basepath'])
    provider = references['provider']
    release = references['release']

    return [os.path.join(basepath, provider, release)]

def resolve_single_filepath(basepath, filename):
    return [os.path.join(basepath, filename)]

def get_name(inputfile):
    with open(inputfile, 'r') as file:
        data = file.read().rstrip()
    return data

def get_tumoral_bam(wildcards):
    with open(config["samples"],'r') as file:
        samples_master = yaml.load(file,Loader=yaml.FullLoader)
        samples_master.keys()
    # print(wildcards.sample)
    return samples_master[wildcards.sample]["tumor_bam"][0]

def get_bam(wildcards):
    with open(config["samples"],'r') as file:
        samples_master = yaml.load(file,Loader=yaml.FullLoader)
        samples_master.keys()
    # print(wildcards.sample)
    return samples_master[wildcards.sample][0]

def select_filtered(wildcards):
    with open(config["samples"],'r') as file:
        samples_master = yaml.load(file,Loader=yaml.FullLoader)
    if not samples_master[wildcards.sample]["normal_bam"]:
        return rules.filter_mutect_tumoronly.output.vcf
    else:
        return rules.filter_mutect.output.vcf
