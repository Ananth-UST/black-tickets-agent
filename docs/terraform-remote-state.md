# Terraform Remote State

## Why Remote State Is Needed

Terraform state records the resources Terraform manages and maps resource blocks to real AWS infrastructure. Keeping state only on a local machine is risky because it can be lost, overwritten, or become different between team members.

BlackTickets prepares an S3 bucket for remote state:

```text
blacktickets-dev-tfstate
```

This change only creates the remote-state infrastructure. It does not migrate Terraform state and does not add a backend block yet.

## State Locking

Terraform state should be locked while a plan or apply is running. Without locking, two people or two automation jobs can update the same state at the same time and corrupt it.

BlackTickets prepares a DynamoDB lock table:

```text
blacktickets-dev-terraform-locks
```

The table uses `PAY_PER_REQUEST` billing and a string partition key named `LockID`, which is the standard Terraform lock table shape.

## Versioning

The state bucket has S3 versioning enabled. Versioning protects against accidental overwrites and makes it possible to recover an earlier state object if a bad migration or apply damages the latest state.

Noncurrent state versions expire after 90 days to limit long-term storage growth.

## Disaster Recovery

Remote state improves recovery because state is stored in AWS rather than on one workstation.

For recovery:

1. Check S3 object versions for the state file.
2. Restore a known-good previous version if needed.
3. Verify the restored state with `terraform plan`.
4. Avoid manually editing state unless there is no safer path.

The bucket also uses server-side encryption with AES256 and blocks public access.

## Team Collaboration

Remote state lets the team share one authoritative state file. With DynamoDB locking, only one Terraform operation can modify state at a time.

After this infrastructure is applied, the next separate step is to add a Terraform backend block and run `terraform init -migrate-state`. That migration should be done deliberately and reviewed before applying.
