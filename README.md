

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



## Installation

Install the necessary software using the following commands:

1. **Install nextflow and conda for workflow and environmental management, respectively**
Download and install Nextflow and its dependencies [here](https://docs.seqera.io/nextflow/install)
```bash
#install conda 24.10
wget https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh
bash Anaconda3-2024.10-1-Linux-x86_64.sh
```
There is no need for installing conda envs. Nextflow will handle the necessary dependencies for each step using the environment files stored in the ``envs`` directory


```bash
# Python
sudo apt update
sudo apt install python3 python3-pip make
pip3 install biopython

# Install Fastp
sudo apt install fastp

# Install HISAT2
sudo apt install hisat2

# Install Bowtie2
sudo apt install bowtie2

# Install Samtools
sudo apt install samtools

# Install Kraken2
sudo apt install kraken2

# Install Bracken
wget https://github.com/jenniferlu717/Bracken/archive/refs/tags/v2.9.tar.gz
tar -xvzf v2.9.tar.gz
cd Bracken-2.9
./install_bracken.sh
sudo mv bracken /usr/local/bin/
sudo mv bracken-build /usr/local/bin/
sudo mv src/kmer2read_distr /usr/local/bin/
sudo mv src/est_abundance.py /usr/local/bin/
sudo mv src/generate_kmer_distribution.py /usr/local/bin/
```

## Usage

1. **Clone the repository**

```bash
git clone https://github.com/cidacslab/aesop-metagenomics-pipeline-nf.git
cd aesop-metagenomics-pipeline
```
2. **Executable and Database Configuration**

Download the databases and edit the *nextflow.config* file 

3. **Test the installation**
```bash
nextflow run aesop.nf --source /path/to/read.{fastq,fastq.gz,fq or fq.gz}
```

## Citation

If you use this pipeline in your research, please cite the following paper:

> Viana, P. A. B.; Tschoeke, D. A.; de Moraes, L.; Santos, L. A.; Barral-Netto, M.; Khouri, R.; Ramos, P. I. P.; Meirelles, P. M.; (2024). Design and Implementation of a Metagenomic Analytical Pipeline for Respiratory Pathogen Detection. BMC Res Notes 17, 291 (2024). https://doi.org/10.1186/s13104-024-06964-9

> Scalable Genomic Integration into Syndromic Surveillance for Respiratory Outbreak Preparedness in Brazil 

* Corresponding Author: Ricardo Khouri (ricardo.khouri@fiocruz.br) and Pedro M Meirelles (pmeirelles@ufba.br)
* On any code issues, correspond to: Pablo Viana (pablo.alessandro@gmail.com) and Tiago Cabral (tiago.cabral422@gmail.com)
