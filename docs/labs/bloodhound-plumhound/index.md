# Lab - BloodHound & PlumHound

???+ warning "Prerequisites" 
    You will need at least the `GOAD-DC02` (`192.168.56.11`) target VM and The Forge VM up and running for this Lab. If you can have **both** GOAD VMs on, that would yield even better results since we are trying to map out a whole Domain.

## Intro

Active Directory (AD) remains a prime target for attackers due to its complexity and inherent misconfigurations. In this lab, we’ll use BloodHound to map relationships within AD and identify potential attack paths. We'll then integrate PlumHound to assess risk proactively, prioritizing misconfigurations before exploitation.

By the time you finish this process, you’ll have a **full map of Active Directory attack paths**, showing how an adversary could pivot and escalate privileges. The workflow for this is:  

1. **Start Neo4j** → Gives BloodHound a database.  
2. **Run BloodHound** → Opens the GUI.  
3. **Use bloodhound-python** → Collects real-world AD data.  
4. **Run PlumHound** → Automates the analysis.  
5. **View the Report** → See the results in a clear, actionable format.  

With this setup, you’re well on your way to mastering AD security—whether you’re defending an environment or finding attack paths before the bad guys do. 

Let’s dive in.

## Walkthrough
*Uncovering Active Directory Attack Paths Like a Pro*  

Alright, let’s walk through setting up BloodHound and PlumHound for Active Directory (AD) analysis. Think of this as a hacker’s reconnaissance mission—you’re gathering intelligence, analyzing attack paths, and identifying weak spots in an AD environment.  

### Step 1: Kickstarting Neo4j
First things first, BloodHound needs a backend database, and that’s where Neo4j comes in. Fire up a terminal and run:  

```bash
sudo neo4j console
```

???- note "Command Options/Arguments Explained"
    - `sudo`: Runs with root privileges, required for Neo4j to bind to network ports and access system resources
    - `neo4j`: Graph database management system that stores and queries the relationships between Active Directory objects
    - `console`: Runs Neo4j in the foreground with live logging output, allowing you to monitor database activity and catch errors immediately
    - Why needed: BloodHound requires a Neo4j database backend to store and query the complex relationships in Active Directory. Running in console mode (vs. as a background service) makes troubleshooting easier during lab work.
    - What happens next: Navigate to http://localhost:7474 to access the Neo4j browser interface and set your credentials

![Neo4j console startup showing initialization messages and HTTP connector binding to port 7474](img/neo4jDB.png){ width="70%" }
/// caption
DB setup
///
  
Neo4j is like BloodHound’s brain—it stores all the juicy AD relationships we’re about to collect. The `console` flag keeps it running in the foreground, so we can monitor logs and catch any errors right away. Without this, BloodHound has nowhere to dump the data, so this step is non-negotiable.

After starting up Neo4j in the console, open a browser and go to http://localhost:7474. You'll be asked to enter the default credentials of user "neo4j" and password "neo4j".

![Neo4j browser login screen showing default username and password fields](img/default-DB-creds.png){ width="70%" }
/// caption
Default DB Creds
///

After that, you'll be asked to provide a new password. We're going to set the new password to "ridgeback".

![Neo4j password change prompt requesting new password and confirmation](img/new-DB-password.png){ width="70%" }
/// caption
Set New DB Password
///

### Step 2: Launching BloodHound 
Next, we need the interface that’ll let us visualize everything. Open another terminal and navigate to your BloodHound directory and start to up the BloodHound GUI with the commands below.

```bash
cd ~/BloodHound-linux-x64
./BloodHound --no-sandbox
```

???- note "Command Options/Arguments Explained"
    - `cd ~/BloodHound-linux-x64`: Changes to the BloodHound installation directory
    - `./BloodHound`: Executes the BloodHound application binary (Electron-based GUI)
    - `--no-sandbox`: Disables Chromium's sandboxing security feature, required when running as root or in containerized environments
    - Why needed: The BloodHound GUI provides the visual interface for querying and exploring Active Directory attack paths. The `--no-sandbox` flag prevents permission errors that commonly occur when running Electron apps with elevated privileges.
    - What happens next: You'll be prompted to enter Neo4j credentials (username: neo4j, password: ridgeback) to connect the GUI to the database

![Terminal showing BloodHound application launching with --no-sandbox flag](img/start-bloodhound.png){ width="70%" }
/// caption
Start BloodHound
///
  
The `--no-sandbox` flag helps avoid permission issues when running the Electron-based app.

The first thing you'll see *should* be a prompt for the Neo4j credentials we just set. Enter the username "neo4j" and the password "ridgeback". This will connect the BloodHound GUI with the Neo4j DB.

![BloodHound GUI authentication dialog prompting for Neo4j database credentials](img/DB-auth.png){ width="70%" }
/// caption
DB Authentication
///

After that, BloodHound will be waiting for data—so let’s give it something to work with.  

### Step 3: Collecting AD Data 
Now comes the fun part: data collection. This is where we act like an attacker or pentester mapping out an AD environment. `bloodhound-python` is a tool used to collect Active Directory (AD) data for analysis in BloodHound, aiding in security assessments. 

<!-- For the sake of the Lab, we're going to assume we obtained the user `brandon.stark`'s credentials by either initial compromise or provided by the POC. -->

In a new terminal, run:  

<!-- ```bash
bloodhound-python --zip -c all -d north.sevenkingdoms.local -u brandon.stark -p iseedeadpeople -dc winterfell.north.sevenkingdoms.local -ns 192.168.56.11 --dns-timeout 60 --dns-tcp
```   -->

```bash
bloodhound-python --zip -c all -d north.sevenkingdoms.local -u robb.stark -p sexywolfy -dc winterfell.north.sevenkingdoms.local -ns 192.168.56.11 --dns-timeout 60 --dns-tcp
```

![Terminal output showing bloodhound-python collecting Active Directory data with progress indicators](img/data-collection.png){ width="70%" }
/// caption
Data Collection
///

???- note "Command Options/Arguments Explained"
    Breaking it down:  
    - `-c all` → Grabs everything: users, groups, ACLs, sessions—you name it.  
    - `-d north.sevenkingdoms.local` → That’s our target AD domain.  
    - `-u robb.stark -p sexywolfy` → Our captured and cracked credentials.
    - `-dc winterfell.north.sevenkingdoms.local` → The specific domain controller we're hitting.
    - `-ns 192.168.56.11` → Using the domain controller for DNS resolution.  
    - `--dns-timeout 60 --dns-tcp` → Tweaks DNS settings for better reliability.  

Looks like we found some data alright!

???+ success "Checkpoint: Verify Data Collection"
    After running bloodhound-python, you should have:

    - [ ] A ZIP file created in your current directory (ending in `_bloodhound.zip`)
    - [ ] No authentication errors in the output
    - [ ] Multiple JSON files inside the ZIP containing users, groups, computers, and ACL data

???+ note
    By default, `bloodhound-python` uses Python's `dns.resolver`, which may bypass `/etc/hosts`. If the DC hostname is manually mapped in `/etc/hosts`, `bloodhound-python` might fail to resolve it properly. Specifying `-ns 127.0.0.1` or `-ns 192.168.56.11` ensures that the system's built-in resolver is used, allowing the tool to recognize the correct IP mappings.

After running this, you’ll get a ZIP file full of BloodHound-compatible JSON data. This is the blueprint of AD relationships, which we’re about to analyze.  

### Step 4: Uploading Data Into Neo4j

Go back to the BloodHound GUI.

- click the Upload button

- select the file ending in "bloodhound.zip" that was just created from the last step

- hit "Open" to load the data into the Neo4j DB

![BloodHound GUI showing Upload Data button and file selection dialog](img/upload-data.png){ width="70%" }
/// caption
Upload Data
///

### Step 5: BloodHound Data Visualization

Staying within the BloodHound GUI, you can navigate the data via the collapsible menu shown below.

![BloodHound sidebar menu displaying pre-built queries including Find all Domain Admins](img/menu.png){ width="70%" }
/// caption
Menu
///

We can get a nice visualization of the Domain Admins by selecting the "Find all Domain Admins" pre-built query shown above.

![BloodHound graph visualization showing Domain Admins and their relationships](img/DAs.png){ width="70%" }
/// caption
Domain Admins
///

???+ note
    This is just one of many pre-built queries. Feel free to continue exploring other on your own.

### Step 6: Running PlumHound for Automated Analysis  
BloodHound is great, but manually sifting through data can be a pain. That’s where PlumHound comes in—it automates the analysis for us. PlumHound is an offensive security tool that processes BloodHound JSON data to identify security risks, privilege escalation paths, and lateral movement opportunities in Active Directory environments. This guide explains how to extract, analyze, and interpret BloodHound data using PlumHound.

Open a new terminal and run these commands.

First, navigate to the PlumHound directory and activate the virtual environment:

```sh
cd ~/git-tools/PlumHound/
source venv/bin/activate
```

???- note "Command Options/Arguments Explained"
    - `cd ~/git-tools/PlumHound/`: Changes to the PlumHound installation directory
    - `source venv/bin/activate`: Activates the Python virtual environment for PlumHound
    - Why virtual environments: Isolates PlumHound's Python dependencies from system-wide packages, preventing version conflicts and ensuring the tool runs with its tested library versions
    - How to verify: After activation, your terminal prompt will show `(venv)` prefix, indicating you're in the virtual environment
    - When needed: Always activate the venv before running PlumHound commands, otherwise you may encounter import errors or version mismatches 

Now we can execute the PlumHound commands below.

```bash
python PlumHound.py -p ridgeback --easy
```

???- note "Command Options/Arguments Explained"
    - `python PlumHound.py`: Executes the PlumHound analysis script
    - `-p ridgeback`: Specifies the Neo4j database password (set earlier when configuring Neo4j)
    - `--easy`: Runs a simplified "sanity check" query that lists domain users to verify database connectivity
    - Why start with --easy: This quick test confirms PlumHound can successfully connect to Neo4j and retrieve data before running more complex analysis tasks
    - Expected output: A simple list of domain users extracted from BloodHound data

This first command (`--easy`) does a quick, out-of-the-box analysis to make sure the DB connection works. Note that we specified "ridgeback" as the Neo4j DB password in the above command.

The output shows us a simple list of Domain users.

![PlumHound terminal output showing list of domain users from sanity check query](img/easy.png){ width="70%" }
/// caption
--easy
///

```bash
python PlumHound.py -p ridgeback -x tasks/default.tasks
```

???- note "Command Options/Arguments Explained"
    - `python PlumHound.py -p ridgeback`: Same as before - runs PlumHound with Neo4j password authentication
    - `-x tasks/default.tasks`: Executes a comprehensive analysis using predefined task definitions from the tasks file
    - What default.tasks includes: Pre-configured queries for common AD attack paths, privilege escalation opportunities, ACL misconfigurations, and high-value targets
    - Output location: Generates detailed HTML/CSV reports in the `reports/` directory
    - Why use task files: Automates systematic analysis instead of manually running queries one-by-one in BloodHound GUI, saving time and ensuring comprehensive coverage

The second command (`-x tasks/default.tasks`) runs a more detailed assessment based on predefined task rules.
  
![PlumHound terminal showing progress of default tasks execution with multiple queries completing](img/default-tasks.png){ width="70%" }
/// caption
Default Tasks
///

The exact list of default tasks can be found in the tool documentation [here](https://www.plumhound.com/#plumhound-examples:~:text=The%20default%20tasklist%20generates%20the%20following%20reports%3A).

This step essentially translates raw BloodHound data into meaningful findings—helping us spot privilege escalation paths and misconfigurations without manually clicking around.   

### Step 7: Reviewing the Report 
Now let’s check out what PlumHound found. Navigate to the reports folder and open the HTML report:  

```bash
cd reports/
ll
```

![Terminal directory listing showing PlumHound-generated HTML and CSV report files](img/report-list.png){ width="70%" }
/// caption
Report List
///

Open the main `index.html` report with the command below.

```bash
firefox ~/git-tools/PlumHound/reports/index.html
```

???- note "Command Options/Arguments Explained"
    - `firefox`: Launches the Firefox web browser
    - `~/git-tools/PlumHound/reports/index.html`: Path to PlumHound's main HTML report dashboard
    - What the report shows: Interactive HTML dashboard with links to detailed findings including privilege escalation paths, high-value targets, ACL misconfigurations, and other Active Directory weaknesses
    - Why HTML format: Provides a professional, shareable report that can be reviewed by security teams without requiring Neo4j or BloodHound installation
    - Alternative viewers: You can also open the report with any web browser (Chrome, Edge, etc.) or serve it via HTTP for remote viewing

![PlumHound HTML report dashboard displaying Active Directory analysis results and attack paths](img/report.png){ width="70%" }
/// caption
Report
///

This is where all our work pays off. The report will highlight attack paths, misconfigured permissions, and other AD weaknesses—like spotting an overprivileged account that could lead to domain dominance.  

Want to dig deeper? Try tweaking collection parameters or using custom tasks in PlumHound for even more targeted analysis. Happy hunting!🐺

## Lab Cleanup🧹

Once you're done analyzing AD attack paths, it's important to shut everything down properly to free up system resources. Follow these steps:

### Stop PlumHound  
Deactivate the virtual environment by running:

```bash
deactivate
```

???- note "Command Options/Arguments Explained"
    - `deactivate`: Exits the Python virtual environment and returns your shell to the system Python environment
    - Why deactivate: Frees up the virtual environment's PATH modifications and prevents accidentally running PlumHound commands outside the venv context in future terminal sessions
    - How to verify: After deactivation, the `(venv)` prefix disappears from your terminal prompt
    - When needed: Always deactivate when finished working with PlumHound to avoid confusion about which Python environment is active

This exits the Python virtual environment used for PlumHound.

### Close BloodHound  
If BloodHound is still running, close the GUI or press `CTRL+C` in its terminal window to stop it.

### Shut Down Neo4j  
To stop the Neo4j database, press `CTRL+C` in its terminal window to stop it.

### Remove Temporary Files (Optional)  
If you want to clean up any leftover BloodHound data:

```sh
rm -rf ~/git-tools/PlumHound/reports/*
```

???- note "Command Options/Arguments Explained"
    - `rm`: Remove/delete files and directories
    - `-r`: Recursive - deletes directories and their contents
    - `-f`: Force - suppresses confirmation prompts and continues even if files don't exist
    - `~/git-tools/PlumHound/reports/*`: Target path - the asterisk wildcard matches all files and directories within the reports folder
    - Why cleanup: Removes old HTML/CSV reports to free up disk space and prevent confusion when running fresh analyses in future labs
    - What's preserved: The PlumHound tool itself and the tasks directory remain untouched - only generated reports are deleted

This removes old reports but keeps the tools installed for future use.

### ✅ Lab Cleaned Up!
Everything is now shut down, and your system is back to normal. If you plan to run the lab again, simply start from **Step 1**.

## OPTIONAL: NetExec Tie-In

???+ info "Optional"
    This is an **optional** part of the lab to explore on your own. No guidance will be provided.

Did you know that NetExec is capable of tying in to BloodHound? Well, it can!

Here's the [first step](https://www.netexec.wiki/getting-started/bloodhound-integration) of getting it integrated.

Have fun exploring!