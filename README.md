* Loading your VCF data into HPDS

To load your data, aside from your VCF file(s), two additional files must be created.

hpds/vcfIndex.tsv
hpds/encryption_key

The vcfIndex.tsv must be a tab separated flat file with 1 line per VCF file you intend to load.

The columns in this file are:

filename
chromosome
annotated
gzip
sample_ids
patient_ids
sample_relationship
related_sample_ids

- filename - The name of a VCF file that is in the vcfLoad folder.

- chromosome - The number of the chromosome in the file(if you have 1 file per chromosome) or ALL if each of your VCF files have all chromosomes for their samples.

- annotated - 0 if you don't want to load annotations, 1 if you do

- gzip - 0 if the file is uncompressed, 1 if it is GZIP compressed, bgzip is supported as it is GZIP, but no other compression algorithms are currently supported

- sample_ids - A comma separated list of the sample ids in your VCF file. These are typically in the last line of the VCF header, but we need them here too to be safe.

- patient_ids - A comma separated list of the numeric(integer) patient ids that HPDS should use to link this to any phenotype data in the environment. This is required even if you don't have phenotype data because we still need patient ids that are integers.

- sample_relationship - not currently used, but in the future it would be the relationship of this sample to another corresponding sample in related_sample_ids

- related_sample_ids - not currently used


The encryption_key file must be a 32 character hexadecimal string. This is not currently used for VCF loads, but it is still required. Feel free to use the below key unless you are also loading phenotype data.

11111111111111111111111111111111

Once these files have been created and your VCF files have been placed in the vcfLoad folder, just run this:

docker-compose -f docker-compose-variant-loader.yml up -d

Wait a while before checking the logs, there is a ton of spam at the beginning from VCF header parsing. After at least 5 minutes run this to watch the logs:

docker-compose -f docker-compose-variant-loader.yml logs --tail=10 -f

It should look something like this:

1570456857562 Done loading chunk : 40410 for chromosome 14
1570456869899 Done loading chunk : 40420 for chromosome 14
1570456880293 Done loading chunk : 40430 for chromosome 14
1570456892424 Done loading chunk : 40440 for chromosome 14
1570456900770 Done loading chunk : 40450 for chromosome 14
1570456909160 Done loading chunk : 40460 for chromosome 14
1570456921627 Done loading chunk : 40470 for chromosome 14
1570456931680 Done loading chunk : 40480 for chromosome 14
1570456940724 Done loading chunk : 40490 for chromosome 14

The first column here is a unix timestamp, just so you can see how long each chunk is taking on average. The chunk number (40410) can be seen as an indicator of progress through the job. This number multiplied by 1000 is the number of loci on the genome that have been loaded(or skipped if they werent in your file) for the specific chromosome. Our example file which is only an excerpt from CHR14 of 1kgenome starts around 20,000,000bp and ends at about 40,000,000bp so this file must be almost done.

As the loading progresses the loader will also be accumulating INFO column data in memory. This INFO storage is the most memory intensive part of the load. For our example file we allocate 4GB of ram, which is more than we need. For a larger project you may need to tweak the heapsize(-Xmx) setting in the docker-compose entrypoint of the variant-loader to have more RAM. 

This process will use all available CPU. It is extremely greedy. It is not advised that you try to do it on your local workstation. Get a VM from your favorite cloud provider or from your IT department with as many cores as you can afford.

Once the process completes you will see something like the following message:

Converted239855399 seconds

The number here is actually milliseconds, we will fix the label soon.

You can now start your validation of the data load by running:

docker-compose up -d

Then pointing your web browser at the IP of your docker host.

Because there is NO SECURITY on this validation Jupyter Notebook, it is recommended that you close off the firewall and SSH tunnel to the host in order to do your validation.


