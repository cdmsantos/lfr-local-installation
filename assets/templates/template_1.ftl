
<div id="div-openIdConnect">
    <form id="login-openIdConnect" action="/web/guest/admin/-/login/openid_connect_request" method="POST">
        <#-- DIV Form escondida para login com OpenIDConnect-->
        <input 
          type="hidden" 
          name="_com_liferay_login_web_portlet_LoginPortlet_OPEN_ID_CONNECT_PROVIDER_NAME" 
          value="${OpenIDProvider.getData()}">
        </input>
        
        <input 
          class="link-lookalike" 
          id="_com_liferay_login_web_portlet_LoginPortlet_tpvb" 
          type="button" 
          onclick="submitOpenIdForm('login-openIdConnect')" 
          value="${LoginText.getData()}">
        </input>
    </form>
</div>

<script>
    function submitOpenIdForm(form){
        Liferay.fire("loading", {showing:true})
        document.getElementById(form).submit()
    };
</script>

<style>
.link-lookalike {
    background: none;
    border: none;
    color: black;
    cursor: pointer;
}

.link-lookalike:hover {
    text-decoration: underline;
    color: gray;
}
</style>