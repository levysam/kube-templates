# Project Overview

This repository assumes you already have a working Kubernetes cluster with a configured CNI.  
The environment was tested using **Cilium**, so full compatibility is only guaranteed when using this CNI.

For load balancing, a MetalLB installation manifest is included. However, you can also install MetalLB by following the official documentation if you prefer a more customized or well-understood setup.

---

## Object Storage (MinIO)

This repository provides two MinIO deployment options:

- **Development MinIO** – for local or non-critical use within your Kubernetes cluster.  
- **Production MinIO** – intended for advanced users experienced with running production-grade storage systems.

If you are not familiar with managing storage in Kubernetes, **it is highly recommended to use your cloud provider’s managed storage services**, such as AWS S3 or Google Cloud Storage.  
While MinIO offers an S3-compatible API, managed cloud storage is generally more reliable and easier to operate.

---

## Databases (MySQL)

Two MySQL setups are available:

- **Development / self-managed MySQL** – runs inside your cluster.  
- **Cloud-managed MySQL** – relies on your cloud provider’s database services.

If you lack experience managing databases or don’t have a dedicated team for infrastructure operations, relying on **cloud-managed databases** is usually the best approach for production.

---

## Caching (Redis / Valkey)

A Redis/Valkey namespace is included and follows the same philosophy as the MySQL setup:

- Suitable for development or self-managed environments inside the cluster.
- For production scenarios, **cloud-managed caching services** are recommended to ensure reliability and reduce operational overhead.

---

## Monitoring

This repository includes a **monitoring** namespace preconfigured with essential tools I consider must-haves for any infrastructure.  
You can add more tools or customize the setup depending on your needs, but this provides a solid foundation to start with.

---

