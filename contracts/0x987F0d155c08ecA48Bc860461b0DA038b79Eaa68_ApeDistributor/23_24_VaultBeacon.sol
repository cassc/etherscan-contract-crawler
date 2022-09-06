// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.2;

import "UpgradeableBeacon.sol";
import "IBeacon.sol";
import "TimeLock.sol";

contract VaultBeacon is TimeLock {

	mapping(uint256 => address) public deployments;
	uint256 public deploymentCount;

	mapping(address => uint256) public deploymentPref;

	event NewImplementationPushed(address newImplementation);

	constructor(address _apeVault, uint256 _minDelay) TimeLock(_minDelay) {
		require(Address.isContract(_apeVault), "VaultBeacon: implementation is not a contract");
		deployments[++deploymentCount] = _apeVault;
	}

	function implementation(address _user) public view returns(address) {
		uint256 pref = deploymentPref[_user];
		if(pref == 0)
			return deployments[deploymentCount];
		else
			return deployments[pref];
	}

	function implementation() public view returns(address) {
		return implementation(msg.sender);
	}

	function setDeploymentPrefs(uint256 _value) external {
		require(_value <= deploymentCount);
		deploymentPref[msg.sender] = _value;
	}

	function pushNewImplementation(address _newImplementation) public itself {
		require(Address.isContract(_newImplementation), "VaultBeacon: implementaion is not a contract");
		deployments[++deploymentCount] = _newImplementation;
		emit NewImplementationPushed(_newImplementation);
	}
}