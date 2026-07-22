The goal of this project is to learn the basics of monitoring. It is to help you understand how to monitor the health of a system and how to set up a basic monitoring dashboard.
Requirements

In this project, you will set up a basic monitoring dashboard using Netdata. Netdata is a powerful, real-time performance and health monitoring tool for systems and applications.

- Install Netdata on a Linux system.
- Configure Netdata to monitor basic system metrics such as CPU, memory usage, and disk I/O.
- Access the Netdata dashboard through a web browser.
- Customize at least one aspect of the dashboard (e.g., add a new chart or modify an existing one).
- Set up an alert for a specific metric (e.g., CPU usage above 80%).

You can learn more about installing and configuring Netdata here.

You can follow the above steps manually to get the understanding of the project. Once you have a working setup, create a few shell scripts to automate the setup and test the monitoring dashboard.

- setup.sh: A shell script to install Netdata on a new system.
- test_dashboard.sh: Script to put some load on the system and test the monitoring dashboard.
- cleanup.sh: Script to clean up the system and remove the Netdata agent.

The goal with this automation is to slowly get accustomed to DevOps practices and CI/CD pipelines.
