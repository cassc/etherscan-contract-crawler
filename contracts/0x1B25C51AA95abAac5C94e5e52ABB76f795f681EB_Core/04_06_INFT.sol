// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { NFTMetadata } from "./ICore.sol";

interface INFT {
    function initialize( 
        NFTMetadata calldata metadata,
        uint256 totalSupply,
        uint256 royaltyInBasisPoints,
        address _minter,
        address splitter
    ) external;
}