/**
* Copyright 2015 IBM Corp.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
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