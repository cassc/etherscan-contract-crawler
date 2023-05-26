pragma solidity ^0.8.17;

import "TransparentUpgradeableProxy.sol";

contract KongEnsProxy is TransparentUpgradeableProxy {

	constructor(address _logic, address _admin, bytes memory _data) public  TransparentUpgradeableProxy(_logic, _admin, _data) {

	}
}