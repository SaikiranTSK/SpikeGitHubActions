<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" indent="yes"/>
<xsl:template match="/">
  <html>
    <head>
      <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css"/>
      <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css"/>
      <link rel="stylesheet" href="styles.css" />
    </head>
    <body>
      <div class="container-fluid">
        <div class="row">
          <div class="col-lg-8 col-md-8 left" id="left_div">
            <div>
              <h3>Results </h3>
            </div>
            <container>
              <p>
                <input type="button" value="Filter: None" class="btn btn-info" id="ShowAll"/>
                <input type="button" value="Filter: failures" class="btn btn-danger" id="ShowOnlyFailures"/>
                <input type="button" value="Expand failures" class="btn btn-danger" id="OpenAllFailures"/>
              </p>
            </container>
            <div class="list-group list-group-root well">
              <xsl:apply-templates select="//test-suite[@type='TestFixture']"/>
            </div>
          </div>
          <div class="col-lg-4 col-md-4 right">
            <div>
              <h3>List of failures</h3>
            </div>
            <!--apply template on the test suite[testfixture]-->
            <xsl:apply-templates mode="Build-Test-Failures" select="//test-suite[@type='TestFixture' and @result='Failure']"/>
          </div>
        </div>
      </div>
      <!-- jQuery first, then Popper.js, then Bootstrap JS -->
      <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"><xsl:value-of select="' '"/></script>
      <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"><xsl:value-of select="' '"/></script>
    <!-- My own scripts -->
      <script src="javascript\ChangeGlyphicons.js"><xsl:value-of select="' '"/></script>
    </body>
  </html>
</xsl:template>


  <!--xsl:template match="/test-run/">
      <xsl:apply-templates select="/test-suite[@type='TestFixture']"/>
  </xsl:template-->


  <!--Test Suite template-->
  <xsl:template match="test-suite">

      <!-- Generate variable names -->
      <xsl:variable name="Fullname">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="@name"/>
          <xsl:with-param name="replace" select="'.'"/>
          <xsl:with-param name="by" select="'_'"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="FeatureID" select="concat($Fullname,'_Href')"/>
      <xsl:variable name="FullNameWithoutFeature">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="@name"/>
          <xsl:with-param name="replace" select="'Feature'"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <!--xsl:variable name="featureName">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="@name"/>
          <xsl:with-param name="replace" select="Feature"/>
          <xsl:with-param name="by" select="'sss'"/>
        </xsl:call-template>
      </xsl:variable-->
      <xsl:variable name="ScenarioFailures" select="count(.//test-case[@result='Failure'])"/>
      <xsl:variable name="ScenarioErrors" select="count(.//test-case[@result='Error'])"/>
      <xsl:variable name="ScenarioSkipped" select="count(.//test-case[@result='Ignored'])"/>
      <xsl:variable name="ScenarioNotRun" select="count(.//test-case[@result='NotRunnable'])"/>
      <xsl:variable name="FullnameLink" select="concat('#',$Fullname)"/>
      <xsl:variable name="TestStatus" select="@result"/>
      <xsl:variable name="LinkClassName" select="concat('list-group-item list-group-item-action collapsed ',$TestStatus)"/>
      <xsl:variable name="icon">
        <xsl:choose>
          <xsl:when test="((@result = 'Success') and (@executed = 'True') and (@success = 'True'))">
            <xsl:value-of select="concat('glyphicon ','glyphicon-plus ','text-success')"/>
          </xsl:when>
          <xsl:when test="@result = 'Failure'">
            <xsl:value-of select="concat('glyphicon ','glyphicon-plus ','text-danger')"/>
          </xsl:when>          
          <xsl:otherwise>
            <xsl:value-of select="concat('glyphicon ','glyphicon-plus ','text-warning')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable> 
      <xsl:variable name="divClassName" select="concat('list-group collapse ',$TestStatus)"/>
      <!--Insert Href here-->
      <a href="{$FullnameLink}" class="{$LinkClassName}" data-toggle="collapse" id="{$FeatureID}" style="background-color:#ffffff">
        <div>
          <i class="{$icon}"><xsl:value-of select="' '"/></i>
          <span class="insight-label"><b>Feature: <xsl:value-of select="$FullNameWithoutFeature"/></b></span>

        <xsl:if test="$ScenarioFailures > 0">
          <span class="label label-danger">Fail: <xsl:value-of select="$ScenarioFailures"/></span>
        </xsl:if>
        <xsl:if test="$ScenarioErrors > 0" >
          <span class="label label-warning">Error: <xsl:value-of select="$ScenarioErrors"/>
          </span>
        </xsl:if>
        <xsl:if test="$ScenarioSkipped > 0">
          <span class="label label-info">Inconclusive: <xsl:value-of select="$ScenarioSkipped"/></span>
        </xsl:if>
        <xsl:if test="$ScenarioNotRun > 0">
          <span class="label label-default">Not run: <xsl:value-of select="$ScenarioNotRun"/></span>
        </xsl:if>
        </div>
      </a>
      <div class="{$divClassName}" id="{$Fullname}">
        <xsl:for-each select=".//test-case">
          <xsl:sort select="./properties/property[@name='DocumentationOrder']/@value"/>
          <xsl:apply-templates select="."/>
        </xsl:for-each>
      </div>
  </xsl:template>

  <xsl:template match="test-case">
   <!-- Generate variable names -->

      <xsl:variable name="ScenarioID">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="@name"/>
          <xsl:with-param name="replace" select="'.'"/>
          <xsl:with-param name="by" select="'_'"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutNull">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="$ScenarioID"/>
          <xsl:with-param name="replace" select="',null'"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutSystemStringorNull">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="$ScenarioNameWithoutNull"/>
          <xsl:with-param name="replace" select="',System_String[]'"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutSystemStringorNullorbracket">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="$ScenarioNameWithoutSystemStringorNull"/>
          <xsl:with-param name="replace" select="'('"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutSystemStringorNullorbrackets">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="$ScenarioNameWithoutSystemStringorNullorbracket"/>
          <xsl:with-param name="replace" select="')'"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutSystemStringorNullorbracketsorQuotes">
        <xsl:value-of select="translate($ScenarioNameWithoutSystemStringorNullorbrackets, '\&quot;', '&#8217;')"/>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutSystemStringorNullorbracketsorQuotesorCommas">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="$ScenarioNameWithoutSystemStringorNullorbracketsorQuotes"/>
          <xsl:with-param name="replace" select="','"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutFeature">
        <xsl:call-template name="substring-after-last">
          <xsl:with-param name="string" select="$ScenarioNameWithoutSystemStringorNull"/>
          <xsl:with-param name="delimiter" select="'Feature_'"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutPreloop">
        <xsl:call-template name="substring-after-last">
          <xsl:with-param name="string" select="$ScenarioNameWithoutFeature"/>
          <xsl:with-param name="delimiter" select="'PreLoop_'"/>
        </xsl:call-template>
      </xsl:variable>
    <xsl:variable name="ScenarioNameWithoutPreloopAcquisition">
      <xsl:call-template name="substring-after-last">
        <xsl:with-param name="string" select="$ScenarioNameWithoutPreloop"/>
        <xsl:with-param name="delimiter" select="'PreLoopAcquisition_'"/>
      </xsl:call-template>
    </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutAnyInfo">
        <xsl:call-template name="substring-after-last">
          <xsl:with-param name="string" select="$ScenarioNameWithoutPreloopAcquisition"/>
          <xsl:with-param name="delimiter" select="'PostLoop_'"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="LinkID" select="concat('#',$ScenarioNameWithoutSystemStringorNullorbracketsorQuotesorCommas)"/>
      <xsl:variable name="ScenarioLoggingLink" select="concat($LinkID,'_Logging')"/>
      <xsl:variable name="ScenariologgingID" select="concat($ScenarioNameWithoutSystemStringorNullorbracketsorQuotesorCommas,'_Logging')"/>
      <xsl:variable name="TestStatus" select="@result"/>
      <xsl:variable name="FullClassName" select="concat('list-group-item list-group-item-action collapsed ',$TestStatus)"/>
      <xsl:variable name="divClassName" select="concat('list-group ','collapse')"/>
      <xsl:variable name="icon">
        <xsl:choose>
          <xsl:when test="@result = 'Success'">
            <xsl:value-of select="concat('glyphicon ','glyphicon-ok-circle ','text-success')"/>
          </xsl:when>
          <xsl:when test="@result = 'Failure'">
            <xsl:value-of select="concat('glyphicon ','glyphicon-remove-circle ','text-danger')"/>
          </xsl:when>
          <xsl:when test="@result= 'Error'">
            <xsl:value-of select="concat('glyphicon ','glyphicon-remove-circle ','text-warning')"/>
          </xsl:when>
          <xsl:when test="@result = 'Ignored'">
            <xsl:value-of select="concat('glyphicon ','glyphicon-remove-circle ','text-dark')"/>
          </xsl:when>
          <xsl:when test="@result = 'Inconclusive'">
            <xsl:value-of select="concat('glyphicon ','glyphicon-remove-circle ','text-dark')"/>
          </xsl:when>
          <xsl:when test="@result ='NotRunnable'">
            <xsl:value-of select="concat('glyphicon ','glyphicon-ban-circle ','text-warning')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('glyphicon ','glyphicon-remove-circle ','text-warning')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <!--Insert Href here-->
      <a href="{$ScenarioLoggingLink}" class="{$FullClassName}" data-toggle="collapse" id="{$ScenarioNameWithoutSystemStringorNullorbracketsorQuotesorCommas}">
        <div>
          <i class="{$icon}"><xsl:value-of select="' '"/></i>
          <span>
            <b>Scenario: </b>
            <xsl:value-of select="concat('',$ScenarioNameWithoutAnyInfo)"/>
          </span>
        </div>
      </a>
      <div class="{$divClassName}" id="{$ScenariologgingID}">
        <div class="list-group-item list-group-item-action">
          <xsl:variable name ="testExecuted" select="@executed"/>
          <xsl:choose>
            <xsl:when test="$testExecuted='False'">
              This test was not executed.
              <p><b>Reason:</b><xsl:value-of select="reason/message"/></p>
            </xsl:when>
            <xsl:otherwise>
              Insert Table Here: <xsl:value-of select="$ScenarioNameWithoutAnyInfo"/>
            </xsl:otherwise>
          </xsl:choose>
            
            <!--b>Start Time:</b> <xsl:value-of select="@start-time"/><br></br>
            <b>End Time: </b> <xsl:value-of select="@end-time"/><br></br>
            <b>Asserts: </b> <xsl:value-of select="@asserts"/-->
            <!--xsl:if test="(@result='Ignored' or @result='Inconclusive')">
              <br></br>
              <b>Message: </b> <xsl:value-of select="reason/message"/>
            </xsl:if>
            <xsl:if test="(@result='Failure')">
              <br></br>
              <b>Message: </b> <xsl:value-of select="failure/message"/>
            </xsl:if-->
          
        </div>
      </div>
     <xsl:variable name="divLink" select="@fullname"/>
  </xsl:template>



<xsl:template name="string-replace-all">
  <xsl:param name="text" />
  <xsl:param name="replace" />
  <xsl:param name="by" />
  <xsl:choose>
    <xsl:when test="contains($text, $replace)">
      <xsl:value-of select="substring-before($text,$replace)" />
      <xsl:value-of select="$by" />
      <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="substring-after($text,$replace)" />
        <xsl:with-param name="replace" select="$replace" />
        <xsl:with-param name="by" select="$by" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="Build-Test-Failures">
  <xsl:variable name="FeatureName" select="@description"/>
    <xsl:for-each select=".//test-case[@result='Failure' or @result='Error' or @result='NotRunnable']">
      <xsl:variable name="ScenarioID">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="@name"/>
          <xsl:with-param name="replace" select="'.'"/>
          <xsl:with-param name="by" select="'_'"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutNull">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="$ScenarioID"/>
          <xsl:with-param name="replace" select="',null'"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutSystemStringorNull">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="$ScenarioNameWithoutNull"/>
          <xsl:with-param name="replace" select="',System_String[]'"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutSystemStringorNullorbracket">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="$ScenarioNameWithoutSystemStringorNull"/>
          <xsl:with-param name="replace" select="'('"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutSystemStringorNullorbrackets">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="$ScenarioNameWithoutSystemStringorNullorbracket"/>
          <xsl:with-param name="replace" select="')'"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutSystemStringorNullorbracketsorQuotes">
        <xsl:value-of select="translate($ScenarioNameWithoutSystemStringorNullorbrackets, '\&quot;', '&#8217;')"/>
      </xsl:variable>
      <xsl:variable name="ScenarioNameWithoutSystemStringorNullorbracketsorQuotesorCommas">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="$ScenarioNameWithoutSystemStringorNullorbracketsorQuotes"/>
          <xsl:with-param name="replace" select="','"/>
          <xsl:with-param name="by" select="''"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioName">
        <xsl:call-template name="substring-after-last">
          <xsl:with-param name="string" select="$ScenarioNameWithoutSystemStringorNull"/>
          <xsl:with-param name="delimiter" select="'Feature_'"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="ScenarioFullname">
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="@name"/>
          <xsl:with-param name="replace" select="'.'"/>
          <xsl:with-param name="by" select="'_'"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="panelColor">
        <xsl:choose>
          <xsl:when test="@result='Error'">
            panel-header-error
          </xsl:when>
          <xsl:when test="@result='NotRunnable'">
            panel-header-notrun
          </xsl:when>
          <xsl:otherwise>
            panel-header
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="panelHeaderColor" select="concat('panel-heading ',$panelColor)"/>
      <div class="panel panel-danger">
        <div class="{$panelHeaderColor}">
          <p class="panel-title">Feature: <xsl:value-of select="$FeatureName"/></p>
        </div>
        <div class="panel-body">
          <p><xsl:value-of select="$ScenarioName"/></p>
          <xsl:variable name ="testExecuted" select="@executed"/>
          <p>
            <b>Message: </b>
          <xsl:choose>
            <xsl:when test="$testExecuted='False'">
                <xsl:value-of select="reason/message"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="failure/message"/>
            </xsl:otherwise>
          </xsl:choose>
          </p>
          <input type="button" value="Open" class="btn btn-block btn-default OpenToAFailure" Failure="{$ScenarioNameWithoutSystemStringorNullorbracketsorQuotesorCommas}" />
        </div>
      </div>
      <!--div>
        <button type="button" class="btn btn-default btn-block bg-danger OpenToAFailure" Failure="{$ScenarioNameWithoutSystemStringorNullorbracketsorQuotesorCommas}" value="Open" style="text-align:left; padding-left:6px; background-color: #ffa6a6;"><xsl:value-of select="$ScenarioName"/></button>
      </div-->
    </xsl:for-each>
</xsl:template>

  <xsl:template name="substring-after-last">
    <xsl:param name="string" />
    <xsl:param name="delimiter" />
    <xsl:choose>
      <xsl:when test="contains($string, $delimiter)">
        <xsl:call-template name="substring-after-last">
          <xsl:with-param name="string" select="substring-after($string, $delimiter)" />
          <xsl:with-param name="delimiter" select="$delimiter" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$string" /></xsl:otherwise>
    </xsl:choose>
  </xsl:template>


</xsl:stylesheet>