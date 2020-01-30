# This example is ready to run queries out of the box
We have already performed the example load and the data is already available through the Jupyter Notebook. To run through the example queries, just run `docker-compose up -d` and point your browser at your Docker host. Once you get an idea what is possible to use your data once in HPDS, you will want to stop the jupyter environment and delete the pre-loaded data prior to running through the load instructions:

`docker-compose down`

`rm -rf hpds/all hpds/merged`

# Loading your VCF data into HPDS

Before loading your VCF file(s), two additional files must be created:

* `hpds/vcfIndex.tsv`

* `hpds/encryption_key`

The `vcfIndex.tsv` must be a tab separated flat file with 1 line per VCF file you intend to load. See sample file at `hpds/vcfIndex_sample.tsv`

The columns in this file are:

**`filename	chromosome	annotated	gzip	sample_ids	patient_ids	sample_relationship	related_sample_ids`** 

- **`filename`** - The name of a VCF file that is in the `vcfLoad` folder. This should be the full path of the VCF files relative to the container filesystem. For the purposes of this Docker example, if you have a file 3.vcf, it should be listed as /opt/local/hpds/vcfInput/3.vcf in this column. If you are not using Docker or have requirements forcing you to modify the docker-compose volume mapping, your settings may vary. 

- **`chromosome`** - The number of the chromosome in the file (if you have 1 file per chromosome) or ALL if each of your VCF files have all chromosomes for their samples.

- **`annotated`** - binary flag set to 0 if you don't want to load annotations and to 1 if you do.

- **`gzip`** - binary flag set to 0 if the file is uncompressed, 1 if it is GZIP compressed, bgzip is supported as it is GZIP, but no other compression algorithms are currently supported.

- **`sample_ids`** - A comma separated list of the sample ids in your VCF file. These are typically in the last line of the VCF header, but we need them here too to be safe.

- **`patient_ids`** - A comma separated list of the numeric(integer) patient ids that HPDS should use to link this to any phenotype data in the environment. This is required even if you don't have phenotype data because we still need patient ids that are integers.

- **`sample_relationship`** - not currently used, but in the future it would be the relationship of this sample to another corresponding sample in related_sample_ids

- **`related_sample_ids`** - not currently used


The `encryption_key` file must be a 32 character hexadecimal string. This is not currently used for VCF loads, but it is still required. Feel free to use the below key unless you are also loading phenotype data.

`11111111111111111111111111111111`

Once these files have been created and your VCF files have been placed in the vcfLoad folder, just run this command from the `pic-sure-hpds-genotype-load-example` folder:

`docker-compose -f docker-compose-variant-loader.yml up -d`

Wait a while before checking the logs, there is a ton of spam at the beginning from VCF header parsing. After at least 5 minutes run this to watch the logs:

`docker-compose -f docker-compose-variant-loader.yml logs --tail=10 -f`

It should look something like this:

variant-loader_1  | 1571093539500 Done loading chunk : 22210 for chromosome 14

variant-loader_1  | 1571093542715 Done loading chunk : 22220 for chromosome 14

variant-loader_1  | 1571093547422 Done loading chunk : 22230 for chromosome 14

variant-loader_1  | 1571093551659 Done loading chunk : 22240 for chromosome 14

variant-loader_1  | 1571093555739 Done loading chunk : 22250 for chromosome 14

variant-loader_1  | 1571093559943 Done loading chunk : 22260 for chromosome 14

>> **NOTE**: if the `up` command above does not start the loading process, try: `docker-compose -f docker-compose-variant-loader.yml restart`. 

This process will use all available CPU. It is extremely greedy. It is not advised that you try to do it on your local workstation. Get a VM from your favorite cloud provider or from your IT department with as many cores as you can afford.

The first column after `variant-loader_1` is a UNIX timestamp, just so you can see how long each chunk is taking on average. The chunk number (22210) can be seen as an indicator of progress through the job. This number multiplied by 1000 is the number of loci on the genome that have been loaded (or skipped if they were not in your file) for the specific chromosome. Our example file is only an excerpt from CHR14 of 1KGenome starts around 20,000,000 bp and ends at about 40,000,000 bp.

As the loading progresses, the loader will also be accumulating an INFO column data in memory. This INFO storage is the most memory intensive part of the load. For our example file we allocate 4GB of RAM, which is more than we need. For a larger project you may need to tweak the `HEAPSIZE` environment setting in the docker-compose entrypoint of the variant-loader to have more RAM. This is expressed in number of megabytes of RAM to allocate.

Once the process completes you will see something like the following message:

Converted 239855 seconds

You can now start your validation of the data load by running:

`docker-compose up -d`

Then pointing your web browser at the IP of your docker host.

Because there is NO SECURITY on this validation `Jupyter Notebook`, it is recommended that you close off the firewall and SSH tunnel to the host in order to do your validation. Use `localhost` in your browser to load the `Jupyter Notebook`.  In situations where HPDS is setup on an EC2 instance use the instance's IP address instead of `localhost`.

>> **NOTE**: HPDS requires that an initial HTTP request be sent to unlock the dataset. This should be a POST command to the endpoint URL + /query and should contain a body as such with the proper security key substituted `{"resourceCredentials":{"key":"11111111111111111111111111111111"}}`

>> **NOTE**: HPDS has limitations related to the way data must be formatted in the VCF file. Read over the following:


Multi-allelic variants have to be split into multiple rows. So if you have:

1	1111111	.	A	T,C	100	PASS	.	GT	1/2

You have to split it to:

1	1111111	.	A	T	100	PASS	.	GT	0/1
1	1111111	.	A	C	100	PASS	.	GT	0/1


There is no support currently for flag-based INFO columns. One approach that works well is to map all of the flag values for a row into a new INFO column called FLAGS and put all values for the VCF row into that column like so:

1	1111111	.	A	T	100	PASS	MULTIALLELIC;SYNONYMOUS;	GT	0/1

Is changed to:

1	1111111	.	A	T	100	PASS	FLAGS=MULTIALLELIC,SYNONYMOUS;	GT	0/1


Phased records are coerced into unphased by the loader. This means 1|0 and 0|1 both become 0/1 after they are loaded.



