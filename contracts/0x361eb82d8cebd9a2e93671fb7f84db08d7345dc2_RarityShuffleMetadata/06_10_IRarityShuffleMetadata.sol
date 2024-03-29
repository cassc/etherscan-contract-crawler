// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IMetadataModuleTrigger } from "@core/interfaces/IMetadataModuleTrigger.sol";
import { ISoundEditionV1 } from "@core/interfaces/ISoundEditionV1.sol";

/**
 * @title IRarityShuffleMetadata
 * @notice The interface for the Rarity Shuffle metadata module
 */
interface IRarityShuffleMetadata is IMetadataModuleTrigger {
    event NewModuleCreated(address, address);

    error OnlyEditionCanTrigger();
    error NoEditionsRemain();
    error RangeMustBeOrdered();

    /**
     * @dev Returns shuffled token Id
     * @param tokenId The token Id to query
     * @return uint256 The shuffled token Id
     */
    function getShuffledTokenId(uint256 tokenId) external view returns (uint256);
}