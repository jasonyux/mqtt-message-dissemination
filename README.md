# MQTT Message Dissemination

This file currently contains only instructions to :

- setup the brokers and run all the configured tests. 

Future updates would add more information about:

- detailed configurable aspects of the scripts
- descriptions of how to use the data analysis script

## Project Structure

- `broker/` is the submodule for Mosquitto repository that I forked. That repo contains the source code I have modified for implementing subscription flooding algorithm.
  - **note that the SF related code is in the `subscription_flooding` branch**
- `experiment/` contains all experiments and scripts related to this project
  - `analysis_scripts/` contains python files related to analyzing data
  - `broker_container/` contains docker container configuration, related programs, and experimental data collected for **brokers**
  - `client_container/` contains docker container configuration and related programs for **clients**
  - `mosquitto_container/` contains docker container configuration for the official Mosquitto programs
  - `scripts/` contains scripts used for automating experiments and data collection process

- `programs/` contains the source code for programs used in the experiment. This mainly contains programs for clients, since the broker program is stored under `broker/`
  - `pulisher.c` and `subscriber.c` are the interactive programs used for demonstration
  - `publisher_args.c` and `subscriber_args.c` are the programs that has highly customable aspects. This includes the ability to generate **distinct** (up to 260) topics based on inputs, adjust publication rates, and etc.
  - `publisher_args_dup.c` is similar to `publisher_args`, but all forked publishers will publish under the **same** topic

## Usage

This discusses on the high level of:

1. setup the brokers
2. configure the brokers
3. setup the clients
4. run automation scripts for experiments
5. analyze data

More details will be updated upon requests.

### Broker Setup

1. To set up the brokers, use the `Dockerfile` under `experiment/broker_container` directory to create an image. In this case, I named the image `my-mosq`.

2. create a custom bridge network, which will be used by the brokers and clients. I called it `my-net`.

3. Use the `docker-compose.yml` with `docker-compose up` and the `--scale` option to create **multiple broker instances**

   - note that this will need the image `my-mosq` and the network `my-net`. If you changed the name, you need to change this file as well.

   - this will also create volume mounts of:

     ```yaml
     volumes:
           - ./broker_data:/broker/data
           - ./broker_log:/broker/log
     ```

### Broker Configuration

This setup is crucial to make the SF and PF work.

1. Inside each broker, you need to configure a `.conf` file that will be used by Mosquitto broker to know the IP of other brokers and connect to them. Some examples have been provided under `experiment/broker_container/sample_config`.

Note:

- for subscription flooding, the setup is subtle (will be improved and simplified in the future) such that, for a connection between two brokers `b1` and `b2`, you will have:

  `b1`:

  ```conf
  listener 8088
  allow_anonymous true
  
  connection b1->b2
  address 172.19.0.7:8088
  topic exmp1/temp in 2 "" ""
  ```

  `b2`:

  ```conf
  listener 8088
  allow_anonymous true
  
  connection b2->b1
  address 172.19.0.7:8088
  topic exmp1/temp in 2 "" ""
  ```

  where:

  - `connection b1->b2` and `connection b2->b1` is currently used for loop detection in subscription flooding algorithm. You can name the connection anyway you want, but you must need the structure `<broker_1_name>-><broker_2_name>` for one and the opposite for the other
  - the topic `exmp1/temp` configured is a dummy topic. This is just used for creating bridges.

### Client Setup

In short, this is the same as [Broker Setup](#Broker-Setup), but that another image is created since I need to copy different programs to them.

1. To set up the clients, use the `Dockerfile` under `experiment/client_container` directory to create an image. In this case, I named the image `my-mosq-client`.
2. this will also need the bridge network created before in [Broker Setup](#Broker-Setup)
3. Use the `docker-compose.yml` with `docker-compose up` and the `--scale` option to create **multiple client instances** if needed
   - note that this will need the image `my-mosq-client` and the network `my-net`. If you changed the name, you need to change this file as well.

### Experiment Automation

This section is irrelevant if you do not want to measure the Total Network Traffic or Broker End-to-end Delay. Shell scripts in this repo are mainly to measure those.

However, since some scripts are pretty general, such as `restart_brokers.sh`, you might find those useful.

In general, the scripts under `experiment/scripts` are for two usages:

- `exp_*.sh` is related to experiments mentioned above
- `pcap2csv.sh` is used to transform the collected `.pcap` data to `.csv` used for analysis

To measure **total network traffic**

1. The general one liner would be:

   ```bash
   ./exp.sh <broker_data_path> <exp_timeout> <sub_broker_ip> <pub_broker_ip> <client_executale_path> <broker_program> <broker_config_file>
   ```

   - broker data are written to `<broker_data_path>/b{1..7}`, assuming you have 7 brokers established.
     - note that this directory is relative to the broker, i.e. valid path inside the broker
     - those directories needs to be **created before using this script**
   - broker `TCPDUMP` and `TOP` has  timeout of `<exp_timeout>`
   - subscriber subscribes to address ` <sub_broker_ip>`. 
     - note that this is the IP internal to the containers.
   - publisher publishes to address `<pub_broker_ip>`
   - subscriber and publisher executable *located* at `<client_executale_path>`
   - broker program to run is `<broker_program>`
     - this assumes that the program is contained in the directory `/broker` in the container
   - broker config file to use is `<broker_config_file>`
     - this assumes that the program is contained in the directory `/broker` in the container

   *for example:*

   ```bash
   ./exp.sh /mosquitto/data/heat_map/THR_3-7/OI_3-7/linear_sf 125 172.19.0.4 172.19.0.2 /client pub_flood_broker pub_flood_config.conf
   ```

2. Then, convert the collected data files `.pcap` into `.csv` using `pcap2csv.sh`. This will parse all the `.pcap` into `.csv` using `tshark`, create a folder `csv/` under the `<path_to_b1-b7>`, and put all the parsed csv there.

   ````bash
   ./pcap2csv.sh <path_to_b1-b7>
   ````

   where:

   - `<path_to_b1-b7>` would be the directory that contains the subdirectory `b1/`, `b2/`, ..., `b7`, assuming you have 7 brokers. Those directories would contain the `.pcap` file data is setup correctly
     - note that this directory is relative to the host computer, not containers

   *for example*:

   ```bash
   ./pcap2csv.sh broker_container/data1/delay_graph/tc-20/linear_sf
   ```

   assuming you have directories such as:

   - `broker_container/data1/delay_graph/tc-20/linear_sf/b1`
   - `broker_container/data1/delay_graph/tc-20/linear_sf/b2`
   - etc.

To measure **end-to-end delay**:

1. modify the package loss rate and other relevant network setting for broker containers

   *for example*:

   ```bash
   pumba netem --duration 10m loss --percent 50 "re2:^su"
   ```

   which adds `50%` package loss rate to all brokers with name starting with `su`

2. Use the same `exp.sh` as above

### Analyze Data

The most visual way is to use the Jupyter Notebook under `analysis_scripts/analysis_py.ipynb`.

To manually produce rate plot and cumulative rate plots, one can use the `data_analysis.py`, which will **output** two images, `cumu_plot.png` and `rate_plot.png`, each of which contains:

- byte sent per broker for all 7 brokers
- cumulative bytes sent per broker for all 7 brokers

Usage:

```bash
py .\data_analysis.py <csv_dir> <output_dir> <plot_title_prefix>
```

where:

- the program is with `\` because I am on Windows System using Powershell
- `<csv_dir>` represents the folder containing all the csv data
- `<output_dir>` represents the **output** folder for plots
- `<plot_title_prefix>` represents the plot title prefix

*for example:*

```bash
py .\data_analysis.py "../broker_container/data1/grand_heat_map/SPR_4-6/OI_1-7/linear_sf/csv/" ./ "7/7THR with 1/7 OI"
```

