<cfinclude template="env.cfm">
<cfset baseDomain = "test.com" />
<cfset baseNS = "ns.test.com." />
<html><head><title>DB Parse</title>
	<link rel="stylesheet" href="general.css">
</head>
<body id="dbParse"> 
	<div id="backlink"><a href="/">Back to App List</a></div>
<cffile action="read" file="#ExpandPath(assetFolder & "/bind.db.txt")#" variable="bind">

<cfoutput>
<cfloop index="i" from="1" to="#ListLen(bind, Chr(10))#">
<cfset thisRow = ListGetAt(ListGetAt(bind, i, Chr(10)), 1, " ") />
<cfif not isNumeric(Replace(thisRow, ".", "","all")) and not FindNoCase(thisRow, "@") and not FindNoCase(thisRow, "$TTL") and not FindNoCase(thisRow,baseNS) >
	#thisRow#.#baseDomain#<br>
</cfif>
</cfloop>
</cfoutput>

</body></html>