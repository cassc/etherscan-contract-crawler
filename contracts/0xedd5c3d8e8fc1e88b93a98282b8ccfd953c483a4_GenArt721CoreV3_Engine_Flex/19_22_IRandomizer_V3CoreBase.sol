// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IRandomizer_V3CoreBase {
    /**
     * @notice This function is intended to be called by a core contract, and
     * the core contract can be assured that the randomizer will call back to
     * the calling contract to set the token hash seed for `_tokenId` via
     * `setTokenHash_8PT`.
     * @dev This function may revert if hash seed generation is improperly
     * configured (for example, if in polyptych mode, but no hash seed has been
     * previously configured).
     * @dev This function is not specifically gated to any specific caller, but
     * will only call back to the calling contract, `msg.sender`, to set the
     * specified token's hash seed.
     * A third party contract calling this function will not be able to set the
     * token hash seed on a different core contract.
     * @param _tokenId The token ID must be assigned a hash.
     */
    function assignTokenHash(uint256 _tokenId) external;
}