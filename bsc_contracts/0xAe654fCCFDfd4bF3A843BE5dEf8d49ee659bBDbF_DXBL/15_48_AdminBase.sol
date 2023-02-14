//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../../common/IPausable.sol";
import "../DexibleStorage.sol";

abstract contract AdminBase {
    
    modifier notPaused() {
        require(!DexibleStorage.load().paused, "Contract operations are paused");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == DexibleStorage.load().adminMultiSig, "Unauthorized");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == address(DexibleStorage.load().communityVault), "Only vault can execute this function");
        _;
    }

    modifier onlyRelay() {
        DexibleStorage.DexibleData storage dd = DexibleStorage.load();
        require(dd.relays[msg.sender], "Only relay allowed to call");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Only allowed as internal call");
        _;
    }

}