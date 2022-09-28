// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./INFT.sol";

interface INFTRepresentation {
    /**
     * @dev see https://docs.opensea.io/docs/contract-level-metadata
     **/
    function getContractUri(INFT _nft) external view returns (string memory);

    /**
     * @dev see https://docs.opensea.io/docs/metadata-standards
     **/
    function getTokenUri(INFT _nft, uint _tokenId) external view returns (string memory);
}