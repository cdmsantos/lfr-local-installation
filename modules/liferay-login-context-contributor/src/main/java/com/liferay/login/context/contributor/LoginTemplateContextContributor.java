package com.liferay.login.context.contributor;

import java.util.Map;

import javax.portlet.PortletRequest;
import javax.portlet.PortletURL;
import javax.portlet.WindowStateException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;

import com.liferay.portal.kernel.facebook.FacebookConnect;
import com.liferay.portal.kernel.json.JSONObject;
import com.liferay.portal.kernel.json.JSONUtil;
import com.liferay.portal.kernel.portlet.LiferayWindowState;
import com.liferay.portal.kernel.portlet.PortletURLFactoryUtil;
import com.liferay.portal.kernel.servlet.PortalSessionThreadLocal;
import com.liferay.portal.kernel.template.TemplateContextContributor;
import com.liferay.portal.kernel.theme.ThemeDisplay;
import com.liferay.portal.kernel.util.GetterUtil;
import com.liferay.portal.kernel.util.HttpUtil;
import com.liferay.portal.kernel.util.PropsKeys;
import com.liferay.portal.kernel.util.PropsUtil;
import com.liferay.portal.kernel.util.PwdGenerator;
import com.liferay.portal.kernel.util.Validator;
import com.liferay.portal.kernel.util.WebKeys;

/**
 * @author crystalsantos
 */
@Component(
	immediate = true,
	property = {"type=" + TemplateContextContributor.TYPE_GLOBAL},
	service = TemplateContextContributor.class
)
public class LoginTemplateContextContributor implements TemplateContextContributor {


	@Reference
	private FacebookConnect facebookConnect;
	
	@Override
	@SuppressWarnings("deprecation")
	public void prepare(
			Map<String, Object> contextObjects, HttpServletRequest request) {

		try {
			
			ThemeDisplay themeDisplay = (ThemeDisplay)request.getAttribute(WebKeys.THEME_DISPLAY);

			PortletURL renderUrl =  PortletURLFactoryUtil.create(request, "com_liferay_login_web_portlet_LoginPortlet", PortletRequest.RENDER_PHASE);
			renderUrl.setWindowState(LiferayWindowState.NORMAL);
			renderUrl.setParameter("mvcRenderCommandName", "/login/login_redirect");
			
			String facebookAuthRedirectURL = facebookConnect.getRedirectURL(themeDisplay.getCompanyId());
			String facebookAuthURL = facebookConnect.getAuthURL(themeDisplay.getCompanyId());
			String facebookAppId = facebookConnect.getAppId(themeDisplay.getCompanyId());

			
			HttpSession portalSession = PortalSessionThreadLocal.getHttpSession();
			
			String nonce = null;
			if(Validator.isNotNull(portalSession)) {

				nonce = (String) portalSession.getAttribute(WebKeys.FACEBOOK_NONCE);
				
				if(Validator.isNull(nonce)){
					nonce = PwdGenerator.getPassword(GetterUtil.getInteger(PropsUtil.get(PropsKeys.AUTH_TOKEN_LENGTH)));
					portalSession.setAttribute(WebKeys.FACEBOOK_NONCE, nonce);
				}
			}
			
			facebookAuthURL = HttpUtil.addParameter(facebookAuthURL, "client_id", facebookAppId);
			facebookAuthURL = HttpUtil.addParameter(facebookAuthURL, "redirect_uri", facebookAuthRedirectURL);
			facebookAuthURL = HttpUtil.addParameter(facebookAuthURL, "scope", "email");
			facebookAuthURL = HttpUtil.addParameter(facebookAuthURL, "stateNonce", nonce);
			
			JSONObject stateJSONObject = JSONUtil.put(
					"redirect", themeDisplay.getURLHome()
				).put(
					"stateNonce", nonce
				);
			
			facebookAuthURL = HttpUtil.addParameter(facebookAuthURL, "state", stateJSONObject.toString());

			contextObjects.put("facebook_url", facebookAuthURL);

		} catch (WindowStateException e) {
			e.printStackTrace();
		}
	}
}