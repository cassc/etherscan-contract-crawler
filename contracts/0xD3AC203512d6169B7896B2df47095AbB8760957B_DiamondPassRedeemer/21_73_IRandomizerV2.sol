// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IGenArt721CoreContractV3_Base.sol";

interface IRandomizerV2 {
    // The core contract that may interact with this randomizer contract.
    function genArt721Core()
        external
        view
        returns (IGenArt721CoreContractV3_Base);

    // When a core contract calls this, it can be assured that the randomizer
    // will set a bytes32 hash for tokenId `_tokenId` on the core contract.
    function assignTokenHash(uint256 _tokenId) external;
}