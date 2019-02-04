<cfinclude template="env.cfm">
<cfset rawDir = ExpandPath(assetFolder & "/raw/") />
<html>
	<head>
		<title>Dig Dug DNS Comparison Tool</title>
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
			function fileExpand() {
				var x = document.getElementById("dirList");
				if (x.style.display === "none") {
					x.style.display = "block";
				} else {
					x.style.display = "none";
				}
			}
			function checkThis(i) {
				document.getElementById("prcFile" + i).checked = true;
			}
		</script>
	</head>
<body id="digDug">
	<div id="backlink"><a href="/">Back to App List</a></div>
	<h1>Dig Dug DNS Comparison Tool</h1>
	<h3>If files (AWS Route 53 Export) are in the raw folder (<cfoutput>/#assetFolder#/raw/</cfoutput>) there will be an option to use a local file rather than 
		the Look up Domains field. Name Server fields must still be provided.</h3>
<cfoutput>
<cfsilent>
	<cfset valDomains = "" />
	<cfif structKeyExists(form, "prcFile") >
		<cftry>
			<cffile action="read" file="#rawDir#/#Replace(form.prcFile,"/","_","all")#" variable="rawRead" />
			<cfif isJSON(rawRead) >
				<cfset desJSON = deserializeJSON(rawRead) /><!--- // JSON to CF Data Object // --->
				<cfset fileDomains = ArrayNew() /><!--- // New Array for Records // --->
				<cfloop index="rI" from="1" to="#ArrayLen(desJSON.ResourceRecordSets)#">
					<!--- // Loop through Resource Record Sets // --->
					<cfif not ListFind("NS,SOA", desJSON.ResourceRecordSets[rI].Type) and not StructKeyExists(desJSON.ResourceRecordSets[rI], "AliasTarget") and not ArrayFind(fileDomains,desJSON.ResourceRecordSets[rI].name) >
						<cfset tmp = arrayAppend(fileDomains,desJSON.ResourceRecordSets[rI].name) />
					</cfif>
				</cfloop>
				<cfset valDomains = arrayToList(fileDomains,Chr(10)) />
			</cfif>
			<cfcatch type="any"><cfset fileDomains = ArrayNew() /></cfcatch>
		</cftry>
	<cfelseif structKeyExists(form, "domains") >
		<cfset valDomains = form.domains />
	</cfif>
</cfsilent>
	<form method="post" action="#cgi.script_name#" name="main" id="main">
		<div class="panel">
			<label for="domains">Look up Domains</label>
			<textarea name="domains" rows="10">#valDomains#</textarea>
			<div class="checkboxes">
				<input name="raw" type="checkbox" #iif(structKeyExists(form, "raw"), de("CHECKED"), de(""))# >
				<label for="raw">Raw Output Only</label>
				<br>
				<input name="reverse" type="checkbox" #iif(structKeyExists(form, "reverse"), de("CHECKED"), de(""))# >
				<label for="reverse">Reverse DNS</label>
			</div>	
		</div>
		<div class="panel">
			<label for="nameservers">Name Servers</label>
			<textarea name="nameservers" rows="10">#iif(structKeyExists(form, "nameservers"),"form.nameservers",de(""))#</textarea>

			<label for="sourcens">Source Name Server</label>
			<input name="sourcens" type="text" value="#iif(structKeyExists(form, "sourcens"),"form.sourcens",de(""))#">
		</div>
		<br style="clear: both;">
		<cfdirectory directory="#rawDir#" action="list" name="rawFiles" /><!--- // Read Directory files as Query // --->
		<cfif rawFiles.RecordCount >
		<br/>
		<label style="margin-left: .5em;"><a href="javascript:fileExpand();">Raw Files (click to open/close)</a></label>
		<cfif structKeyExists(form, "prcFile") >
		<div class="accord" style="display: block;"><ul><li><input type="radio" name="prcFile" id="prcFile0" value="#form.prcFile#" checked > <label for="prcFile"><a href="javascript:checkThis('0');">#form.prcFile#</a> (clear form or select to new file to unset)</li></ul></div>
		</cfif>
		<div id="dirList" class="accord ul2col" style="display: none;">
			<ul>
				<cfloop query="rawFiles">
					<li><input type="radio" name="prcFile" id="prcFile#rawFiles.CurrentRow#" value="#rawFiles.name#"> <label for="prcFile"><a href="javascript:checkThis('#rawFiles.CurrentRow#');">#rawFiles.name#</a></label></li>
				</cfloop>				
			</ul>
		</div>
		</cfif>
		<p class="buttons"><input type="submit" name="Submit"> <input type="button" value="Clear" onclick="clearForm(document.getElementById('main'));"></p>
	</form>
</cfoutput>

<cfif structKeyExists(form, "Submit")  >
	<cfsilent>
		<cfset rawArray = ArrayNew(2) />
		<cfset testSpace = ArrayNew() />
		<cfset exeErr = "" />
		<cfset exeName = "/usr/bin/dig" />
		<cfset rtnQry = queryNew("ID,Domain,NS,Entry,TTL,IN,Type,Addr,Source") />

		<cfset theseNS = listToArray(form.nameservers, Chr(10)) />
		<cfset nsCompare = form.sourcens />
		<cfset preArgFwd1 = "any +noall +answer">
		<cfset preArgRev1 = "+noall +answer -x">
		<cfset preArgRev2 = "+noall +answer ptr">

		<cfif structKeyExists(form, "prcFile") >
			<cfset prcFileError = true />
			<cftry>
				<cfset theseDomains = fileDomains />
				<cfset prcFileError = false />

				<cfcatch type="any"><cfset prcFileError = true /></cfcatch>
			</cftry>		
		<cfelse>
			<cfset prcFileError = false />
			<cfset theseDomains = listToArray(form.domains, Chr(10)) />
		</cfif>

		<cfif not prcFileError >
			<cfloop index="dI" from="1" to="#ArrayLen(theseDomains)#">
				
				<cfset thisDOM = theseDomains[di] />
				<cfif structKeyExists(form, "reverse") and Find("in-addr.arpa",thisDOM) >
					<!--- // If Reverse PTR Entry (1.0.0.10.in-addr.arpa) // --->
					<cfset preArg = preArgRev2 />
					<cfset thisArg = " @#nsCompare# #thisDOM#" />
				<cfelseif structKeyExists(form, "reverse") and ListLen(thisDOM,".") eq 4 >
					<!--- // If Reverse is IP Address (10.0.0.1) // --->
					<cfset preArg = preArgRev1 />
					<cfset thisArg = " #thisDOM# @#nsCompare#" />
				<cfelse>
					<!--- // Else Forward IP Regardless of Flag // --->
					<cfset preArg = preArgFwd1 />
					<cfset thisArg = " @#nsCompare# #thisDOM#" />
				</cfif>
				<cfset exeArg = preArg & thisArg />
				<cfexecute variable="digsource" name="#exeName#" arguments="#exeArg#" errorVariable="exeErr" timeout="30"/>
				<cfset rawArray[ArrayLen(rawArray)+1][1] = "#thisDOM# @#nsCompare#" />
				<cfset rawArray[ArrayLen(rawArray)][2] = digsource />

				<!--- // Add Domain NS Compare Entries // --->
				<cfset digsourceArray = listToArray(digsource, Chr(10)) />
				<cfloop index="i" from="1" to="#ArrayLen(digsourceArray)#">
					<cfset attrSource = listToArray(digsourceArray[i], Chr(9)) />
					<cfif ArrayLen(attrSource) lt 5 >
						<cfset tempSource = Replace(digsourceArray[i], Chr(9), " ", "all") />
						<cfset attrSource = ArrayNew() />
						<cfif ListLen(tempSource," ") gte 5 >
							<cfset attrSource[1] = listGetAt(tempSource,1," ") />
							<cfset attrSource[2] = listGetAt(tempSource,2," ") />
							<cfset attrSource[3] = listGetAt(tempSource,3," ") />
							<cfset attrSource[4] = listGetAt(tempSource,4," ") />
							<cfset lastSTR = Right(tempSource, Len(tempSource) - FindNoCase(ListGetAt(tempSource, 5, " "), tempSource) + 1) />
							<cfset attrSource[5] = lastSTR />
						</cfif>
					</cfif>
					<cfif ArrayLen(attrSource) eq 5 >
							<cfset thisRow = rtnQry.RecordCount + 1 />
							<cfset thisStruct = StructNew() />
							<cfset thisStruct = { ID = thisRow, Domain = thisDOM,NS = nsCompare, Entry = attrSource[1], TTL = attrSource[2], IN = attrSource[3], Type = attrSource[4], Addr = attrSource[5], Source = "1"} />
							<cfset QueryAddRow(rtnQry,thisStruct) />
						</cfif>
				</cfloop>

				<!--- // Add Domain NS Lookup Entries // --->
				<cfloop index="nsI" from="1" to="#ArrayLen(theseNS)#">
					<cfif structKeyExists(form, "reverse") and Find("in-addr.arpa",thisDOM) >
						<!--- // If Reverse PTR Entry (1.0.0.10.in-addr.arpa) // --->
						<cfset preArg = preArgRev2 />
						<cfset thisArg = " @#theseNS[nsI]# #thisDOM#" />
					<cfelseif structKeyExists(form, "reverse") and ListLen(thisDOM,".") eq 4 >
						<!--- // If Reverse is IP Address (10.0.0.1) // --->
						<cfset preArg = preArgRev1 />
						<cfset thisArg = " #thisDOM# @#theseNS[nsI]#" />
					<cfelse>
						<!--- // Else Forward IP Regardless of Flag // --->
						<cfset preArg = preArgFwd1 />
						<cfset thisArg = " @#theseNS[nsI]# #thisDOM#" />
					</cfif>
					<cfset exeArg = preArg & thisArg />
					<cftry>
						<cfexecute variable="digdug" name="#exeName#" arguments="#exeArg#" errorVariable="exeErr" timeout="30"/>
						<cfset rawArray[ArrayLen(rawArray)+1][1] = "#thisDOM# @#theseNS[nsI]#" />
						<cfset rawArray[ArrayLen(rawArray)][2] = digdug />

						<cfset digdugArray = listToArray(digdug, Chr(10)) />
						<cfloop index="i" from="1" to="#ArrayLen(digdugArray)#">
							<cfset attr = listToArray(digdugArray[i], Chr(9)) />
							<cfif ArrayLen(attr) lt 5 >
								<cfset tempAttr = Replace(digdugArray[i], Chr(9), " ", "all") />
								<cfset attr = ArrayNew() />
								<cfif ListLen(tempAttr," ") gte 5 >
									<cfset attr[1] = listGetAt(tempAttr,1," ") />
									<cfset attr[2] = listGetAt(tempAttr,2," ") />
									<cfset attr[3] = listGetAt(tempAttr,3," ") />
									<cfset attr[4] = listGetAt(tempAttr,4," ") />
									<cfset lastSTR = Right(tempAttr, Len(tempAttr) - FindNoCase(ListGetAt(tempAttr, 5, " "), tempAttr) + 1) />
									<cfset attr[5] = lastSTR />
								</cfif>
							</cfif>
							<cfif ArrayLen(attr) eq 5 >
								<cfset thisRow = rtnQry.RecordCount + 1 />
								<cfset thisStruct = StructNew() />
								<cfset thisStruct = { ID = thisRow, Domain = thisDOM,NS = theseNS[nsI], Entry = attr[1], TTL = attr[2], IN = attr[3], Type = attr[4], Addr = attr[5], Source = "0" } />
								<cfset QueryAddRow(rtnQry,thisStruct) />
							</cfif>
						</cfloop>
						<cfcatch type="any">
							<cfset thisRow = rtnQry.RecordCount + 1 />
							<cfset thisStruct = StructNew() />
							<cfset thisStruct = { ID = thisRow, Domain = "Error - #cfcatch.message#",NS = "", Entry = "", TTL = "", IN = "", Type = "", Addr = "", Source = "0" } />
							<cfset QueryAddRow(rtnQry,thisStruct) />
						</cfcatch>
					</cftry>
				</cfloop>

			</cfloop>
			<cfquery name="nsC" dbtype="query">
				select * from rtnQry 
				where ns = '#nsCompare#'
				order by Domain, Type
			</cfquery>
		<cfelse>
			<cfset nsC = rtnQry />
		</cfif>
	</cfsilent>

	<cfoutput>
	<div id="results">
	<cfif not structKeyExists(form, "raw") >
		<table>
			<thead>
			<tr>
				<th>Name Server</th>
				<th>Type</th>
				<th>Entry</th>
				<th>Address</th>
			</tr>
			</thead>
			<tbody>
		<cfset loopDOM = "" />
		<cfloop query="nsC">
			<cfif loopDOM neq nsC.Domain >
				<cfset loopDOM = nsC.Domain />
				<tr class="domain">
					<td colspan="4">#loopDOM#</td>
				</tr>
			</cfif>
			<cfquery name="matches" dbtype="query">
				select * 
				from rtnQry
				where rtnQry.Domain = '#nsC.Domain#'
				and rtnQry.Entry = '#nsC.Entry#'
				and rtnQry.Type = '#nsC.Type#' 
				and rtnQry.Addr = '#nsC.Addr#'
				and rtnQry.NS != '#nsCompare#'
				order by Domain, Type
			</cfquery>

			<cfif matches.recordCount gt 0 >
				<tr class="source">
					<td>#nsC.NS#</td>
					<td>#nsC.Type#</td>
					<td>#nsC.Entry#</td>
					<td><div>#nsC.Addr#</div></td>
				</tr>
				<cfloop query="matches">
					<tr class="green">
						<td>#matches.NS#</td>
						<td>#matches.Type#</td>
						<td>#matches.Entry#</td>
						<td><div>#matches.Addr#</div></td>
					</tr>
				</cfloop>
			<cfelse>
				<tr class="red source">
					<td>#nsC.NS#</td>
					<td>#nsC.Type#</td>
					<td>#nsC.Entry#</td>
					<td><div>#nsC.Addr#</div></td>
				</tr>
			</cfif>
		</cfloop>
			</tbody>
		</table>
	</cfif>

	<cfif ArrayLen(rawArray) >
		<cfloop index="rI" from="1" to="#ArrayLen(rawArray)#">
<hr>
<h2>#rawArray[rI][1]#</h2>
<pre>#rawArray[rI][2]#</pre>
		</cfloop>
	
	
	</cfif>


<!---
		<cfdump var="#nsC#" >
		<cfdump var="#rtnQry#" >
		<cfdump var="#rawArray#" >
--->	
	</div>
	</cfoutput>
	
</cfif>

</body>
</html>