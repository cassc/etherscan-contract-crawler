// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../api/deploy/ICedarDeployer.sol";
import "./CedarERC1155DropDelegateLogic.sol";

contract CedarERC1155DropDelegateLogicFactory is Ownable {
    /// ===============================================
    ///  ========== State variables - public ==========
    /// ===============================================
    CedarERC1155DropDelegateLogic public implementation;

    constructor() {
        // Deploy the implementation contract and set implementationAddress
        implementation = new CedarERC1155DropDelegateLogic();

        implementation.initialize();
    }

    function deploy() external onlyOwner returns (CedarERC1155DropDelegateLogic newClone) {
        newClone = CedarERC1155DropDelegateLogic(Clones.clone(address(implementation)));
        newClone.initialize();
    }
}