
rule get_software:
    output:
        touch("bamstats04.created"),
        exec="jvarkit/dist/bamstats04.jar"
    threads: conservative_cpu_count(reserve_cores=2,max_cores=99)
    shell:
        "git clone https://github.com/lindenb/jvarkit.git ;"
        ""
        "jvarkit/gradlew bamstats04 "


rule panel_coverage:
    input:
        bam=lambda wildcards: get_bam(wildcards),
#        software=rules.get_software.output.exec
    output:
        tsv="results/stats/{sample}_panel_coverage.tsv"
    params:
        custom=java_params(tmp_dir=config.get("processing").get("tmp_dir"), multiply_by=5),
        genome=resolve_single_filepath(*references_abs_path("ref"), config.get("ref").get("fasta")),
        intervals=config.get("processing").get("panel_intervals"),
        param=config.get("params").get("jvarkit").get("bamstats04")
    threads: conservative_cpu_count(reserve_cores=2, max_cores=99)
    resources:
        tmpdir = config.get("processing").get("tmp_dir")
    shell:
        "java -jar "
        "{params.param} "
        "-B {params.intervals} "
        "-R {params.genome} "
        "{input.bam} "
        "-o {output.tsv} "


rule canonical_coverage:
    input:
        bam=lambda wildcards: get_bam(wildcards),
#        software=rules.get_software.output.exec
    output:
        tsv="results/stats/{sample}_canonical_coverage.tsv"
    params:
        custom=java_params(tmp_dir=config.get("processing").get("tmp_dir"), multiply_by=5),
        genome=resolve_single_filepath(*references_abs_path("ref"), config.get("ref").get("fasta")),
        intervals=config.get("processing").get("canonical_intervals"),
        param=config.get("params").get("jvarkit").get("bamstats04")
    threads: conservative_cpu_count(reserve_cores=2, max_cores=99)
    resources:
        tmpdir = config.get("processing").get("tmp_dir")
    shell:
        "java -jar "
        "{params.param} "
        "-B {params.intervals} "
        "-R {params.genome} "
        "{input.bam} "
        "-o {output.tsv} "


rule format_results:
    input:
        panel="results/stats/{sample}_panel_coverage.tsv",
        canonical="results/stats/{sample}_canonical_coverage.tsv"
    output:
        tsv="results/tsv/{sample}.coverage.tsv",
        xlsx="results/xlsx/{sample}.coverage.xlsx"
    params:
        panel_intervals=config.get("processing").get("panel_intervals"),
        canonical_intervals=config.get("processing").get("canonical_intervals")
    conda:
        "../envs/r_env.yaml"
    threads: conservative_cpu_count(reserve_cores=2, max_cores=99)
    resources:
        tmpdir = config.get("processing").get("tmp_dir")
    script:
        "../scripts/parse_results.R"
