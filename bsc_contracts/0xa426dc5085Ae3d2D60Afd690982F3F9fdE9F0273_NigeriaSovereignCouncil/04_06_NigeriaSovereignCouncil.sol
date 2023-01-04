// SPDX-License-Identifier: Apache License, Version 2.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./proxy/UpgradeabilityProxy.sol";

contract NigeriaSovereignCouncil is UpgradeabilityProxy, Ownable {
    constructor(address implementationContract) public UpgradeabilityProxy(implementationContract) {}

    function implementation() external view returns (address) {
        return _implementation();
    }

    function upgrade(address newImplementation) external onlyOwner {
        _upgradeTo(newImplementation);
    }

    receive() external payable {}

    function kill(address account) external onlyOwner {
        selfdestruct(payable(account));
    }
}