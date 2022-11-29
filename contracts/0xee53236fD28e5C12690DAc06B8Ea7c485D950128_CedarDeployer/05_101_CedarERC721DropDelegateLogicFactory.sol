// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../api/deploy/ICedarDeployer.sol";
import "./CedarERC721DropDelegateLogic.sol";

contract CedarERC721DropDelegateLogicFactory is Ownable {
    /// ===============================================
    ///  ========== State variables - public ==========
    /// ===============================================
    CedarERC721DropDelegateLogic public implementation;

    constructor() {
        // Deploy the implementation contract and set implementationAddress
        implementation = new CedarERC721DropDelegateLogic();
        implementation.initialize();
    }

    function deploy() external onlyOwner returns (CedarERC721DropDelegateLogic newClone) {
        newClone = CedarERC721DropDelegateLogic(Clones.clone(address(implementation)));
        newClone.initialize();
    }
}