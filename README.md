# RFrame

## Installation
1. On systems that are using cgroup v2 you may have to add:

    ```
    systemd.unified_cgroup_hierarchy=0
    ```
    to your kernel boot parameters until snap is updated to support cgroup v2.

2. Change your current working directory to the RFrame location:
	```bash
    cd /path/to/RFrame
    ```

3. Install all necessary dependencies by executing the setup script with root privileges:
    ```bash
    sudo ./setup
    ```

## Execution
You can display the usage by executing:
```bash
./rframe --usage
```
