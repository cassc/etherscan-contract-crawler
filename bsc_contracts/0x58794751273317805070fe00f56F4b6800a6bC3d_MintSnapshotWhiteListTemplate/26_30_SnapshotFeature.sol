// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../extensions/ERC20SnapshotRewrited.sol";
import "../features-interfaces/ISnapshotFeature.sol";

abstract contract SnapshotFeature is ERC20SnapshotRewrited, ISnapshotFeature {
    
    function _beforeTokenTransfer_hook(
        address from, 
        address to, 
        uint256 amount
    ) internal virtual {
        ERC20SnapshotRewrited._beforeTokenTransfer(from, to, amount);
    }

    function getCurrentSnapshotId() external override view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    function snapshot() external override {
        _snapshot();
    }

}