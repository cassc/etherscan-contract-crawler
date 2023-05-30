// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract MyGoodDogStakingProxy is TransparentUpgradeableProxy {
    constructor(address logic) payable TransparentUpgradeableProxy(logic, msg.sender, bytes("")) {}

    function currentImplementation() external view returns (address) {
        return _implementation();
    }

    function currentAdmin() external view returns (address) {
        return _admin();
    }
}