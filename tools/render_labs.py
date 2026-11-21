# render_labs.py: expands {{SNIPPET}} placeholders in tools/lab-src/*.md into docs/labs/*.md
# Usage: python3 tools/render_labs.py tools/lab-src/*.md
import re, sys, os
SEL = {
 'ts':  ['cloud.google.com/gke-gpu-sharing-strategy: time-sharing','cloud.google.com/gke-max-shared-clients-per-gpu: "4"','workshop.devfest/table: ${TABLE}'],
 'mps': ['cloud.google.com/gke-gpu-sharing-strategy: mps','workshop.devfest/table: ${TABLE}'],
 'mig': ['cloud.google.com/gke-gpu-partition-size: ${MIG_PARTITION}'],
 # story flow (Jarvislabs): one GPU per table, mode switched by the instructor
 'ex':   ['workshop.devfest/gpu-mode: exclusive','workshop.devfest/table: ${TABLE}'],
 'tsj':  ['workshop.devfest/gpu-mode: time-sharing','workshop.devfest/table: ${TABLE}'],
 'hami': ['workshop.devfest/gpu-mode: hami','workshop.devfest/table: ${TABLE}'],
}
def pod(name, strat, command, env=(), gpus=1, restart=None, deadline=None, hostipc=None, requests=False, labels=None, hami=None):
    if hostipc is None: hostipc = (strat=='mps')
    L=['kubectl apply -f - <<EOF','apiVersion: v1','kind: Pod','metadata:',f'  name: {name}']
    if labels: L.append(f'  labels: {labels}')
    L.append('spec:')
    if restart: L.append(f'  restartPolicy: {restart}')
    if deadline: L.append(f'  activeDeadlineSeconds: {deadline}')
    if hostipc: L.append('  hostIPC: true')
    L.append('  nodeSelector:'); L += ['    '+s for s in SEL[strat]]
    L += ['  containers:',f'  - name: {name.split("-")[0]}','    image: ${IMAGE}',f'    command: {command}','    env:','    - {name: LD_LIBRARY_PATH, value: /usr/local/nvidia/lib64}']
    L += ['    - {name: %s, value: "%s"}'%(k,v) for k,v in env]
    L.append('    resources:')
    if requests: L.append('      requests: {cpu: 500m, memory: 2Gi}')
    lim = f'nvidia.com/gpu: {gpus}' + (f', nvidia.com/gpumem: {hami[0]}, nvidia.com/gpucores: {hami[1]}' if hami else '')
    L.append(f'      limits: {{{lim}}}')
    L += ['    volumeMounts: [{name: scripts, mountPath: /scripts}]','  volumes:','  - name: scripts','    configMap: {name: gpu-scripts}','EOF']
    return L
SNIPS = {
 'BURN_TS':  lambda: pod('burn','ts','["bash", "-c", "/usr/local/nvidia/bin/nvidia-smi -L; exec python3 /scripts/burn.py"]',[('DUTY','${DUTY:-1.0}')],labels='{app: burn, team: ${TEAM}}',requests=True),
 'BURN_MPS': lambda: pod('burn','mps','["python3", "/scripts/burn.py"]',labels='{app: burn, team: ${TEAM}}',requests=True),
 'BURN_MIG': lambda: pod('burn-mig','mig','["python3", "/scripts/burn.py"]',[('MATRIX','4096')],labels='{app: burn}',requests=True),
 'MEMHOG_TS': lambda gib: pod('memhog','ts','["python3", "/scripts/memhog.py"]',[('GIB',gib)]),
 'MEMHOG_MPS': lambda gib: pod('memhog','mps','["python3", "/scripts/memhog.py"]',[('GIB',gib)]),
 'MEMHOG_MPS_OVERRIDE': lambda: pod('memhog','mps','["python3", "/scripts/memhog.py"]',[('GIB','14'),('CUDA_MPS_PINNED_DEVICE_MEM_LIMIT','0=16G'),('CUDA_MPS_ACTIVE_THREAD_PERCENTAGE','100')]),
 'MEMHOG_MIG': lambda: pod('memhog-mig','mig','["python3", "/scripts/memhog.py"]',[('GIB','${MIG_MEMHOG_GIB:-8}')]),
 'PROBE_MPS_NOIPC': lambda: pod('probe-noipc','mps','["python3", "/scripts/probe.py"]',restart='Never',deadline=90,hostipc=False),
 'PROBE_MPS': lambda: pod('probe','mps','["python3", "/scripts/probe.py"]',restart='Never'),
 'PROBE_MPS2': lambda: pod('probe2','mps','["python3", "/scripts/probe.py"]',restart='Never',gpus=2),
 'PROBE_EX':  lambda: pod('probe','ex','["bash", "-c", "nvidia-smi -L; python3 /scripts/probe.py"]',restart='Never'),
 'HOLD_EX':   lambda name: pod(name,'ex','["sleep", "infinity"]',labels='{app: hold}'),
 'BURN_TSJ':  lambda: pod('burn','tsj','["bash", "-c", "nvidia-smi -L; exec python3 /scripts/burn.py"]',[('DUTY','${DUTY:-1.0}')],labels='{app: burn, team: ${TEAM}}',requests=True),
 'MEMHOG_TSJ': lambda gib: pod('memhog','tsj','["python3", "/scripts/memhog.py"]',[('GIB',gib)]),
 'PROBE_HAMI': lambda: pod('probe','hami','["python3", "/scripts/probe.py"]',restart='Never',hami=('${GPU_MEM:-4000}','${GPU_CORES:-25}')),
 'BURN_HAMI': lambda: pod('burn','hami','["python3", "/scripts/burn.py"]',labels='{app: burn, team: ${TEAM}}',requests=True,hami=('4000','${GPU_CORES:-25}')),
 'MEMHOG_HAMI': lambda gib: pod('memhog','hami','["python3", "/scripts/memhog.py"]',[('GIB',gib)],hami=('${GPU_MEM:-4000}','25')),
 'PROBE_MIG': lambda: pod('probe-mig','mig','["bash", "-c", "/usr/local/nvidia/bin/nvidia-smi -L; python3 /scripts/probe.py"]',restart='Never'),
}
def block(lines, indent):
    pad=' '*indent
    out=[pad+'```bash']+[pad+l for l in lines]+[pad+'```']
    return '\n'.join(out)
def render(src):
    def sub(m):
        indent=len(m.group(1)); name=m.group(2); arg=m.group(3)
        f=SNIPS[name]; lines=f(arg) if arg else f()
        return block(lines, indent)
    return re.sub(r'^( *)\{\{(\w+)(?::([^}]+))?\}\}$', sub, src, flags=re.M)
for f in sys.argv[1:]:
    out=os.path.join(os.path.dirname(__file__), 'build', 'labs', os.path.basename(f)); os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out,'w').write(render(open(f).read()))
    print('rendered',out)
