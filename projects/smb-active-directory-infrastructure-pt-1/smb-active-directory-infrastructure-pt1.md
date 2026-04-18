# Small-Medium Business Active Directory Infrastructure Part 1: Initial Setup

## Introduction

In this series of write-ups I am going to detail the set up and configuration of a medium-sized corporate office intranet from initial DC promotion, configuration of network services, file sharing, common-sense group policies for basic security and standardization, to the creation of a hybrid identity, remote access VPN, and backup and recovery of critical services and resources.

I will be creating a simple perimeter network with a Pfsense firewall for isolation and to demonstrate the configuration of a remote access VPN, but because the focus of this lab project is on the configuration of essential IT services I will be leaving the network unsegmented. It is possible to create a router-on-a-stick topology with Pfsense, but I decided against doing this here. In an [older project](<../smb-active-directory-infrastructure-segmented/active-directory-infrastructure-segmented.md>) I configured a ROAS topology with Pfsense and found it added unnecessary complexity for a project that was otherwise focused on application layer technologies.

In this first write-up I will go through initial forest creation, the promotion of domain controllers, the creation of the organizational unit structure, and the creation of users. Most of these tasks will be done with scripts I have pre-written.

## Table of Contents
- Firewall configuration overview
- Forest creation and promoting domain controllers