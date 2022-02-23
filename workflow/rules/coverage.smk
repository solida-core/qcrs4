
rule get_software:
    input:
        normal=lambda wildcards: get_normal_bam(wildcards),
        tumoral= lambda wildcards: get_tumoral_bam(wildcards),
    output:
        touch("bamstats04.created"),
        exec="jvarkit/dist/bamstats04.jar"
    threads: conservative_cpu_count(reserve_cores=2,max_cores=99)
    shell:
        "git clone https://github.com/lindenb/jvarkit.git ; "
        "cd jvarkit ; "
        "./gradlew bamstats04 "


rule run_bamstat:
    input:
        bam=lambda wildcards: get_bam(wildcards),
        software=rules.get_software.output.exec
    output:
        tsv="results/stats/{sample}_coverage.tsv"
    params:
        custom=java_params(tmp_dir=config.get("processing").get("tmp_dir"), multiply_by=5),
        intervals=config.get("processing").get("interval_list"),
        param=config.get("params").get("jvarkit").get("bamstats04")
    threads: conservative_cpu_count(reserve_cores=2, max_cores=99)
    resources:
        tmpdir = config.get("processing").get("tmp_dir")
    shell:
        "java -jar "
        "{input.software} "
        "-B {params.intervals} "
        "{input.bam} "
        "-o {output.tsv} "
