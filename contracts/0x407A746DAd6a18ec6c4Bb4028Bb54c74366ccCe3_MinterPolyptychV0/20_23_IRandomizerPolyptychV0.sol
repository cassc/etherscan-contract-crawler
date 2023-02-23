// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity 0.8.17;

import "./IRandomizerV2.sol";

interface IRandomizerPolyptychV0 is IRandomizerV2 {
    /**
     * @notice Minter contract at `_contractAddress` allowed to assign token hash seeds.
     */
    event HashSeedSetterUpdated(address indexed _contractAddress);

    /**
     * @notice Project with ID `_projectId` is enabled/disabled for polyptych minting.
     */
    event ProjectIsPolyptychUpdated(uint256 _projectId, bool _isPolyptych);

    /**
     * @notice When a core contract calls this, it can be assured that the randomizer
     * will set a bytes32 hash for tokenId `_tokenId` on the core contract. This function
     * may only be called by the contract configured as the `hashSeedSetterContract` via
     * the `setHashSeedSetterContract` available to the core contract admin.
     */
    function assignTokenHash(uint256 _tokenId) external;

    /**
     * @notice Store the token hash seed for an existing token to be re-used in a polyptych panel.
     */
    function setPolyptychHashSeed(uint256 _tokenId, bytes12 _hashSeed) external;
}