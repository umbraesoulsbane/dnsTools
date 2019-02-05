<cfinclude template="env.cfm">
<html>
	<head> 
		<title>dnsTools</title>
		<link rel="stylesheet" href="general.css">
	</head> 
	<body id="root"> 
		<h1>dnsTools</h1>
		<h3>This application provides tools for bulk dns functions like digs as well as the ability to take AWS Route 53 exports and conver them to creates.</h3>
		<strong>Applications</strong>
		<ul>
			<li><a href="awsFormatter.cfm">AWS Router 53 Formatter</a>: Take AWS JSON Exports and Converts them per AWS Route 53 rules to allow creates.</li>
			<li><a href="digDug.cfm">Dig Dug</a>: Basic DNS Tools.
				<ul>
					<li>Allows Bulk DNS Lookups against specific Name Servers</li>
					<li>Allows for a "source" Name Server to compare entries</li>
					<li>Allow for processing existing AWS Route 53 exports to run compares</li>
				</ul>
			</li>
			<li><a href="whoVille.cfm">whoVille Whois Lookup</a>: Looks up a Domain or IP Address ownership information.</li>
			<li><a href="dbParse.cfm">DB Parse</a>: Parses a Bind output file to list contents. This may not assume a standard Bind file. Was designed for unknown provided file.</li>
		</ul>
			  
	</body>
</html>