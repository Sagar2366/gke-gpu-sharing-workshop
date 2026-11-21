!!! abstract "What you'll do"
    Remove everything you created, so the GPU is free for the next person and nothing keeps running.

!!! step "Delete everything you started"
    ```bash
    kill %1 2>/dev/null; kubectl delete deploy,svc,pod --all
    ```

    !!! see "You should see"
        Your deployments, services and pods deleted. `kubectl get pods` now says `No resources found`.

    !!! why "Why this matters"
        Pods on a shared GPU hold chairs (and memory) until you delete them, even when they're idle.

!!! step "Check nothing is left"
    ```bash
    kubectl get all
    ```

    !!! see "You should see"
        Nothing except, possibly, the default `kubernetes` service. The organisers delete the shared cluster right after the session.

<!-- only:gke -->
!!! note "Doing this in your own project?"
    Deleting pods isn't enough there: **GPU nodes bill every second they exist**. Follow the last step of
    [Run it in your own project](own-project.md) to delete the GPU node pool or the whole cluster.
<!-- /only -->
<!-- only:jarvislabs -->
!!! note "Doing this on your own Jarvislabs VM?"
    Deleting pods isn't enough there: **GPU VMs bill every minute they exist**. Follow the last step of
    [Run the labs on one Jarvislabs GPU VM](jarvislabs-solo.md) to delete the VM.
<!-- /only -->

!!! step "Tell us how it went"
    Scan the feedback QR code on your table card. It takes one minute and helps the next workshop.
