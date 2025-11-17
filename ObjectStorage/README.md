
you need install the directpv before the minio instalation, it will search for available disks.
after that run the discover script to create the drivers.yml file that list all the cluster disks.
edit the drivers.yml for select only the disks you want on minio.
then run the init script that register all the storage available on kubernets api for minio allocate and use
