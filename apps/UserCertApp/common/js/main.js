/*
 *
    COPYRIGHT LICENSE: This information contains sample code provided in source code form. You may copy, modify, and distribute
    these sample programs in any form without payment to IBM® for the purposes of developing, using, marketing or distributing
    application programs conforming to the application programming interface for the operating platform for which the sample code is written.
    Notwithstanding anything to the contrary, IBM PROVIDES THE SAMPLE SOURCE CODE ON AN "AS IS" BASIS AND IBM DISCLAIMS ALL WARRANTIES,
    EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OR CONDITIONS OF MERCHANTABILITY, SATISFACTORY QUALITY,
    FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND ANY WARRANTY OR CONDITION OF NON-INFRINGEMENT. IBM SHALL NOT BE LIABLE FOR ANY DIRECT,
    INDIRECT, INCIDENTAL, SPECIAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR OPERATION OF THE SAMPLE SOURCE CODE.
    IBM HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS OR MODIFICATIONS TO THE SAMPLE SOURCE CODE.

 */

function wlCommonInit(){
	/*
	 * Use of WL.Client.connect() API before any connectivity to a MobileFirst Server is required. 
	 * This API should be called only once, before any other WL.Client methods that communicate with the MobileFirst Server.
	 * Don't forget to specify and implement onSuccess and onFailure callback functions for WL.Client.connect(), e.g:
	 *    
	 *    WL.Client.connect({
	 *    		onSuccess: onConnectSuccess,
	 *    		onFailure: onConnectFailure
	 *    });
	 *     
	 */
	
	// Common initialization code goes here
	
}

function logout () {
	console.log('Calling logout');
    
	WL.UserAuth.deleteCertificate()
	.always(function (res) {
            console.log(res);
    });
    
	WL.Client.logout('wl_userCertificateAuthRealm', {onSuccess: WL.Client.reloadApp});
    
}

function getData () {	
	var resourceRequest = new WLResourceRequest(
			"/adapters/DummyAdapter/getSecretData", 
			WLResourceRequest.GET
		);
	resourceRequest.send().then(
		    onSuccess,
		    onRequestFailure
		);
}

onSuccess = function (result) {
    console.log('Success: ', JSON.stringify(result));
	alert('Success: ' + result.responseJSON.secretData);
};
onRequestFailure = function (result) {
	console.log('Failure: ', JSON.stringify(result));
	alert('Failure: ' + result.errorCode + ': ' + result.errorMsg);
};