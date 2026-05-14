

# Metagenomic Analytical Pipeline for Respiratory Pathogen Detection



## Abstract
Scalable Genomic Integration into Syndromic Surveillance for Respiratory Outbreak Preparedness in Brazil:
Timely detection of respiratory outbreaks is a key step for epidemic preparedness. Brazil’s Alert-Early System of Outbreaks with Pandemic Potential (ÆSOP) uses anomaly detections in the curves of Primary Health Care encounters data for syndromically detecting increases of influenza-like illnesses. Herein, we present a proof-of-concept study evaluating the integration of a cost-efficient genomic module into ÆSOP, using pooled-sample Next-Generation Sequencing with Hybrid Capture (NGS-HC) to characterize pathogens during both alert and baseline periods across seven cities, representing all Brazilian regions (n=1,137 samples; 114 pools). We performed RT-qPCR for major respiratory viruses in all samples, as a benchmark for NGS-HC results. NGS-HC detected 33 viral species, including Flu A, SARS-CoV-2, RSV, HRV, seasonal HCoVs, together with exploratory profiling of respiratory tract-associated bacteria. Overall concordance with RT-qPCR was moderate (sensitivity 80.81%, specificity 81.27%, weighted kappa = 0.53). Pooling samples led to a tenfold cost-per-sample reduction, with a median turnaround time of 7 days. Syndromic alerts consistently coincided with high impact in public health pathogens, while in non-alert periods there was a predominance of endemic, lower impact viruses. There was a marked regional and seasonal variation in genomic profiles, indicating the need for a national baseline pathogen landscape. We addressed amplicon contamination challenges through laboratory protocols and stringent bioinformatic pipelines. Our findings support the integration of genomic surveillance for early outbreak detection in decentralized health systems, providing a scalable model for low- and middle-income countries to enhance epidemic preparedness.


## Methods

Our work performed the following steps:

[**Execution of Analysis Pipeline**]()

    1. Download files from Basespace
    2. Adapter Trimming and Quality Filtering
    3. Host Decontamination
    2. Taxa Annotation
    3. Species-Level taxa abundance retrieval



## Installation and Usage

1. **Install nextflow and conda for workflow and environmental management, respectively**
Download and install Nextflow and its dependencies [here](https://docs.seqera.io/nextflow/install)
```bash
#install conda 24.10
wget https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh
bash Anaconda3-2024.10-1-Linux-x86_64.sh
```
There is no need for installing conda envs. Nextflow will handle the necessary dependencies for each step using the environment files stored in the ``envs`` directory

2. **Clone this repository**
```bash
git clone https://github.com/diogoat/aesop-metagenomics-pipeline-nf.git
cd aesop-metagenomics-pipeline-nf
mkdir -p ./databases 
mkdir -p ./test
```
3. **Download tools and reference databases from Zenodo**

**Download Tools**
```bash
wget https://zenodo.org/records/20168222/files/softwares.zip?download=1 -O softwares.zip
unzip softwares.zip
```
    
**Bowtie2 referece databases**
```bash
#ERCC
mkdir -p databases/bowtie2_db/ercc92
wget https://zenodo.org/records/20168222/files/ercc92.zip?download=1 -O ercc92.zip
unzip ercc92.zip -d databases/bowtie2_db/ercc92
#PHIX viral
mkdir -p databases/bowtie2_db/phix_viralproj14015
wget https://zenodo.org/records/20168222/files/phix_viralproj14015.zip?download=1 -O phix_viralproj14015.zip
unzip phix_viralproj14015.zip databases/bowtie2_db/phix_viralproj14015
#Human index
mkdir -p databases/bowtie2_db/human_index_20240725
wget https://zenodo.org/records/20168222/files/bowtie_human_index_20240725.zip?download=1 -O human_index_20240725.zip
unzip human_index_20240725.zip -d databases/bowtie2_db/human_index_20240725
```

**Hisat2 referece databases**
```bash
#Human index
mkdir -p databases/hisate2_db/hisat_human_index_20240725
wget https://zenodo.org/records/20168222/files/hisat_human_index_20240725.zip?download=1 -O human_index_20240725.zip
unzip  hisat_human_index_20240725.zip -d databases/hisate2_db/hisat_human_index_20240725
```

**Taxonomy information**
```bash
mkdir -p databases/taxonomy/taxdump_20250211
wge https://zenodo.org/records/20168222/files/taxdump_20250211.zip?download=1=1 -O taxdump_20
250211.zip
unzip taxdump_20250211.zip -d databases/taxonomy/taxdump_20250211
```

**Kraken/Braken database is too large (>200Gb) to be storaged in Zenodo. Therefore, it's necessary to build it from scrath**
```bash
mkdir -p databases/kraken2_db/aesop_kraken2db
./softwares/kraken2-2.1.3/bin/kraken2-build --download-taxonomy --db databases/kraken2_db/aesop_kraken2db
./softwares/kraken2-2.1.3/bin/kraken2-build --download-library bacteria --db databases/kraken2_db/aesop_kraken2db
./softwares/kraken2-2.1.3/bin/kraken2-build --download-library viral --db databases/kraken2_db/aesop_kraken2db
./softwares/kraken2-2.1.3/bin/kraken2-build --build --threads 16 --db databases/kraken2_db/aesop_kraken2db
#Build it for Braken also
./softwares/Bracken-2.9/bracken-build -d databases/kraken2_db/aesop_kraken2db -t 16 -k 35 -l 75
```

4. **Test the installation**
The firt run may take a couple of minutes to start because nextflow needs to configure the environment.
```bash
#Download the test set from Zenodo
wget https://zenodo.org/records/20168222/files/MOCK01_S1_L001_R1_001.fastq.gz?download=1 -O MOCK01_S1_L001_R1.fastq.gz
wget https://zenodo.org/records/20168222/files/MOCK01_S1_L001_R2_001.fastq.gz?download=1 -O MOCK01_S1_L001_R2.fastq.gz
wget https://zenodo.org/records/20168222/files/POOL01_S1_L001_R1_001.fastq.gz?download=1 -O POOL01_S1_L001_R1.fastq.gz
wget https://zenodo.org/records/20168222/files/POOL01_S1_L001_R2_001.fastq.gz?download=1 -O POOL01_S1_L001_R2.fastq.gz
mv *.fastq.gz ./test
#Run AESOP Metagenomic Pipeline
nextflow run aesop.nf --source test -with-report InstallTest.htm
```
A directory named ``Results`` will appear when the pipeline finishes. It in you can check the outputs of each step 


## Citation

If you use this pipeline in your research, please cite the following paper:

> Viana, P. A. B.; Tschoeke, D. A.; de Moraes, L.; Santos, L. A.; Barral-Netto, M.; Khouri, R.; Ramos, P. I. P.; Meirelles, P. M.; (2024). Design and Implementation of a Metagenomic Analytical Pipeline for Respiratory Pathogen Detection. BMC Res Notes 17, 291 (2024). https://doi.org/10.1186/s13104-024-06964-9

> Scalable Genomic Integration into Syndromic Surveillance for Respiratory Outbreak Preparedness in Brazil 

* Corresponding Author: Ricardo Khouri (ricardo.khouri@fiocruz.br) and Pedro M Meirelles (pmeirelles@ufba.br)
* On any code issues, correspond to: Pablo Viana (pablo.alessandro@gmail.com) and Tiago Cabral (tiago.cabral422@gmail.com)
