// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./AbstractRoyalties.sol";
import "./RoyaltiesV2.sol";

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {
    function getRaribleV2Royalties(uint256 id) external view override returns (LibPart.Part[] memory) {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) internal override {
        emit RoyaltiesSet(id, _royalties);
    }
}