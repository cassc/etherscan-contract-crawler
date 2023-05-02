pragma solidity ^0.8.2;

import"TransparentUpgradeableProxy.sol";


contract BoxProxy is TransparentUpgradeableProxy {
	constructor(address _logic, address _admin, bytes memory _data) public  TransparentUpgradeableProxy(_logic, _admin, _data) {}
}