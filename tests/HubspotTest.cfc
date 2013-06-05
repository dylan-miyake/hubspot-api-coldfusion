<cfcomponent extends="mxunit.framework.TestCase">
	
	<cffunction name="setup">
		<cfset var beanConfigs = "" />

		<cfsavecontent variable="beanConfigs">
			<beans>
				<bean id="HubspotService" class="path.to.hubspot">
			        <constructor-arg name="portal_id"><value>{your_portal_id}</value></constructor-arg>
			        <constructor-arg name="hapikey"><value>{your_api_key}</value></constructor-arg>
					<constructor-arg name="restconsumer"><ref bean="restconsumer" /></constructor-arg>
				</bean>
				<bean id="RestConsumer" class="path.to.restconsumer" />
			</beans>
		</cfsavecontent>

		<cfscript>
			variables.beanFactory = createObject("component", "coldspring.beans.DefaultXmlBeanFactory").init();
			variables.beanFactory.loadBeansFromXmlRaw(beanConfigs, true);

			variables.hs = variables.beanFactory.getBean("HubspotService");
		</cfscript>

		<!--- if set to false, will try to connect to remote service to check these all out --->
		<cfset localMode = false />

	</cffunction>


	<cffunction name="offlineInjector" access="private" hint="conditionally injects a mock if we are running tests in offline mode vs. integration mode">
		<cfif localMode>
			<cfset makePublic(arguments[1], arguments[4]) />
			<cfset injectMethod(argumentCollection = arguments) />
		</cfif>
		<!--- if not local mode, don't do any mock substitution so the service connects to the remote service! --->
	</cffunction>


	<cffunction name="testCreateContact" access="public" output="false" returntype="void">
		
		<cfset var args = {"form_guid": "your-form-guid"
							,"email": "joe@blow.com"
							,"firstname": "Joe"
							,"lastname": "Blow"
							,"club_organization": "Test Org #randRange(1000,9999)#" } />

		<cfset var res = hs.submitForm(argumentCollection = args) />
		
		<cfset debug(res) />
		<cfset assertTrue(res.complete, "Should have successfully completed (no errors were thrown, http completed OK (but not necessarily 200 OK)") />
		<cfset assertTrue(res.status EQ 204, "Should have returned empty response and been 204 Created") />
	
	</cffunction>


	<cffunction name="testCreateLeadFromSignupForm" access="public" output="false" returntype="void">
		
		<cfset var r = randRange(1000,9999) />
		<cfset var res = "" />
		<cfset var args = {"form_guid": "your-form-guid"
							,"pageUrl": "http://www.yourpage.com/signup"
							,"pageName": "Signup Page"
							,"ipAddress": CGI.remote_addr
							,"email": "joe@blow#r#.com"
							,"firstname": "Joe"
							,"lastname": "Blow"
							,"company": "Test #r#"
							,"phone": "415.555.1212"
							,"address": "#r# Anywhere Lane"
							,"city": "San Francisco"
							,"state": "CA"
							,"zip": "94107"
							,"country": "US"
							,"website": "http://www.myorg#r#.com"
							} />

		<cfif structKeyExists(cookie, "hubspotutk")>
			<cfset args["hubspotutk"] = cookie.hubspotutk />
		</cfif>
		
		<cfset res = hs.submitForm(argumentCollection = args) />
		
		<cfset debug(res) />
		<cfset assertTrue(res.complete, "Should have successfully completed (no errors were thrown, http completed OK (but not necessarily 200 OK) for joe@blow#r#.com") />
		<!--- note if the hs_context is not passed, it returns 302 with a location to the "thank you" page --->
		<cfset assertTrue(res.status EQ 204, "Should have returned empty response and 204, didn't for joe@blow#r#.com") />

	
	</cffunction>


	<cffunction name="testGetForms" access="public" output="false" returntype="void">
		
		<cfset var res = hs.getForms() />
		
		<cfset debug(res) />
		<cfset assertTrue(res.complete, "Should have successfully completed (no errors were thrown, http completed OK (but not necessarily 200 OK)") />
		<cfset assertTrue(res.status EQ 200 AND isJSON(res.content), "Should have returned json response and been 200 OK") />
	
	</cffunction>


	<cffunction name="testFindContact" access="public" output="false" returntype="void">
		
		<cfset var res = hs.findContact(q = "blow") />
		<cfset debug(res) />
		<cfset assertTrue(res.complete, "Should have completed successfully") />
	
	</cffunction>


	<cffunction name="testGetContact" access="public" output="false" returntype="void">

		<!--- this vid was deleted from a test account, NLA --->		
		<cfset var res = hs.getContact('enter-a-vid-here-from-your-contact') />
		<cfset debug(res) />
		<cfset assertTrue(res.complete, "Should have completed successfully") />
		<cfset assertTrue(res.status EQ 200 AND isJSON(res.content), "Should have returned json response and been 200 OK") />
	
	</cffunction>



	<!--- mocks! --->
	<cffunction name="serviceIsDownMock" access="private">
		<cfset var cfhttp = { filecontent = "connection failure", statuscode = "Connection Failure. Status code unavailable.", errordetail = "FailWhale!" } />
		<cfreturn cfhttp />
	</cffunction>

</cfcomponent>