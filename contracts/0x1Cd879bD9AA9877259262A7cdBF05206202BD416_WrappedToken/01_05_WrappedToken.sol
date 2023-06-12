// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "../../util/Ownable.sol";
import "../../proxy/UpgradeabilityProxy.sol";

contract WrappedToken is UpgradeabilityProxy, Ownable {
    event Upgraded(uint256 indexed version, address indexed implementation);

    constructor(address implementationContract, address newOwner) public UpgradeabilityProxy(implementationContract) {
        setOwner(newOwner);
    }

    function upgradeTo(uint256 newVersion, address newImplementation) external onlyOwner {
        _upgradeTo(newVersion, newImplementation);
        emit Upgraded(newVersion, newImplementation);
    }

    receive() external payable {}
}