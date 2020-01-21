<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <meta http-equiv="X-UA-Compatible" content="IE=edge">
                    <title>Wildfly example</title>
                    <link rel="SHORTCUT ICON" href="https://c.s-microsoft.com/favicon.ico?v2" type="image/x-icon"/>
                    <link rel="stylesheet" href="https://ajax.aspnetcdn.com/ajax/bootstrap/4.1.1/css/bootstrap.min.css" crossorigin="anonymous">
                    <link rel="stylesheet" type="text/css" href="https://appservice.azureedge.net/css/linux-landing-page/v3/main.css">
                    <style>
                        #container {
                            position: relative;
                        }
                        #abc{
                            position: relative;
                            bottom: 0px;
                        }
                        .abc{
                            position: relative;
                            bottom: 0px;
                        }
                    </style>
                    <script type="text/javascript">
                        window.onload=function(){try{var a=window.location.hostname;if(a.includes(".azurewebsites.net")){a=a.replace(".azurewebsites.net", "")}var b=document.getElementById("depCenterLink");b.setAttribute("href", b.getAttribute("href") + "&sitename=" + a);}catch(d){}}
                    </script>
    </head>
    <body>
        <nav class="navbar navbar-light bg-light">
            <a class="navbar-brand " href="#">
                <div class="container pl-4 ml-5">
                </div>
            </a>
        </nav>
        <div class="container-fluid container-height mr-2">
            <div class="pt-10 pb-10 mt-10 mb-10 d-xxs-none d-xs-none d-sm-none d-md-none d-lg-block d-xl-block" style="height:20px; width:100%; clear:both;"></div>
            <%-- <div class="row">
                <div class=" extra-pl-small-scr col-xl-6 col-lg-6 col-md-10 col-sm-11 col-xs-11 div-vertical-center">
                    <div class="container-fluid">
                        <div class="row">
                            <h4>The Wildfly container is running.</h4>
                        </div>
                        <div class="row info-mg-top">
                            <p class=" pl-0 col-md-6 col-sm-12 info-mg-top">
                                Now it's time to deploy the sample WAR application. See the next step in README.md for instructions.
                            </p>
                        </div>
                    </div>
                </div>
            </div> --%>
            <div class="row">
                <div class=" extra-pl-small-scr offset-xl-1 offset-lg-1 offset-md-2 offset-sm-2 offset-xs-4 col-xl-5 col-lg-5 col-md-10 col-sm-11 col-xs-11 div-vertical-center">
                    <div class="container-fluid">
                        <div class="row">
                            <h4>The Wildfly container is running.</h4><br>
                            <p>Now it's time to deploy the sample WAR application. See the next step in README.md for instructions.</p><br>
                            <b>Java Information:</b>
                        </div>
                        <div class="row">
                            <%@ page import="java.util.*" %>
                            <%
                                ArrayList<String> mainPageProps = new ArrayList<String>();
                                mainPageProps.add("java.version");
                                mainPageProps.add("jboss.home.dir");
                                mainPageProps.add("java.home");

                                for(String name : mainPageProps)
                                {
                                    String value = System.getProperty(name);
                                    if(value != null)
                                    {
                                        out.print(name + ": " + value + "<br>");
                                    }
                                }
                            %>
                        </div>
                    </div>
                </div>
                <div class="col-xl-5 col-lg-5 col-md-12 d-none d-lg-block"></div>
                <div class="col-xl-1 col-lg-1 col-md-1"></div>
            </div>
        </div>

        <!-- Bootstrap core JavaScript==================================================-->
        <script src="https://ajax.aspnetcdn.com/ajax/jquery/jquery-3.2.1.min.js" crossorigin="anonymous"></script>
        <script src="https://ajax.aspnetcdn.com/ajax/bootstrap/4.1.1/bootstrap.min.js" crossorigin="anonymous"></script>
    </body>
</html>
