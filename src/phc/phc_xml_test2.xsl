<?xml version='1.0'?>
<xsl:stylesheet
  xmlns:AST="http://www.phpcompiler.org/phc-1.1"
  xmlns:past="http://www.parrotcode.org/PAST-0.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:HIR="http://www.phpcompiler.org/phc-hir-1.1"
  xmlns:MIR="http://www.phpcompiler.org/phc-mir-1.1"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  version="1.0" >

<xsl:output method='xml' indent='yes' />
<xsl:strip-space  elements="*"/>


<!--

TODO: AST:source_rep

-->
<!--

$Id: phc_xml_to_past_xml.xsl 33276 2008-11-27 20:12:54Z bernhard $

This transformation takes a XML abstract syntax tree as generated
by PHC from PHP source code. It generates an XML representation of a PAST data structure.

-->

<xsl:template match="attrs/attr" >attr key=:(<xsl:value-of select="@key"/>)</xsl:template>  


<xsl:template match="/">
  <root>
  <xsl:apply-templates select="AST:PHP_script" />
</root>
</xsl:template>







<xsl:template match="text()">
  <MYTEXT><xsl:value-of select="."></xsl:value-of></MYTEXT>
</xsl:template>


<!--
<xsl:include href="newtemplates-inc.xsl"/>

-->
<xsl:template match="@*">
  <mattr>
    <xsl:for-each select="@*">
      attribute name: <xsl:value-of select="name()"/>
    attribute value: <xsl:value-of select="."/>
  </xsl:for-each>
  </mattr>

</xsl:template>



<xsl:template match="/*/Class_def/Member_list/Method/">
  MIKE: method of a class
</xsl:template>

<xsl:template match="text()">
  <MYTEXT>
    <xsl:copy-of select="text()"/>
    <xsl:value-of select="."></xsl:value-of>
  </MYTEXT>
</xsl:template>





 <xsl:template match="@*">
   <sattribute>
     <pname><xsl:value-of select="name(..)"/></pname>
     <name><xsl:value-of select="name(.)"/></name>
     <attributes><xsl:value-of select="."/></attributes>   
   </sattribute>
  
 </xsl:template>



<xsl:template match="AST:Method_invocation/AST:METHOD_NAME">
     <xsl:text >
</xsl:text>

  <AST:Method_invocation>
  <AST:METHOD_NAME>
  <attributes>  <xsl:apply-templates select="@*"/>
</attributes>
<xsl:apply-templates />
<method_name> <xsl:value-of select="value" /></method_name>

<past:Op>
  <xsl:attribute name="name" ><xsl:value-of select="value" /></xsl:attribute>
  <xsl:apply-templates select="AST:Actual_parameter_list" />
</past:Op>

  </AST:METHOD_NAME>
</AST:Method_invocation>
</xsl:template>


<xsl:template mode="runGenericsParent" 
match="*">
<xsl:if test="name(..)"><xsl:apply-templates mode="runGenericsParent" 
select=".."/>/</xsl:if><xsl:value-of select="name(.)"/>
</xsl:template>

<xsl:template name="runGenerics">
<xsl:text >
</xsl:text>

  <path> 
  <xsl:apply-templates mode="runGenericsParent" select="."/>
</path> 
  <attributes> 
  <xsl:apply-templates select="@*"/> </attributes>
  <xsl:apply-templates />
</xsl:template>



 <xsl:template match="node()">
     <xsl:text >
</xsl:text>

   <node>
     <pname><xsl:value-of select="name(..)"/></pname>
     <name><xsl:value-of select="name(.)"/></name>
     <text><xsl:value-of select="text()"/></text>   

     <child>
       <xsl:call-template name="runGenerics"/>
     </child>   
     <xsl:text >
</xsl:text>
</node>

 </xsl:template>


<xsl:template match="AST:Method_invocation" >
  <Method_invocation>
  <past:Op>
    <xsl:attribute name="name" ><xsl:value-of select="AST:METHOD_NAME/value" /></xsl:attribute>
    <xsl:apply-templates select="AST:Actual_parameter_list" />
    <xsl:apply-templates select="AST:CLASS_NAME"/>
    <xsl:apply-templates select="AST:Variable"/>
    <xsl:apply-templates select="AST:Target"/>

  </past:Op>
</Method_invocation>
</xsl:template>


<xsl:template match="AST:STRING" >
  <past:Val returns="PhpString" >
    <xsl:attribute name="encoding" ><xsl:value-of select="value/@encoding" /></xsl:attribute>
    <xsl:attribute name="value" ><xsl:value-of select="value" /></xsl:attribute>
  </past:Val>
</xsl:template>

<xsl:template match="AST:INT" >
  <past:Val returns="PhpInteger" >
    <xsl:attribute name="value" ><xsl:value-of select="value" /></xsl:attribute>
  </past:Val>
</xsl:template>

<xsl:template match="AST:BOOL" >
  <past:Val returns="PhpBoolean" >
    <xsl:attribute name="value" ><xsl:choose>
      <xsl:when test="value = 'True'"  >1</xsl:when>
      <xsl:when test="value = 'False'" >0</xsl:when>
    </xsl:choose></xsl:attribute>
  </past:Val>
</xsl:template>

<xsl:template match="AST:BOOL" >
  <past:Val returns="PhpNull" >
    <xsl:attribute name="value" >0</xsl:attribute>
  </past:Val>
</xsl:template>

<!-- looks like phc is running into a floating point issue -->
<xsl:template match="AST:REAL" >
  <past:Val returns='PhpFloat' >
    <xsl:attribute name="value" ><xsl:value-of select="AST:source_rep" /></xsl:attribute>
  </past:Val>
</xsl:template>

<xsl:template match="AST:Method/AST:Signature/AST:METHOD_NAME/value/text()">
  <MethodSignature>
    <xsl:value-of select="."></xsl:value-of>
  </MethodSignature>
</xsl:template>

<xsl:template match="AST:Post_op" >
  <AST:Post_op>
    <xsl:apply-templates select="AST:Target"/>
    <xsl:apply-templates select="AST:Expr_list"/>
    <xsl:apply-templates select="AST:OP"/>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Post_op>
</xsl:template>  

<xsl:template match="AST:Class_def/AST:INTERFACE_NAME_list">
  <skip></skip>
</xsl:template>


<xsl:template match="AST:Class_def/AST:CLASS_NAME">
      <xsl:apply-templates select="AST:CLASS_NAME"/>
</xsl:template>



<xsl:template match="AST:Type/AST:CLASS_NAME">
      <xsl:apply-templates select="AST:CLASS_NAME"/>
</xsl:template>

<xsl:template match="AST:Type/value"><MIKECLASSNAME></MIKECLASSNAME>
</xsl:template>


<xsl:template match="attrs/attr/integer"><MIKEINT></MIKEINT>
</xsl:template>
<xsl:template match="attrs/attr/string"><MIKESTRING></MIKESTRING>
</xsl:template>  


<xsl:template match="attrs/attr/string_list/string/@encoding"><ENCODING></ENCODING>
</xsl:template>
<xsl:template match="attrs/attr/string_list/string/text()"><STRINGINLIST></STRINGINLIST>
</xsl:template>

<xsl:template match="attrs/attr[@key='phc.line_number']">

  <LINENUMBER>
    <xsl:attribute name="linenumber">
    <xsl:value-of select="integer/text()"/>      
    </xsl:attribute>

</LINENUMBER>
</xsl:template>


<xsl:template match="attrs/attr[@key='phc.filename']">
  <Filename>
    <xsl:attribute name="filename">
      <xsl:value-of select="string/text()"/>
    </xsl:attribute>
</Filename>
</xsl:template>

<xsl:template match="attrs/attr[@key='phc.comments']">
  <Comment >
<xsl:for-each select="string_list/string">
  <COMMENT>
  <xsl:value-of select="."/>
</COMMENT>
</xsl:for-each>
</Comment>
</xsl:template>

<xsl:template match="AST:Class_mod/bool"><SKIPBOOL></SKIPBOOL>
  </xsl:template>

<xsl:template match="attrs/attr/@key">
  <SomKey>
  </SomKey>
</xsl:template>

<xsl:template match="AST:Class_mod">
  <CLASSMOD>
    <xsl:apply-templates select="attrs" />
  </CLASSMOD>  </xsl:template>
  
<xsl:template match="attrs">
<xsl:apply-templates select="attr" /></xsl:template>
<xsl:template match="AST:PHP_script">
<xsl:apply-templates select="AST:Statement_list"/>
</xsl:template>


<xsl:template match="AST:Member_list"> 
  <AST:Member_list>
    <xsl:apply-templates select="AST:Attribute"></xsl:apply-templates>
    <xsl:apply-templates select="AST:Method"></xsl:apply-templates>
  </AST:Member_list>
</xsl:template>

<xsl:template match="AST:Name_with_default_list">
  <AST:Name_with_default_list>
    <xsl:apply-templates select="Name_with_default">   
  </xsl:apply-templates>
  </AST:Name_with_default_list>
</xsl:template>

<xsl:template match="AST:Attribute">
  <AST:Attribute>
  <xsl:apply-templates select="AST:Attr_mod"/>
  <xsl:apply-templates select="AST:Name_with_default_list"/>
</AST:Attribute>
</xsl:template>


<xsl:template match="AST:Class_def">

  <AST:Class_def>
    <xsl:apply-templates select="AST:CLASS_NAME"></xsl:apply-templates>
    <xsl:apply-templates select="AST:Class_mod"></xsl:apply-templates>
    <xsl:apply-templates select="AST:Member_list"></xsl:apply-templates>
  </AST:Class_def>
</xsl:template>


<xsl:template match="AST:Method">
  <AST:Method>
    <xsl:apply-templates select="AST:Signature"/>
    <xsl:apply-templates select="AST:Statement_list"/>
  </AST:Method>
</xsl:template>



<xsl:template name="RunDecls">
  <subobjectsdecl>
    <xsl:apply-templates select="AST:Class_def" />
    <xsl:apply-templates select="AST:Global"/>
    <xsl:apply-templates select="AST:Static_declaration"/>
    <xsl:apply-templates select="AST:Eval_expr"/>
    <xsl:apply-templates select="AST:If"/>
    <xsl:apply-templates select="AST:Foreach"/>    
    <xsl:apply-templates select="AST:Return"/>
    <xsl:apply-templates select="AST:Break"/>
    <xsl:apply-templates select="AST:Continue"/>
    <xsl:apply-templates select="AST:Nop"/>
    <xsl:apply-templates select="AST:Switch"/>
    <xsl:apply-templates select="AST:Throw"/>
    <xsl:apply-templates select="AST:While"/>
  </subobjectsdecl>
</xsl:template>

<xsl:template match="AST:Assignment" >
  <xsl:call-template name="RunExpression" />
</xsl:template>

<xsl:template name="RunExpression" >
  <subobjects2>
      <xsl:apply-templates select="AST:Bin_op"/>
      <xsl:apply-templates select="AST:Array"/>
      <xsl:apply-templates select="AST:BOOL"/>
      <xsl:apply-templates select="AST:Cast"/>
      <xsl:apply-templates select="AST:Constant"/>
      <xsl:apply-templates select="AST:INT"/>
      <xsl:apply-templates select="AST:Method_invocation"/>
      <xsl:apply-templates select="AST:Post_op"/>
      <xsl:apply-templates select="AST:Pre_op"/>
      <xsl:apply-templates select="AST:STRING"/>
      <xsl:apply-templates select="AST:Unary_op"/>
      <xsl:apply-templates select="AST:Variable"/>
  </subobjects2>
</xsl:template>  

<xsl:template match="AST:Array_elem" >
  <ArrayElem>
    <xsl:apply-templates select="AST:Array"/>
    <xsl:apply-templates select="AST:Assignment"/>
    <xsl:apply-templates select="AST:BOOL"/>
    <xsl:apply-templates select="AST:Bin_op"/>
    <xsl:apply-templates select="AST:INT"/>
    <xsl:apply-templates select="AST:Method_invocation"/>
    <xsl:apply-templates select="AST:NIL"/>
    <xsl:apply-templates select="AST:STRING"/>
    <xsl:apply-templates select="AST:Variable"/>
  </ArrayElem>
</xsl:template>

<xsl:template match="AST:Formal_parameter" >
  <AST:Formal_parameter>
  <xsl:apply-templates select="AST:Name_with_default"/>
  <xsl:apply-templates select="AST:Type"/>
</AST:Formal_parameter>
</xsl:template>  

<xsl:template match="AST:Type" >
  <AST:Type>    
  <xsl:apply-templates select="AST:CLASS_NAME"/>
  </AST:Type>
</xsl:template>  

<xsl:template match="AST:Array_elem_list">
  <xsl:apply-templates select="AST:Array_elem"/>
</xsl:template>

<xsl:template match="AST:Array">
  <xsl:apply-templates select="AST:Array_elem_list"/>
</xsl:template>


<xsl:template match="AST:Signature">
  <xsl:apply-templates select="AST:Formal_parameter_list"/>
</xsl:template>


<xsl:template match="AST:Formal_parameter_list">
  <xsl:apply-templates select="AST:Formal_parameter"/>
</xsl:template>



<xsl:template match="AST:Name_with_default">
  <AST:Name_with_default>
    <xsl:apply-templates select="AST:Array"/>
    <xsl:apply-templates select="AST:BOOL"/>
    <xsl:apply-templates select="AST:Constant"/>
    <xsl:apply-templates select="AST:Expr"/>
    <xsl:apply-templates select="AST:INT"/>
    <xsl:apply-templates select="AST:NIL"/>
    <xsl:apply-templates select="AST:STRING"/>
    <xsl:apply-templates select="AST:VARIABLE_NAME"/>
  </AST:Name_with_default>
</xsl:template>

<xsl:template match="AST:VARIABLE_NAME">
  <VARIABLE_NAME>
    <xsl:attribute name="value"
      ><xsl:value-of select="./value"/></xsl:attribute>
  </VARIABLE_NAME>
</xsl:template>

<xsl:template match="AST:Attr_mod"></xsl:template>

<xsl:template match="AST:Method/AST:Statement_list">
  <AST:Statement_list>
  <past:Stmts>
    <xsl:apply-templates select="AST:For"/>
    <xsl:apply-templates select="AST:Foreach"/>
    <xsl:apply-templates select="AST:Global"/> 
    <xsl:apply-templates select="AST:If"/>    
    <xsl:apply-templates select="AST:Return"/>
    <xsl:apply-templates select="AST:Static_declaration"/>
    <xsl:apply-templates select="AST:Switch"/>    
    <xsl:apply-templates select="AST:While"/>    
    <xsl:apply-templates select="AST:Do"/>
    <xsl:apply-templates select="AST:Eval_expr"/>
  </past:Stmts>
</AST:Statement_list>
</xsl:template>

<xsl:template match="AST:PHP_script/AST:Statement_list">
  Statement_list:
  <past:Stmts>
    <xsl:apply-templates select="AST:Class_def" />
  </past:Stmts>
</xsl:template>


<xsl:template match="AST:Variable">
  <AST:Variable>
    <xsl:apply-templates select="AST:Expr_list"/>
    <xsl:apply-templates select="AST:Reflection"/>
    <xsl:apply-templates select="AST:Target"/>
    <xsl:apply-templates select="AST:VARIABLE_NAME"/>    
  </AST:Variable>
</xsl:template>



<xsl:template match="AST:Expr_list">
  <AST:Expr_list>
<xsl:apply-templates select="AST:Bin_op"/>
<xsl:apply-templates select="AST:Expr"/>
<xsl:apply-templates select="AST:INT"/>
<xsl:apply-templates select="AST:Method_invocation"/>
<xsl:apply-templates select="AST:Post_op"/>
<xsl:apply-templates select="AST:STRING"/>
<xsl:apply-templates select="AST:Variable"/>
</AST:Expr_list>
</xsl:template>


<xsl:template match="AST:Eval_expr">
  <AST:Eval_expr>
    <xsl:apply-templates select="AST:Assignment"/>
    <xsl:apply-templates select="AST:Ignore_errors"/>
    <xsl:apply-templates select="AST:List_assignment"/>
    <xsl:apply-templates select="AST:Method_invocation"/>
    <xsl:apply-templates select="AST:Op_assignment"/>
    <xsl:apply-templates select="AST:Post_op"/>
    <xsl:apply-templates select="AST:Pre_op"/>
</AST:Eval_expr>

</xsl:template>

<xsl:template match="AST:Statement_list">
  <AST:Statement_list>
    <xsl:apply-templates select="AST:For"/>      
    <xsl:apply-templates select="AST:Foreach"/>
    <xsl:apply-templates select="AST:Global"/>
    <xsl:apply-templates select="AST:Nop"/> 
    <xsl:apply-templates select="AST:Return"/> 
    <xsl:apply-templates select="AST:Static_declaration"/> 
    <xsl:apply-templates select="AST:Switch"/>
    <xsl:apply-templates select="AST:Break"/>
    <xsl:apply-templates select="AST:Continue"/>
    <xsl:apply-templates select="AST:Eval_expr"/>
    <xsl:apply-templates select="AST:Throw"/>
    <xsl:apply-templates select="AST:While"/>
</AST:Statement_list>  
</xsl:template>


<xsl:template match="AST:Target">
<AST:Target></AST:Target>
  <!--  <AST:Target xsi:nil="true" />-->
</xsl:template>

<xsl:template match="AST:Actual_parameter_list">
  <xsl:apply-templates select="AST:Actual_parameter"/>
</xsl:template>

<xsl:template match="AST:Actual_parameter" >
  <AST:Actual_parameter>
    <xsl:apply-templates select="AST:Array"/>
    <xsl:apply-templates select="AST:BOOL"/>
    <xsl:apply-templates select="AST:Bin_op"/>
    <xsl:apply-templates select="AST:Cast"/>
    <xsl:apply-templates select="AST:Constant"/>
    <xsl:apply-templates select="AST:INT"/>
    <xsl:apply-templates select="AST:Method_invocation"/>
    <xsl:apply-templates select="AST:Post_op"/>
    <xsl:apply-templates select="AST:Pre_op"/>
    <xsl:apply-templates select="AST:STRING"/>
    <xsl:apply-templates select="AST:Unary_op"/>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Actual_parameter>
</xsl:template>  



<xsl:template match="AST:OP">
  <past:Op>
    <xsl:attribute name="pirop" >
      <xsl:choose>
        <xsl:when test="value = '+'" >n_add</xsl:when>
        <xsl:when test="value = '-'" >n_sub</xsl:when>
        <xsl:when test="value = '*'" >n_mul</xsl:when>
        <xsl:when test="value = '/'" >n_div</xsl:when>
        <xsl:when test="value = '%'" >n_mod</xsl:when>
      </xsl:choose>
    </xsl:attribute>
    <xsl:attribute name="name" >
      <xsl:choose>
        <xsl:when test="value/@encoding = 'base64'" >
          <xsl:choose>
            <xsl:when test="value = 'PA=='" >infix:&lt;</xsl:when>
            <xsl:when test="value = 'PD0='" >infix:&lt;=</xsl:when>
            <xsl:when test="value = 'Pj0='" >infix:&gt;=</xsl:when>
            <xsl:when test="value = 'Pg=='" >infix:&gt;</xsl:when>
            <xsl:when test="value = 'Jg=='" >infix:&amp;</xsl:when>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="value = '&amp;&amp;'" >infix:AND</xsl:when>
        <xsl:when test="value = '||'" >infix:OR</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat('infix:', AST:OP/value)" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </past:Op>
 
</xsl:template>


<xsl:template match="AST:If">
  <AST:If>
    <xsl:apply-templates select="AST:Bin_op"/>
    <xsl:apply-templates select="AST:Method_invocation"/>
    <xsl:apply-templates select="AST:Statement_list"/>
    <xsl:apply-templates select="AST:Unary_op"/>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:If>
</xsl:template>


<xsl:template match="AST:Bin_op">
  <AST:Bin_op>
    <xsl:apply-templates select="AST:Assignment"/>
    <xsl:apply-templates select="AST:Assignment"/>
    <xsl:apply-templates select="AST:BOOL"/>
    <xsl:apply-templates select="AST:BOOL"/>
    <xsl:apply-templates select="AST:Constant"/>
    <xsl:apply-templates select="AST:INT"/>
    <xsl:apply-templates select="AST:Instanceof"/>
    <xsl:apply-templates select="AST:Method_invocation"/>
    <xsl:apply-templates select="AST:NIL"/>
    <xsl:apply-templates select="AST:OP"/>
    <xsl:apply-templates select="AST:STRING"/>
    <xsl:apply-templates select="AST:Unary_op"/>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Bin_op>  
</xsl:template>


<xsl:template match="AST:While">
  <AST:While>
    <xsl:apply-templates select="AST:Assignment"/>
    <xsl:apply-templates select="AST:BOOL"/>
    <xsl:apply-templates select="AST:Bin_op"/>
    <xsl:apply-templates select="AST:Statement_list"/>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:While>
 
</xsl:template>

<xsl:template match="AST:Swith">
  <AST:Switch>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Switch>
</xsl:template>

<xsl:template match="AST:Switch_case">
  <AST:Switch_case>
    <xsl:apply-templates select="AST:Constant"/>
    <xsl:apply-templates select="AST:Expr"/>
    <xsl:apply-templates select="AST:Expr"/>
    <xsl:apply-templates select="AST:INT"/>
    <xsl:apply-templates select="AST:STRING"/>
    <xsl:apply-templates select="AST:Statement_list"/>
  </AST:Switch_case>
</xsl:template>

<xsl:template match="AST:Switch_case_list">
  <AST:Switch_case_list>
    <xsl:apply-templates select="AST:Switch_case"/>
  </AST:Switch_case_list>
</xsl:template>

<xsl:template match="AST:CLASS_NAME">
  <AST:CLASS_NAME><xsl:value-of select="value"/>
    </AST:CLASS_NAME>
</xsl:template>

<xsl:template match="AST:CLASS_NAME/@*"></xsl:template>
<xsl:template match="AST:CLASS_NAME/value">MIKECLASSNAME</xsl:template>
<xsl:template match="AST:CLASS_NAME/attrs"></xsl:template>



<xsl:template match="AST:Break">
  <AST:Break>
    <AST:INT>
      <xsl:call-template name="runGenerics"/>
    </AST:INT>
    <AST:Expr>
      <xsl:call-template name="runGenerics"/>
    </AST:Expr>
    <value>
      <xsl:call-template name="runGenerics"/>
    </value>
  </AST:Break>  
</xsl:template>

<xsl:template match="AST:CAST">
  <AST:CAST>  
    <attrs>
      <xsl:call-template name="runGenerics"/>
    </attrs>
  </AST:CAST>
</xsl:template>

<xsl:template match="AST:CONSTANT_NAME">
  <AST:CONSTANT_NAME>
    <xsl:call-template name="runGenerics"/>
  </AST:CONSTANT_NAME>  
</xsl:template>

<xsl:template match="AST:Cast">
  <AST:Cast>
    <attrs>
      <xsl:call-template name="runGenerics"/>
    </attrs>
  </AST:Cast>

</xsl:template>
<xsl:template match="AST:Conditional_expr">

  <AST:Conditional_expr>
    <xsl:apply-templates select="AST:Array"/>
    <xsl:apply-templates select="AST:BOOL"/>
    <xsl:apply-templates select="AST:Bin_op"/>
    <xsl:apply-templates select="AST:Constant"/>
    <xsl:apply-templates select="AST:INT"/>
    <xsl:apply-templates select="AST:Method_invocation"/>
    <xsl:apply-templates select="AST:NIL"/>
    <xsl:apply-templates select="AST:STRING"/>
    <xsl:apply-templates select="AST:Unary_op"/>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Conditional_expr>
</xsl:template>

<xsl:template match="AST:Constant">
  <AST:Constant>
    <xsl:apply-templates select="AST:CLASS_NAME"/>     
    <xsl:apply-templates select="AST:CONSTANT_NAME"/>
  </AST:Constant>  
</xsl:template>


<xsl:template match="AST:Do">
  <AST:Do>
    <xsl:apply-templates select="AST:Bin_op"/>
    <xsl:apply-templates select="AST:Statement_list"/>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Do>
</xsl:template>


<xsl:template match="AST:Expr">
<AST:Expr xsi:nil="true" />
</xsl:template>

<xsl:template match="AST:For">
  <AST:For>
    <xsl:apply-templates select="AST:For"/>  
    <xsl:apply-templates select="AST:Assignment"/>
    <xsl:apply-templates select="AST:Bin_op"/>
    <xsl:apply-templates select="AST:Post_op"/>
    <xsl:apply-templates select="AST:Pre_op"/>
    <xsl:apply-templates select="AST:Statement_list"/>
  </AST:For>  
  
</xsl:template>

<xsl:template match="AST:Foreach">
  <AST:Foreach>
    <xsl:apply-templates select="AST:Statement_list"/>
    <xsl:apply-templates select="AST:Variable"/>   
  </AST:Foreach>
  
</xsl:template>

<xsl:template match="AST:Global">

  <AST:Global>
      <xsl:apply-templates select="AST:Variable_name_list"/>
  </AST:Global>
</xsl:template>

<xsl:template match="AST:Instanceof">
  <AST:Instanceof>
    <xsl:apply-templates select="AST:CLASS_NAME"/>    
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Instanceof>
</xsl:template>

<xsl:template match="AST:List_assignment">
  <AST:List_assignment>
    <xsl:apply-templates select="AST:List_element_list"/>
    <xsl:apply-templates select="AST:Method_invocation"/>
    <xsl:apply-templates select="AST:Variable"/>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:List_assignment>
</xsl:template>


<xsl:template match="AST:List_element_list">
  <AST:List_element_list>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:List_element_list>
</xsl:template>

<xsl:template match="AST:NIL"><AST:NIL/> </xsl:template>

<xsl:template match="AST:New">
<AST:New>
  <xsl:apply-templates select="AST:Actual_parameter_list"/>
  <xsl:apply-templates select="AST:Reflection"/>
</AST:New>
</xsl:template>

<xsl:template match="AST:Nop"><NOP/></xsl:template>

<xsl:template match="AST:Op_assignment">
  <AST:Op_assignment>
    <xsl:apply-templates select="AST:Bin_op"/>
    <xsl:apply-templates select="AST:Conditional_expr"/>
    <xsl:apply-templates select="AST:Constant"/>
    <xsl:apply-templates select="AST:Method_invocation"/>
    <xsl:apply-templates select="AST:OP"/>
    <xsl:apply-templates select="AST:STRING"/>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Op_assignment>

</xsl:template>

<xsl:template match="AST:Pre_op">

  <AST:Pre_op>
    <xsl:apply-templates select="AST:OP"/>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Pre_op>

</xsl:template>

<xsl:template match="AST:Reflection">
  <AST:Reflection>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Reflection>

</xsl:template>

<xsl:template match="AST:Return">

  <AST:Return>

<xsl:apply-templates select="AST:Array"/>
<xsl:apply-templates select="AST:Assignment"/>
<xsl:apply-templates select="AST:BOOL"/>
<xsl:apply-templates select="AST:Bin_op"/>
<xsl:apply-templates select="AST:Conditional_expr"/>
<xsl:apply-templates select="AST:Expr"/>
<xsl:apply-templates select="AST:Method_invocation"/>
<xsl:apply-templates select="AST:NIL"/>
<xsl:apply-templates select="AST:Post_op"/>
<xsl:apply-templates select="AST:STRING"/>
<xsl:apply-templates select="AST:Variable"/>

  </AST:Return>
</xsl:template>

<xsl:template match="AST:Static_declaration">
  <AST:Static_declaration>
    <xsl:apply-templates select="AST:Name_with_default_list"/>
  </AST:Static_declaration>
</xsl:template>

<xsl:template match="AST:Switch">

  <AST:Switch>
    <xsl:apply-templates select="AST:Variable"/>
  </AST:Switch>

</xsl:template>

<xsl:template match="AST:Throw">
<AST:Throw>
    <xsl:apply-templates select="AST:New"/>
</AST:Throw>
</xsl:template>

<xsl:template match="AST:Unary_op">
  <AST:Unary_op>    
  <xsl:apply-templates select="AST:Bin_op"/>
  <xsl:apply-templates select="AST:Instanceof"/>
  <xsl:apply-templates select="AST:Method_invocation"/>
  <xsl:apply-templates select="AST:OP"/>
  <xsl:apply-templates select="AST:Variable"/>
</AST:Unary_op>

</xsl:template>

<xsl:template match="AST:Variable_name_list">
  <AST:Variable_name_list>
    <xsl:apply-templates select="AST:VARIABLE_NAME"/>
  </AST:Variable_name_list>

</xsl:template>

<xsl:template match="AST:CONSTANT_NAME">
  <AST:CONSTANT_NAME><xsl:value-of select="value"/> </AST:CONSTANT_NAME>
</xsl:template>



</xsl:stylesheet>
