// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TailsTravelsProxy is TransparentUpgradeableProxy {
    // We intentionally override the ERC721A slot for _currentIndex here as we cannot
    // write the ERC721A _currentIndex private attribute when upgrading proxy implementation 
    // (which otherwise normally would be called in the ERC721A constructor).
    // This is to set the collection start index to 1
    uint256 private _currentIndex = 1; // SLOT 0x0000000000000000000000000000000000000000000000000000000000000000

    constructor(address logic) payable TransparentUpgradeableProxy(logic, msg.sender, bytes("")) {}

    function currentImplementation() external view returns (address) {
        return _implementation();
    }

    function currentAdmin() external view returns (address) {
        return _admin();
    }
}