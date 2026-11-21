!!! step "Delete everything you started"
    ```bash
    kill %1 2>/dev/null; kubectl delete deploy,svc,pod --all
    ```

    !!! see "You should see"
        `kubectl get pods` says `No resources found`. The instructor deletes the GPU machines right after the session.

!!! step "Tell us how it went"
    Scan the feedback QR code on your table card.

### Take it home

- **[Build it yourself on one Jarvislabs GPU VM](jarvislabs-solo.md)**: the same scripts, one machine, all four teams.
- **[The GKE edition](gpu-sharing-on-gke.md)**: the same ideas on Google Kubernetes Engine.
- **[HAMi](../reference/hami.md)** · **[Cheat sheet](../reference/cheatsheet.md)** · **[What's next: AICR & Agent Substrate](../reference/whats-next.md)**

!!! success "Thank you!"
    You built a GPU cluster from scratch, broke it four different ways, and fixed it. See you at the next DevFest!
