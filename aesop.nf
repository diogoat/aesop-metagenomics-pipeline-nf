#!/usr/bin/env nextflow

process DOWNLOAD {
    // publishDir "Results", mode: 'copy', overwrite: true
    output:
        path "0-download"
    script:
        """
        export PATH=${params.tools.basescape}:\$PATH
        bs download project -v -i ${params.id} -o 0-download --extension='.fastq.gz' --exclude='*unmapped*' --exclude='*deter*'
        """
}
process MOVE_READS {
    // publishDir "Results", mode: 'copy', overwrite: true
    input:
        path "0-download"
    output:
        path "0-raw_reads/*.gz"
    script:
        """
        mkdir -p 0-raw_reads
        mv 0-download/*/*.fastq.gz 0-raw_reads/
        """
}
process BOWTIE_PHIX {
    input:
    tuple val(sample), path(reads)

    output:
    tuple val("${sample}"), path("${sample}_phix_R{1,2}.fastq.gz")

    script:
    """
    export PATH=${params.tools.bowtie2}:\$PATH
    export PATH=${params.tools.samtools}:\$PATH

    bowtie2 --very-sensitive-local --met-stderr \
    --threads 8 \
    -x ${params.indices.phix} \
    -q \
    -1 ${reads[0]} \
    -2 ${reads[1]} \
    -S ${sample}_phix.sam
    samtools view -bS -f 13 ${sample}_phix.sam > ${sample}_phix.bam
    samtools fastq -1 ${sample}_phix_R1.fastq.gz -2 ${sample}_phix_R2.fastq.gz ${sample}_phix.bam
    rm ${sample}_phix.bam
    rm ${sample}_phix.sam
    """
}
process BOWTIE_ERCC {
    input:
    tuple val(sample), path(reads)

    output:
    tuple val("${sample}"), path("${sample}_ercc_R{1,2}.fastq.gz")

    script:
    """
    export PATH=${params.tools.bowtie2}:\$PATH
    export PATH=${params.tools.samtools}:\$PATH

    bowtie2 --very-sensitive-local --met-stderr \
    --threads 8 \
    -x ${params.indices.ercc} \
    -q \
    -1 ${reads[0]} \
    -2 ${reads[1]} \
    -S ${sample}_ercc.sam
    samtools view -bS -f 13 ${sample}_ercc.sam > ${sample}_ercc.bam
    samtools fastq -1 ${sample}_ercc_R1.fastq.gz -2 ${sample}_ercc_R2.fastq.gz ${sample}_ercc.bam
    rm ${sample}_ercc.bam
    rm ${sample}_ercc.sam
    """
}
process FASTP {
    input:
    tuple val(sample), path(reads)
    
    output: 
    tuple val("${sample}"), path("${sample}_clean_R{1,2}.fastq.gz")
    
    script:
    """
    export PATH=${params.tools.fastp}:\$PATH

    fastp \
    -i ${reads[0]} -I ${reads[1]} \
    -o ${sample}_clean_R1.fastq.gz \
    -O ${sample}_clean_R2.fastq.gz  \
    --thread 8 \
    --cut_front \
    --cut_tail \
    --cut_window_size 1 \
    --cut_mean_quality 20 \
    --average_qual 20 \
    --length_required 50 \
    --n_base_limit 2
    """
}
process HISAT2 {
    input:
    tuple val(sample), path(reads)

    output:
    tuple val("${sample}"), path("${sample}_hisat_R{1,2}.fastq.gz")

    script:
    """
    export PATH=${params.tools.hisat2}:\$PATH
    export PATH=${params.tools.samtools}:\$PATH

    hisat2 --met-stderr \
    --threads 8 \
    -x ${params.indices.hisat2} \
    -q \
    -1 ${reads[0]} \
    -2 ${reads[1]} \
    -S ${sample}_hisat.sam
    samtools view -bS -f 13 ${sample}_hisat.sam > ${sample}_hisat.bam
    samtools fastq -1 ${sample}_hisat_R1.fastq.gz -2 ${sample}_hisat_R2.fastq.gz ${sample}_hisat.bam
    rm ${sample}_hisat.bam
    rm ${sample}_hisat.sam

    """
}
process BOWTIE_HUMAN {
    input:
    tuple val(sample), path(reads)

    output:
    tuple val("${sample}"), path("${sample}_human_R{1,2}.fastq.gz")

    script:
    """
    export PATH=${params.tools.bowtie2}:\$PATH
    export PATH=${params.tools.samtools}:\$PATH

    bowtie2 --very-sensitive-local --met-stderr \
    --threads 8 \
    -x ${params.indices.human_full} \
    -q \
    -1 ${reads[0]} \
    -2 ${reads[1]} \
    -S ${sample}_human.sam
    samtools view -bS -f 13 ${sample}_human.sam > ${sample}_human.bam
    samtools fastq -1 ${sample}_human_R1.fastq.gz -2 ${sample}_human_R2.fastq.gz ${sample}_human.bam
    rm ${sample}_human.bam
    rm ${sample}_human.sam

    """
}
process KRAKEN2 {
    publishDir "Results/${params.name}/kraken2", mode: 'copy'
    input:
    tuple val(sample), path(reads)

    output:
        tuple val("${sample}"), path("${sample}.report")

    script:
    """
    export PATH=${params.tools.kraken2}:\$PATH
    kraken2 --db ${params.indices.kraken_braken} \
    --paired \
    ${reads[0]}  \
    ${reads[1]}   \
    --output ${sample}.kraken \
    --report ${sample}.report \
    --confidence 0.1 \
    --memory-mapping \
    --threads 8
    """
}
process BRAKEN  {
    publishDir "Results/${params.name}/braken", mode: 'copy' 

    input:
        tuple val(sample), path(report)
    output:
    tuple val(sample), path("${sample}.braken")
    
    script:
    """
    export PATH=${params.tools.braken}:\$PATH

    bracken -d ${params.indices.kraken_braken} \
    -i ${report[0]} \
    -o ${sample}.braken \
    -r 130 \
    -t 1
    """
}
process RAW_READS_STATS {
    publishDir "Results/${params.name}/stats", mode: 'copy'
    input:
        path raw_reads
    output:
        path "raw-reads-stats.tsv"
    script:
    """
    export PATH=${params.tools.seqkit}:\$PATH
    seqkit stats --basename ${raw_reads} -T > raw-reads-stats.tsv
    """
}           
process FILTERED_READS_STATS {
    publishDir "Results/${params.name}/stats", mode: 'copy'
    input:
        path filtered_reads
    output:
        path "filtered-reads-stats.tsv"
    script:
    """
    export PATH=${params.tools.seqkit}:\$PATH
    seqkit stats --basename ${filtered_reads} -T > filtered-reads-stats.tsv
    """
}
process MERGE_BRACKEN {
    publishDir "Results/${params.name}/abundance", mode: 'copy'
    input:
        path braken_files
    output:
        path 'braken-abund.tsv'
    script:
    """
    chmod +x ${params.tools.braken_combine}/combine_bracken_outputs.py
    export PATH=${params.tools.braken_combine}:\$PATH
    combine_bracken_outputs.py \
    --files ${braken_files} \
    -o braken-abund.tsv
    """
}
process CALCULATE_NTRPM {
    conda "${params.envs.braken_ntrpm}"
    publishDir "Results/${params.name}/abundance", mode: 'copy'
    input:
        path braken_abundance
        path filtered_reads_stats
    output:
        path 'braken-ntrpm.tsv'
    script:
    """
    python - <<EOF
    import pandas as pd

    ReadsStats = pd.read_csv("${filtered_reads_stats}", sep="\\t")
    BrakenOriginalFile = pd.read_csv("${braken_abundance}", sep="\\t")
    RpipPathogens = pd.read_csv("${params.taxonomy.rpip_pathogens}", sep=",")


    ReadsStats['file'] = ReadsStats.file.str.replace("_human_R[12].fastq.gz", "", regex=True)
    TotalReadsDict = ReadsStats.groupby('file')['num_seqs'].sum().to_dict()
    RpipPathogens.rename(columns = {"tax_id":"taxonomy_id"}, inplace=True)
    
    BrakenOriginalFile = BrakenOriginalFile.merge(
    RpipPathogens[["taxonomy_id", "organism", "realm"]],
    on = "taxonomy_id",
    how = "left")
    
    for sample in TotalReadsDict.keys():
        BrakenOriginalFile[f"{sample}.ntrpm"] = BrakenOriginalFile[f"{sample}.braken_num"].apply(lambda x:(x/1_000_000) * TotalReadsDict[sample]).round().astype(int)

    ColumnsToKeep = list(BrakenOriginalFile.columns.str.contains(".ntrpm"))
    ColumnsToKeep = list(BrakenOriginalFile.columns[ColumnsToKeep]) + ["name", "taxonomy_id", "realm"]

    BrakenOriginalFile = BrakenOriginalFile.loc[
        BrakenOriginalFile.realm.isin(["bacteria","eukaryota","viruses"]),
        ColumnsToKeep
        ]
    BrakenOriginalFile = BrakenOriginalFile.melt(
        id_vars=["name", "taxonomy_id", "realm"],
        var_name="sample",
        value_name="braken_ntrpm")

    viruses =   (BrakenOriginalFile.realm == "viruses") & (BrakenOriginalFile.braken_ntrpm >= 1)
    bacteria =  (BrakenOriginalFile.realm == "bacteria") & (BrakenOriginalFile.braken_ntrpm >= 10)
    eukaryota = (BrakenOriginalFile.realm == "eukaryota") & (BrakenOriginalFile.braken_ntrpm >= 200)
    BrakenOriginalFile = BrakenOriginalFile.loc[viruses | bacteria | eukaryota]
    BrakenOriginalFile.to_csv("braken-ntrpm.tsv", sep="\\t", index=False)
    

    EOF
    """
}
process HEATMAPS {
    conda "${params.envs.braken_ntrpm}"
    publishDir "Results/${params.name}/figures", mode: 'copy'

    input:
        path braken_ntrpm
    output:
        path 'heatmap_bacteria.png'
        path 'heatmap_viruses.png'
    script:
    """
    python - <<EOF
    import pandas as pd
    import matplotlib.pyplot as plt
    import seaborn as sns
    from matplotlib.colors import ListedColormap, BoundaryNorm

    BrakenOriginalFile = pd.read_csv("${braken_ntrpm}", sep="\\t")
    BackGroud = BrakenOriginalFile.loc[BrakenOriginalFile["sample"].str.contains("MOCK")]
    BackGroud = BackGroud.pivot_table(
        index = ["name", "taxonomy_id", "realm"],
        columns = "sample",
        values = "braken_ntrpm",
    ).reset_index().fillna(0)

    BackGroud['mean'] = BackGroud.iloc[:,BackGroud.columns.str.contains("MOCK")].mean(axis=1)
    BackGroud['std'] =  BackGroud.iloc[:,BackGroud.columns.str.contains("MOCK")].std(axis=1)
    BackGroudMap = BackGroud.set_index('taxonomy_id').to_dict(orient='index')

    Samples = BrakenOriginalFile.loc[~BrakenOriginalFile["sample"].str.contains("MOCK")]
    Samples['backgroud.mean'] = Samples.taxonomy_id.apply(lambda x: BackGroudMap.get(x, {}).get('mean', 0))
    Samples['backgroud.std'] =  Samples.taxonomy_id.apply(lambda x: BackGroudMap.get(x, {}).get('std', 0.0001))
    Samples['zscore'] = Samples.apply(
        lambda row: (row['braken_ntrpm'] - row['backgroud.mean']) / row['backgroud.std'],
        axis = 1
    )

    Virus = Samples[(Samples.realm == "viruses") & (Samples.zscore > 1)]
    Bacteria = Samples[(Samples.realm == "bacteria") & (Samples.zscore > 1)]
    Eucaria = Samples[(Samples.realm == "eukaryota") & (Samples.zscore > 1)]

    Virus = Virus.pivot_table(
        index="name",
        columns="sample",
        values="braken_ntrpm",
        fill_value=0
    )
    Bacteria = Bacteria.pivot_table(
        index="name",
        columns="sample",
        values="braken_ntrpm",
        fill_value=0
    )
    Eucaria = Eucaria.pivot_table(
        index="name",
        columns="sample",
        values="braken_ntrpm",
        fill_value=0
    )


    color_breaks = [0, 1, 5, 25, 100, 500, 1000, 5000, 10000, 50000, 220000, 450000]
    heat_colors = [
        "#CCCCCC",  # substituto de grey80
        "#FFFFCC", "#FFEFA5", "#FEDC7F", "#FEBF5B",
        "#FD9D43", "#FC7034", "#F23D26",
        "#D91620", "#B40325", "#800026"
    ]

    cmap = ListedColormap(heat_colors)
    norm = BoundaryNorm(color_breaks, ncolors=len(heat_colors), clip=False)

    sns.heatmap(
        data=Virus,
        cmap=cmap,
        norm=norm,
        cbar_kws={"label": "nt_rpm"},
    )
    plt.title("Viral Samples")
    plt.tight_layout()
    plt.savefig("heatmap_viruses.png", dpi=300, bbox_inches='tight')
    plt.close()
    sns.heatmap(
        data=Bacteria,
        cmap=cmap,
        norm=norm,
        cbar_kws={"label": "nt_rpm"},
    )
    plt.title("Bacterial Samples")   
    plt.tight_layout()
    plt.savefig("heatmap_bacteria.png", dpi=300, bbox_inches='tight')
    plt.close()
    EOF
    """    
}
process REDCAP {
    conda "${params.envs.braken_ntrpm}"
    publishDir "Results/${params.name}/figures", mode: 'copy'
    errorStrategy 'ignore'

    input:
        path redcap_file
    output:
        path 'redcap_heatmap.png'
    script:
    """
    python - <<EOF
    import pandas as pd
    import seaborn as sns
    import matplotlib.pyplot as plt
    from matplotlib.colors import ListedColormap
    REDcapMetadata = pd.read_csv("${redcap_file}")
    REDcapMetadata = REDcapMetadata.loc[REDcapMetadata.id_run_enr == "LACENDF_AESOP-C2_RNAPENR_LIBRARY20250129"]
    REDcapMetadata.set_index('id_pool', inplace=True)
    Symptoms = [
    'febre',
    'tosse',
    'congestao_nasal',
    'coriza',
    'dispneia',
    'odinofagia',
    'cefaleia', 
    'otalgia', 
    'astenia', 
    'mialgia',
    'blenoftalmia', 
    'calafrios', 
    'disgeusia', 
    'vomito', 
    'nausea',
    'dor_toracica', 
    'gastralgia', 
    'abdominalgia', 
    'diarreia', 
    'hipertensao',
    'hipoxia', 
    'enurese', 
    'sonolencia', 
    'artralgia', 
    'conjuntivite'
        ]
    
    VirusesPCR = [
    'flua_pcr', 'flua_cq',
    'flub_pcr', 'flub_cq', 
    'sars2_pcr', 'sars2_cq', 
    'rinovirus_pcr','rinovirus_cq', 
    'adenovirus_pcr', 'adenovirus_cq',
    'metapneumovirus_pcr', 'metapneumovirus_cq', 
    'rsv_pcr', 'rsv_cq']
    REDcapSymptoms = REDcapMetadata[Symptoms]
    REDcapPCR_Viruses = REDcapMetadata[VirusesPCR]
    REDcapPCR_Viruses = REDcapPCR_Viruses.apply(pd.to_numeric)
    REDcapPCR_Viruses = REDcapPCR_Viruses[REDcapPCR_Viruses != 99].dropna(axis=1)
    REdCAP_SymtomsANDVirus = pd.concat([REDcapSymptoms,REDcapPCR_Viruses], axis = 1).T

    cmap = ListedColormap(["#A1CEDB", "red"])
    plt.figure(figsize=(9,7))
    ax = sns.heatmap(
        REdCAP_SymtomsANDVirus,
        cmap=cmap, 
        cbar=False,
        linecolor='grey',
        linewidths=0.6
    )

    cols = REdCAP_SymtomsANDVirus.columns
    unique_cols = cols.unique()
    tick_positions = []

    for u in unique_cols:
        idx = [i for i, c in enumerate(cols) if c == u]
        center = (min(idx) + max(idx)) / 2
        tick_positions.append(center)

    ax.set_xticks(tick_positions)
    ax.set_xticklabels(unique_cols, rotation=90)


    for u in unique_cols[1:]:  
        first_idx = [i for i, c in enumerate(cols) if c == u][0]
        ax.axvline(first_idx, color="white", linewidth=2)

    plt.axhline(y=len(Symptoms), color='white', linewidth=2)
    plt.tight_layout()
    plt.savefig("redcap_heatmap.png", dpi=300, bbox_inches='tight')
    plt.close()

    EOF
    """

}
process WRITE_REPORT {
    conda "${params.envs.braken_ntrpm}"
    publishDir "Results/${params.name}/report", mode: 'copy'
    errorStrategy 'ignore'
    input:
        path braken_heatmap_viruses
        path redcap_heatmap
    
    output:
        path 'report.docx'
    script:
    """
    python - <<EOF
    from docx import Document
    from docx.shared import Inches
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    from docx.shared import Cm, Pt
    doc = Document()

    def add_paragraph(doc, text, first_line_indent_cm=1, space_after_pt=6, line_spacing=1.15):
        p = doc.add_paragraph(text)
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        p.paragraph_format.first_line_indent = Cm(first_line_indent_cm)
        p.paragraph_format.space_after = Pt(space_after_pt)  # espaço após o parágrafo
        p.paragraph_format.line_spacing = line_spacing       # espaçamento entre linhas
        return p

    doc.add_heading('Relatório Interno da Equipe de Bioinformática', level=0)

    # 1. METODOLOGIA
    doc.add_heading('1. METODOLOGIA EMPREGADA', level=1)

    doc.add_heading('1.1 Download', level=2)
    add_paragraph(
        doc,
        "O download das amostras sequenciadas foi realizado no Athos (servidor localizado no CIDACS, disponível para o AESOP) "
        "utilizando a ferramenta “bs cli” fornecida pelo Illumina BaseSpace para acessar os dados da plataforma."
    )
    add_paragraph(
        doc,
        "Os genomas humanos GRCh38 e T2T-CHM13v2.0 foram baixados do servidor FTP diretamente do EMBL-EBI e do NCBI, respectivamente. "
        "Os bancos de dados taxonômicos utilizados são disponibilizados publicamente pelo Langmead Lab da Johns Hopkins University, desenvolvedores do software Kraken2 e Bracken. "
        "Foi usado o banco standard plus PFP que contém genomas de archaea, bactéria, vírus, plasmídeos, humano, protozoa, fungi e plantas."
    )

    doc.add_heading('1.2 Controle de qualidade das sequências', level=2)
    add_paragraph(
        doc,
        "Foi realizado um controle de qualidade das sequências das amostras utilizando a ferramenta fastp, que remove adaptadores do sequenciamento, reads de tamanhos menores que 50 e com escore de qualidade menor que 20."
    )

    doc.add_heading('1.3 Download', level=2)
    add_paragraph(
        doc,
        "Foi criado um banco de dados com genomas humanos selecionados (GRCh38 e T2T-CHM13v2.0) para remoção de sequências contaminantes. "
        "Mapeamos as sequências metagenômicas (i.e., RPIP) nos genomas utilizando Bowtie2, Hisat2 e samtools, e as sequências mapeadas contra esses genomas foram removidas antes da anotação taxonômica."
    )

    doc.add_heading('1.4 Anotação taxonômica', level=2)
    add_paragraph(
        doc,
        "Foi utilizado o software Kraken2 para realizar a anotação taxonômica das amostras a partir dos reads dos metagenomas e o software Bracken para estimar a abundância das espécies a partir desta anotação."
    )

    doc.add_heading('1.5 Cálculo do nTRPM', level=2)
    add_paragraph(
        doc,
        "Os resultados da anotação taxonômica foram utilizados para gerar tabelas de abundância de reads classificados, normalizados em rPM (reads per million sequenced). "
        "Para remover possíveis sinais de contaminação, utilizamos duas amostras de água (controle negativo) sequenciadas em conjunto e calculamos o z-score usando-as como referência."
    )
    doc.add_heading('2. RESULTADOS DA IDENTIFICAÇÃO DE PATÓGENOS', level=1).bolsd = True
    doc.add_heading('2.1 AESOP PIPELINE', level=1).bolsd = True
    doc.add_heading('2.1.1 Patógenos virais', level=2)
    doc.add_picture("${braken_heatmap_viruses}", width=Inches(4))

    doc.add_heading('2.2 REDcap', level=1).bolsd = True
    doc.add_picture("${redcap_heatmap}", width=Inches(4)) 

    doc.save('report.docx')

    EOF
    """

}

//Params
// if (!params.name) {
//     error 'project name is needed [--name]'
// }
// if (!params.id) {
//     erro 'project if is needed [--id]'
// }

if( !params.source ) {
    error "ERROR: Inform a source directory with --source <path>"
}
workflow {
    //Get reads from base space
    // DOWNLOAD()
    // files_ch = MOVE_READS(DOWNLOAD.out)
    // grouped_ch = files_ch
    //     .flatten()
    //     .map { file ->
    //         def name = file.getName() 
    //         def sample = (name =~ /^(\w+_S\d+)_/)[0][1] 
    //         tuple(sample, file)
    //     }
    //     .groupTuple()
    // raw_reads = grouped_ch.map{files -> files[1]}.collect()


    raw_reads = Channel.fromFilePairs("${params.source}/*_{1,2}.{fastq,fastq.gz,fq,fq.gz}")

    //Remove low quality reads
    FASTP(raw_reads)

    //Remove human reads
    BOWTIE_PHIX(FASTP.out)
    BOWTIE_ERCC(BOWTIE_PHIX.out)
    HISAT2(BOWTIE_ERCC.out)
    filtered_read = BOWTIE_HUMAN(HISAT2.out).map{files -> files[1]}.collect()
    FILTERED_READS_STATS(filtered_read)
    
    //Taxonomy
    KRAKEN2(BOWTIE_HUMAN.out)
    braken_counts = BRAKEN(KRAKEN2.out).map{files -> files[1]}.collect()
    MERGE_BRACKEN(braken_counts)
    CALCULATE_NTRPM(MERGE_BRACKEN.out,FILTERED_READS_STATS.out)

    //Plots
    HEATMAPS(CALCULATE_NTRPM.out)
    redcap_ch = channel.fromPath('/home/pedro/aesop/aesop-pipeline/metadata/AESOP_DATA_2025-06-23_1716.csv')
    REDCAP(redcap_ch)
    WRITE_REPORT(HEATMAPS.out[1], REDCAP.out)
}

