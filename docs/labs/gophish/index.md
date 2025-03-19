# Gophish Lab

## Tabletop Exercise: Planning a Phishing Campaign

Before diving into the hands-on portion, lets discuss the following questions to understand the planning aspects of a phishing campaign:

1. **Target Selection**
   - Who is the target audience for this phishing campaign?
   - What are their roles and responsibilities?
   - What information is valuable to an attacker?

2. **Pretext & Lure**
   - What is a convincing pretext for your phishing email?
   - How would you make the email look legitimate?
   - What kind of attachment or link would entice the target to interact?

3. **Infrastructure & Payloads**
   - What domains or email addresses will be used for sending phishing emails?
   - Will you use an attachment, a credential harvesting site, or both?
   - How will you track engagements and collect responses?

4. **Detection & Response**
   - What security measures might detect this attack?
   - How can defenders mitigate the risk of this type of phishing campaign?
   - What logging and monitoring tools would be helpful in identifying phishing attempts?

<!-- ## Hands-On Lab: Building a Gophish Campaign

### Setting Up Gophish
1. Extract the archive and run Gophish:
   ```bash
   ./gophish
   ```
2. Access the web interface at `https://localhost:3333` and log in.

### Configuring Sending Profiles
1. Navigate to **Sending Profiles** and create a new SMTP profile.
2. Configure the SMTP server settings (e.g., Gmail, Mailtrap, or an internal relay).
3. Test the SMTP configuration to ensure emails can be sent.

### Creating a Phishing Email
1. Go to **Email Templates** and click **New Template**.
2. Create a realistic phishing email, incorporating:
   - A subject line
   - A body message (HTML or plaintext)
   - A call to action with a link or attachment
3. Use placeholders (`{{.FirstName}}`, `{{.LastName}}`) for personalization.

### Setting Up a Landing Page
1. Navigate to **Landing Pages** and create a new page.
2. Choose between:
   - Redirecting the victim to a legitimate site after data capture.
   - Creating a cloned login page for credential harvesting.
3. Enable capturing submitted credentials if applicable.

### Defining the Target Group
1. Go to **Users & Groups** and create a new group.
2. Upload a CSV file or manually add targets.
3. Ensure each entry includes **First Name**, **Last Name**, and **Email**.

### Launching the Campaign
1. Navigate to **Campaigns** and click **New Campaign**.
2. Configure:
   - Name
   - Email Template
   - Landing Page
   - Sending Profile
   - Target Group
3. Set the campaign start time and launch.

### Monitoring and Analyzing Results
1. Check the **Dashboard** for real-time updates.
2. Review the status of emails (sent, opened, clicked, submitted credentials).
3. Analyze collected data and adjust tactics as necessary.

### Post-Engagement Discussion
1. What were the success rates of email opens and credential submissions?
2. What made the phishing attempt convincing or unconvincing?
3. What countermeasures could be implemented to mitigate phishing attacks? -->