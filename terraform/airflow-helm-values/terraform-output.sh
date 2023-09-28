#!/bin/bash
export DB_PASSWORD=$(terraform output -raw db_password)
export DB_HOST=$(terraform output -raw private_ip_address)
