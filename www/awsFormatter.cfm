<cfinclude template="env.cfm">
<cfset rawDir = ExpandPath(assetFolder & "/raw/") />
<cfset proDir = ExpandPath(assetFolder & "/processed/") />
<html>
	<head> 
		<title>Route 53 JSON Formatter</title>
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
			function runVal() {
				<cfoutput>setFile = "#cgi.script_name#";</cfoutput>
				window.location.href = setFile + "?goValidate";
			}
		</script>
	</head> 
	<body id="awsformat"> 
		<div id="backlink"><a href="/">Back to App List</a></div>
		<h1>Route 53 JSON Formatter</h1>
		<h3>This will take Route 53 exported JSON files in the raw folder (<cfoutput>/#assetFolder#/raw/</cfoutput>), add the <a href="https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-migrating.html#hosted-zones-migrating-edit-records" target="_blank">required fields and rules</a> 
			for migration finally saving the resulting files in the processed folder (<cfoutput>/#assetFolder#/processed/</cfoutput>). It will also attempt to split files of over 1,000 records 
			into multiple files to match the Route 53 requirement. Aliases are detected and placed in their own file, but will require manually editing to match AWS Route 53 requirements for Alias migrations.</h3>
	<cfoutput> 
		<cfsilent>
			<cfdirectory directory="#rawDir#" action="list" name="rawFiles" /><!--- // Read Directory files as Query // --->
			<cfdirectory directory="#proDir#" action="list" name="procFiles" /><!--- // Read Directory files as Query // --->
		</cfsilent>
		<p>There are currently <strong>#rawFiles.RecordCount# files</strong> in the raw folder.</p>
		<p>
			<span id="procMsg">
				There are currently <strong>#procFiles.RecordCount# files</strong> in the processed folder.
				<ul><li><strong>Note:</strong> Files will be overwritten when raw files are processed.</li></ul>
			</span>
		</p>
		<form method="post" action="#cgi.script_name#" name="main" id="main">
		<p class="buttons"><input type="submit" name="Submit" value="Process Raw Files"> &nbsp; <input type="button" name="Validate" value="Validate Processed Files" onclick="runVal();" ><!--- <input type="button" value="Clear" onclick="clearForm(document.getElementById('main'));"> ---></p>
		</form>
		<cfif structKeyExists(form, "Submit") and rawFiles.RecordCount gt 0 >
		<table>
			<thead>
				<tr>
					<th>Raw Filename</th>
					<th>Records</th>
					<th>Processed Filename(s)</th>
				</tr>
			</thead>
			<tbody>
		<cfset procCnt = 0 />
		<cfloop query="rawFiles">
			<!--- // Loop over File list // --->
			<cffile action="read" file="#rawFiles.directory#/#rawFiles.name#" variable="rawRead" /><!--- // Read File // --->
			<cfif isJSON(rawRead) >
			<cftry>
				<cfset desJSON = deserializeJSON(rawRead) /><!--- // JSON to CF Data Object // --->
				<cfset changeArray = ArrayNew(2) /><!--- // New Array for Records // --->
				<cfset changeAliasArray = ArrayNew(2) /><!--- // New Array for AliasRecords // --->

				<cfloop index="rI" from="1" to="#ArrayLen(desJSON.ResourceRecordSets)#">
					<!--- // Loop through Resource Record Sets // --->
					<cfif not ListFind("NS,SOA", desJSON.ResourceRecordSets[rI].Type) >
						<!--- // Ignore NS and SOA Records per AWS Documentation // --->
						<cfset recStruct = StructNew("ordered") /><!--- // Create New CF Structure for New ResourceRecordSet parent // --->
						<cfset recStruct = [ "Action": "CREATE", "ResourceRecordSet": desJSON.ResourceRecordSets[rI] ] /><!--- // Add new ResourceRecordSet parent and add Record Children per AWS Documentation // --->
						<cfset per1K = Trim(NumberFormat(rI / 1000,"99999")) + 1 /><!--- // Determine number of Records and Split into 1,000 each // --->
						
						<cfif StructKeyExists(desJSON.ResourceRecordSets[rI], "AliasTarget") >
							<cfset tmp = arrayAppend(changeAliasArray[ArrayLen(changeAliasArray)+1], recStruct) /><!--- // Append this record to Change Alias Array (Dimension 1 = File per 1k / Dimension 2 = Records per 1k) // --->
						<cfelse>
							<cfset tmp = arrayAppend(changeArray[per1k], recStruct) /><!--- // Append this record to Change Array (Dimension 1 = File per 1k / Dimension 2 = Records per 1k) // --->
						</cfif>
					</cfif>
				</cfloop>
				<cfset newFileName = ArrayNew() /><!--- // Set new Array for Filenames // --->
				<cfset passCNT = 0 />
				<cfloop index="wI" from="1" to="#ArrayLen(changeArray)#">
					<!--- // Loop over Change Array Dimension 1 // --->
					<cfset procStruct = StructNew("ordered") /><!--- // Create New CF Structure for Processed JSON // --->
					<cfset procStruct = [ "Comment": rawFiles.name, "Changes": changeArray[wI] ] /><!--- // Add new Head to JSON Document per AWS Documentation // --->
					<cfset tmp = arrayAppend(newFileName, Replace(rawFiles.name, ".txt", ".processed-" & NumberFormat(wI,"00000") & ".json")) /><!--- // Determine Filename for Record Set // --->
					<cffile action="write" file="#proDir##newFileName[wI]#" output="#serializeJSON(procStruct)#" addnewline="false" /><!--- // Save File // --->
					<cfset passCNT = wI />
				</cfloop>
				<cfif ArrayLen(changeAliasArray) >
					<cfloop index="wI2" from="1" to="#ArrayLen(changeAliasArray)#">
						<!--- // Loop over Change Array Dimension 1 // --->
						<cfset procStruct = StructNew("ordered") /><!--- // Create New CF Structure for Processed JSON // --->
						<cfset procStruct = [ "Comment": rawFiles.name, "Changes": changeAliasArray[wI2] ] /><!--- // Add new Head to JSON Document per AWS Documentation // --->
						<cfset tmp = arrayAppend(newFileName, Replace(rawFiles.name, ".txt", ".processed-aliases-" & NumberFormat(passCNT+wI2,"00000") & ".json")) /><!--- // Determine Filename for Record Set // --->
						<cffile action="write" file="#proDir##newFileName[passCNT+wI2]#" output="#serializeJSON(procStruct)#" addnewline="false" /><!--- // Save File // --->
					</cfloop>
				</cfif>


				<cfset procCnt += ArrayLen(newFileName) /><!--- // Vanity Count of Files Processed // --->
				<tr class="green">
					<td>#rawFiles.name#</td>
					<td>#ArrayLen(desJSON.ResourceRecordSets)#</td>
					<td>
						<cfloop index="fI" from="1" to="#ArrayLen(newFileName)#">
							#newFileName[fI]#<br>
						</cfloop>
					</td>
				</tr>
				<cfcatch type="any">
					<tr class="red">
						<td>#rawFiles.name#</td>
						<td>0</td>
						<td><strong>ERROR: Unable to process file. (#cfcatch.message#)</strong></td>
					</tr>
				</cfcatch>
			</cftry>
			<cfelse>
				<tr class="red">
					<td>#rawFiles.name#</td>
					<td>0</td>
					<td><strong>ERROR: No JSON detected in File.</strong></td>
				</tr>
			</cfif>
		</cfloop>
			</tbody>
		</table>
		<script>
			thisCnt = '#procCnt#';
			if (thisCnt > 0) {
				document.getElementById('procMsg').innerHTML = "<strong>" + thisCnt + " files</strong> where created in the processed folder.";
			}
		</script>
		<br/><br/>
		<cfelseif structKeyExists(form, "Submit") and rawFiles.RecordCount eq 0 >
			<p class="red center bold message">There are no files to process.</p>
		<cfelseif structKeyExists(url, "goValidate") and procFiles.RecordCount gt 0 >
			<!--- // Validate Record Count and JSON in Processed Files // --->
			<table>
				<thead>
					<tr>
						<th>Processed Filename</th>
						<th>Records</th>
						<th>Valid JSON</th>
					</tr>
				</thead>
				<tbody>
				<cfloop query="procFiles">
				<!--- // Loop over File list // --->
				<cffile action="read" file="#procFiles.directory#/#procFiles.name#" variable="procRead" /><!--- // Read File // --->
				<cfif isJSON(procRead) >
				<cftry>
					<cfset desJSON = deserializeJSON(procRead) /><!--- // JSON to CF Data Object // --->
					<tr class="green">
						<td>#procFiles.name#</td>
						<td>#ArrayLen(desJSON.Changes)#</td>
						<td class="center">YES</td>
					</tr>
					<cfcatch type="any">
						<tr class="red">
							<td>#procFiles.name#</td>
							<td>0</td>
							<td><strong>ERROR: Unable to read file. (#cfcatch.message#)</strong></td>
						</tr>
					</cfcatch>
				</cftry>
				<cfelse>
					<tr class="red">
						<td>#procFiles.name#</td>
						<td>0</td>
						<td><strong>NO</strong></td>
					</tr>
				</cfif>
			</cfloop>
				</tbody>
			</table>
		<cfelseif structKeyExists(url, "goValidate") and procFiles.RecordCount eq 0 >
			<p class="red center bold message">There are no files to validate.</p>
		</cfif>	
	</cfoutput> 
	</body> 
</html>
