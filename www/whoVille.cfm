<cfinclude template="env.cfm">
<html>
	<head>
		<title>whoVille Whois Lookup</title>
		<link rel="stylesheet" href="general.css">
		<script>
			function clearForm(myFormElement) {
				var elements = myFormElement.elements;
				myFormElement.reset();
				for(i=0; i<elements.length; i++) {
					field_type = elements[i].type.toLowerCase();
					switch(field_type) {
						case "text":
						case "password":
						case "textarea":
						case "hidden":
							elements[i].value = "";
							break;

						case "radio":
						case "checkbox":
							if (elements[i].checked) {
								elements[i].checked = false;
							}
							break;

						case "select-one":
						case "select-multi":
							elements[i].selectedIndex = -1;
							break;

						default:
							break;
					}
				}
			}
			function togThis(id) {
				ele = document.getElementById("output" + id);
				if (ele) {
					if (ele.style.display == "none") {
						ele.style.display = "block";
					} else {
						ele.style.display = "none";
					}
				}
			}
		</script>
	</head>
<body id="whoVille">
	<div id="backlink"><a href="/">Back to App List</a></div>
	<h1>whoVille Whois Lookup</h1>
	<h3>Performs a Whois Lookup on a set of Domains or IP addresses.</h3>
<cfoutput>
	<cfsilent>
		<cfif structKeyExists(form,"domains") >
			<cfset valDomains = form.domains />
		<cfelse>
			<cfset valDomains = "" />
		</cfif>
	</cfsilent>

	<form method="post" action="#cgi.script_name#" name="main" id="main">
		<div class="panel">
			<label for="domains">Look up Domains</label>
			<textarea name="domains" rows="10">#valDomains#</textarea>
		</div>
		<div class="panel">
			<label for="host">Host (optional)</label>
			<input name="host" type="text" value="#iif(structKeyExists(form, "host"),"form.host",de(""))#">

			<label for="port">Port (optional)</label>
			<input name="port" type="text" value="#iif(structKeyExists(form, "port"),"form.port",de(""))#">

			<div class="checkboxes">
				<input name="legal" type="checkbox" #iif(structKeyExists(form, "legal"), de("CHECKED"), de(""))# >
				<label for="legal">Suppress Legal Disclaimers (optional)</label>
				<br><br>
				<input name="verbose" type="checkbox" #iif(structKeyExists(form, "verbose"), de("CHECKED"), de(""))# >
				<label for="verbose">Verbose (optional)</label>
			</div>	
		</div>
		<br style="clear: both;">
		<p class="buttons"><input type="submit" name="Submit"> <input type="button" value="Clear" onclick="clearForm(document.getElementById('main'));"></p>
	</form>
</cfoutput>

<cfif structKeyExists(form, "Submit")  >
	<cfsilent>
		<cfset theseDomains = listToArray(form.domains, Chr(10)) />
		<cfset rawArray = ArrayNew(2) />
		<cfset exeErr = "" />
		<cfset exeName = "/usr/bin/whois" />
		<cfset preArg = "" />
		<cfif structKeyExists(form, "host") and Len(Trim(form.host)) >
			<cfset preArg &= " --host " & form.host />
			<cfset thisHost = "@" & form.host />
		<cfelse>
			<cfset thisHost = form.host />
		</cfif>
		<cfif structKeyExists(form, "port") and Len(Trim(form.port)) >
			<cfset preArg &= " --port " & form.port />
		</cfif>
		<cfif structKeyExists(form, "verbose") >
			<cfset preArg &= " --verbose" />
		</cfif>
		<cfif structKeyExists(form, "legal") >
			<cfset preArg &= " -H" />
		</cfif>

		<cfloop index="dI" from="1" to="#ArrayLen(theseDomains)#">		
			<cfset thisDOM = theseDomains[di] />
			<cfset exeArg = Trim(preArg) & " " & thisDOM />

			<cfexecute variable="whosource" name="#exeName#" arguments="#exeArg#" errorVariable="exeErr" timeout="30"/>
			<cfset rawArray[ArrayLen(rawArray)+1][1] = "#thisDOM# #thisHost#" />
			<cfset rawArray[ArrayLen(rawArray)][2] = whosource />

		</cfloop>
	</cfsilent>

	<cfoutput>
		<cfif ArrayLen(rawArray) >
			<cfloop index="rI" from="1" to="#ArrayLen(rawArray)#">
<hr>
<h2><a href="javascript:togThis('#rI#');">#rawArray[rI][1]#</a></h2>
<pre id="output#rI#">#rawArray[rI][2]#</pre>
			</cfloop>
		
		</cfif>
	</cfoutput>
</cfif>

</body>
</html>