// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./DAOContract.sol";

/**
@title Simple contract that adds upgradability to DAOContract
*/

contract DAOUpgradeableContract is Initializable, UUPSUpgradeable, DAOContract {
	function _authorizeUpgrade(address) internal virtual override {
		_onlyAvatar();
	}
}