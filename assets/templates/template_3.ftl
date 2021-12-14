<div id="div-openIdConnect">

    <form id="login-openIdConnect" action="/web/guest/admin/-/login/openid_connect_request" method="POST">
        <div class="btn-group w-100" role="group" aria-label="Login Buttons">
                        
            <#-- DIV Form escondida para login com OpenIDConnect-->
            <input type="hidden" name="_com_liferay_login_web_portlet_LoginPortlet_OPEN_ID_CONNECT_PROVIDER_NAME" value="${OpenIDProvider.getData()}"></input>
            
            <a type="button" class="btn liferay-btn liferay-btn-google" target="_blank" id="_com_liferay_login_web_portlet_LoginPortlet_tpvb" type="button" onclick="submitOpenIdForm('login-openIdConnect')">
                <#if (OpenIDProvider.OpenIDIcon.getData())?? && OpenIDProvider.OpenIDIcon.getData() != "">
                    <img class="liferay-login google-icon" alt="${OpenIDProvider.OpenIDIcon.getAttribute("alt")}" data-fileentryid="${OpenIDProvider.OpenIDIcon.getAttribute("fileEntryId")}" src="${OpenIDProvider.OpenIDIcon.getData()}"/>
                </#if>
            
                <span>${OpenIDProvider.OpenIDText.getData()}</span>
            </a>
            
            <a type="button" class="btn liferay-btn liferay-btn-facebook" target="_blank" onclick="facebookRedirect('${facebook_url}')">
                <#if (FacebookText.FacebookIcon.getData())?? && FacebookText.FacebookIcon.getData() != "">
                    <img class="liferay-login facebook-icon" alt="${FacebookText.FacebookIcon.getAttribute("alt")}" data-fileentryid="${FacebookText.FacebookIcon.getAttribute("fileEntryId")}" src="${FacebookText.FacebookIcon.getData()}" />
                </#if>
                <span>${FacebookText.getData()}</span>
            </a>

        </div>
        
    </form>
</div>

<script>
    function submitOpenIdForm(form){
        Liferay.fire("loading", {showing:true})
        document.getElementById(form).submit()
    };
    
    function facebookRedirect(url){
        event.preventDefault()
        Liferay.fire("loading", {showing:true})
        location.href = url;
    }
</script>

<style>
.liferay-login {
    padding: 20px;  
    border-radius: 5px;
}

.facebook-icon {
    height: 73px;
    width: auto;
    padding-left: 15px;
}

.google-icon {
    height: 70px;
    width: auto;
    padding-left: 15px;
}

.liferay-btn {
    max-height: 50px;
}

.liferay-btn-facebook{
    border-radius: 0px 33px 33px 0px;
    color: #FFF;
    background-color: #255ADE;
    font-size: 17px;
    display: flex;
    align-items:center;
    width: 50%;
}

.liferay-btn-facebook.span{
    margin: auto;
}

.liferay-btn-facebook:hover {
    color: #FFF;
}

.liferay-btn-google{
    border-radius: 33px 0px 0px 33px !important;;
    color: #255ADE;
    background-color: #FFF;
    font-size: 17px;
    box-shadow: 0px 3px 6px rgba(0,0,0, 0.16);
    display: flex;
    align-items:center;
    width: 50%;
}

.liferay-btn-google.span{
    margin: auto;
}

.liferay-btn-google:hover {
    color: #255ADE;
}
</style>