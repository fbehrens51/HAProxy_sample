# HAProxy TCP Passthrough

**This is not a polished project**.  The point of this was to come up with a rough working solution to help with transition of application from existing hosted platform to the new platform.

## Problem/Requirements

### Hosted Platform transition for an application

1. Cannot depend on timely DNS changes and need to keep the exposed url the same for end users/systems.   
2. Ability to control sending traffic to new and/or old platform
3. Preserve SSL termination within those platforms
4. Application in either platform hosted behind ELB (in TCP mode)
5. Not overly complex.  This is not intended to live long term (will go away once satisfied with new platform).

**Notes**
* Timely DNS changes is not within our problem to solve
* DNS can occur eventually when satisfied with new platform results

## Proposed Solution

### Proxy Layer

- Allows an intermediate layer to control which backend traffic is sent to.  (Req 2)
- TCP Mode - In this mode it will pass through the request to the platform and preserve the proper endpoint for SSL termination. (Req 3)

### DNS

- No DNS change (Req #1)
  - Proposed steps to Reuse existing ELB for HAProxy (rough..to discuss)
    - Create new ELB
      - configure identical to existing, attach same (or new set of) instances, & validate
    - Update any Security Groups/rules
    - Spin HAProxy instances pointing at new ELB & validate
    - Attach HAProxy instances to existing ELB & validate 
    - Remove non-HAproxy instances from ELB
  - Pros
    - More control over when traffic changes to use HAProxy
    - No DNS change, so don't have to wait for changes to propagate out to all clients
    

- DNS Change, but doesn't require it to happen immediately (Req #1)
  - Proposed steps for using new ELB for HAProxy layer
    - Create new ELB
    - Spin up HAProxy instances pointing at existing ELB
    - Update any Security Groups/rules
    - Validate 
    - request DNS change to occur and wait for it to happen
  - Pros
    - Can validate what will be the live stack prior to making DNS change
  - Cons
    - no control over when new stack gets traffic (at the mercy of the DNS update and propagation)

## Health Check
#### Additional Info
This can be a little tricky.  It really depends on what level of health check we want and how the underlying platform and ELB healthchecks are configured.
1. Since the underlying platforms are already using their own ELB(s), and those have their own health check(s), what level of reliance should we have on those?
2. When implementing our own, we want to be sure that we're not removing the entire platform if one instance of the underlying application fails
 
#### Implementing health checks
   
1. Plain TCP check - will validate backend is reachable, but not necessarily that the application is working
2. ssl type check - will validate backend is reachable and supporting ssl connections, but not necessarily that the application is working  
3. more complex TCP check - can customize for needs
   1. Based on underlying platform health checks
      1. This helps, but wouldn't remove the server from the backend if the platform was up, but the application was down
   2. Based on application health checks
      1. Options
          1. Application exposes a health check of its own 
          2. Write custom tcp-check to validate application is running
      2. Concerns
          1. Sounds Ideal, but if we hit the one instance that just went bad, we would remove the whole platform.
             1. We would need to build in some fault tolerance.
             2. Is this really the responsibility of the underlying platform?

## Logging

1. The example configuration is currently configured to write to local rsyslog which writes out to `/var/log/haproxy.log`.
2. This can easily be modified to write to an external location.




