<!---
	Copyright 2013+ Brian Ghidinelli (http://www.ghidinelli.com/)

	Licensed under the Apache License, Version 2.0 (the "License"); you
	may not use this file except in compliance with the License. You may
	obtain a copy of the License at:

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
--->
<cfcomponent displayname="Hubspot V3 API Client" output="false">
	
	<cfset variables.instance = StructNew() />
	<cfset variables.instance.portal_id = '' />
	
	<cffunction name="init" output="false" access="public" returntype="any">
		<cfargument name="portal_id" type="string" required="true" />
		<cfargument name="hapikey" type="string" required="true" />
		<cfargument name="RestConsumer" type="any" required="true" />

		<cfset variables.instance.portal_id = arguments.portal_id />
		<cfset variables.instance.hapikey = arguments.hapikey />
		<cfset variables.RestConsumer = arguments.RestConsumer />
		
		<cfset variables.RestConsumer.setDebug(false) />
		<cfset variables.RestConsumer.setRateLimit(1) />

		<cfreturn this />		
	</cffunction>


	<cffunction name="submitForm" access="public" returntype="any" output="false">
		<cfargument name="form_guid" type="string" required="true" />
		<!--- hs_context --->
		<cfargument name="hutk" type="string" required="false" default="" hint="Hubspot UTK cookie value" />
		<cfargument name="pageUrl" type="string" required="false" default="" />
		<cfargument name="pageName" type="string" required="false" default="" />
		<cfargument name="ipAddress" type="string" required="false" default="" />

		<!--- any valid company or msr custom field --->
		<cfargument name="email" type="string" required="true" />
		<cfargument name="firstname" type="string" required="false" default="" />
		<cfargument name="lastname" type="string" required="false" default="" />
		<cfargument name="company" type="string" required="false" default="" />
		<cfargument name="website" type="string" required="false" default="" />
		<cfargument name="phone" type="string" required="false" default="" />
		<cfargument name="address" type="string" required="false" default="" />
		<cfargument name="city" type="string" required="false" default="" />
		<cfargument name="state" type="string" required="false" default="" />
		<cfargument name="zip" type="string" required="false" default="" />
		<cfargument name="country" type="string" required="false" default="" />

		<cfargument name="account_type" type="string" required="false" default="" />
		<cfargument name="existing_service_" type="string" required="false" default="" />
		<cfargument name="hear_about_msr" type="string" required="false" default="" />
		<cfargument name="date_of_next_event" type="string" required="false" default="" />
		<cfargument name="questions_comments" type="string" required="false" default="" />

		<cfset var hs_context = {"hutk": arguments.hutk, "ipAddress": arguments.ipAddress, "pageUrl": arguments.pageUrl, "pageName": arguments.pageName} />
		<cfset var post = duplicate(arguments) />
		<cfset var headers = {"Content-Type": "application/x-www-form-urlencoded"} />

		<cfreturn doRemoteCall(method = "POST", resource = "https://forms.hubspot.com/uploads/form/v2/#getPortalID()#/#arguments.form_guid#", headers = headers, payload = post) />
	</cffunction>
	

	<cffunction name="getForms" output="false" access="public" returntype="any">
		<cfreturn doRemoteCall(method = "GET", resource = "/contacts/v1/forms") />
	</cffunction>


	<cffunction name="findContact" output="false" access="public" returntype="any" hint="">
		<cfargument name="q" type="string" required="true" hint="email or name to search for" />
		<cfargument name="count" type="numeric" required="false" default="20" />
		<cfargument name="offset" type="numeric" required="false" default="0" />
		
		<cfreturn doRemoteCall(method = "GET", resource = "/contacts/v1/search/query", payload = {"q": arguments.q, "count": arguments.count, "offset": arguments.offset}) />
	</cffunction>


	<cffunction name="getContact" output="false" access="public" returntype="any">
		<cfargument name="vid" type="any" required="true" />
		<cfreturn doRemoteCall(method = "GET", resource = "/contacts/v1/contact/vid/#arguments.vid#/profile") />
	</cffunction>


	<!--- PRIVATE METHODS --->
	<cffunction name="doRemoteCall" output="false" access="private" returntype="any">
		<cfargument name="method" type="any" required="true" default="GET" />
		<cfargument name="resource" type="any" required="true" />
		<cfargument name="headers" type="any" required="false" default="#structNew()#" />
		<cfargument name="payload" type="any" required="false" default="#structNew()#" />
	
		<cfset var uri = arguments.resource />
		<cfset var res = "" />
		
		<!--- allow short /resource/style/names to add endpoint but also permit passing in a full URL like for form Submit --->
		<cfif left(uri, 1) EQ "/">
			<cfset uri = "https://api.hubapi.com" & uri />
		</cfif>

		<!--- append the authkey to the URL either directly or to the payload for GET requests --->
		<cfif uCase(arguments.method) EQ "GET" AND isStruct(arguments.payload)>
			<cfset structInsert(arguments.payload, "hapikey", getApiKey(), true) />
		<cfelse>
			<cfif find("?", uri)>
				<cfset uri &= "&hapikey=#getApiKey()#" />
			<cfelse>
				<cfset uri &= "?hapikey=#getApiKey()#" />
			</cfif>
		</cfif>

		<cfset res = variables.restconsumer.process(url = uri, method = arguments.method, payload = arguments.payload, headers = arguments.headers, timeout = 30) />
		
		<cfif res.complete AND (NOT len(trim(res.content)) OR isJSON(res.content))>
			<cfreturn res />
		<cfelse>
			<cfdump var="#res#" output="console" />
			<cfthrow message="Error" detail="The response from #arguments.resource# was not JSON" extendedinfo="#res.content#" />
		</cfif>
		
	</cffunction>


	<!--- Accessor methods --->
	<cffunction name="getPortalID" output="false" access="private" returntype="any">
		<cfreturn variables.instance.portal_id />
	</cffunction>

	<cffunction name="getApiKey" output="false" access="private" returntype="any">
		<cfreturn variables.instance.hapikey />
	</cffunction>
	

</cfcomponent>