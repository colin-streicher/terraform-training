## Deployment Requirements
- deployment system
- what is the acceptable amount of downtime? None is ideal
- Understand the application requirements
- Having git configured

## Security Requirements
- firewall/WAF
- CSP
- vm should use managed identity
  - must limit privileges to least required
  - database user should be limited to minimum grants
- secrets should be stored in keyvault
- https to load balancer
- https to backend
- encrypt at rest, database and vm

## Build Requirements
- Having dns configured
- blue/green deployments - future
- load balancer
- self-healing
- auto-scaling - future
- database should be cloud managed
- cache is built in
