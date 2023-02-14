// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Claimable.sol";

interface IBurnable {
    function burn(uint256 tokenId) external;
}

/**
 * @title Module handling claiming of mintable NFTs by buring passes.
 */
abstract contract ClaimableBurning is Claimable {

    /**
     * @dev Burn pass
     */
    function _setPassUsed(uint256 _tokenId) internal override {
        IBurnable(address(pass)).burn(_tokenId);
    }

    /**
     * @dev All existing tokenIds are unused, since using burns them.
     */
    function _getPassUsed(uint256) internal override pure returns (bool) {
        return false;
    }
}