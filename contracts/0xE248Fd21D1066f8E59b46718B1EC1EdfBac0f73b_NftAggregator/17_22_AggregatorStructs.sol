// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

struct FeeDetails {
    uint256 _profileTokenId;
    uint256 _wei;
}

/**
 * @dev Represents an array of ERC20 contract addresses and an array of
 * associated amounts, which are used for inputs in the aggregator for
 * purposes of trading
 */
struct ERC20Details {
    address[] tokenAddrs;
    uint256[] amounts;
}

/**
 * @dev Represents an ERC-721 NFT contract and it's associated
 * associated ids, which are used for inputs in the aggregator for
 * purposes of trading
 */
struct ERC721Details {
    address tokenAddr;
    address[] to;
    uint256[] ids;
}

/**
 * @dev Helps transfer ERC1155 NFTs using a tokenAddr and the ids and
 * amounts
 */
struct ERC1155Details {
    address tokenAddr;
    uint256[] ids;
    uint256[] amounts;
}

/**
 * @dev Helps aggregator approve tokens for use on nft marketplaces
 */
struct Approvals {
    address token;
    address operator;
    uint256 amount;
}

struct MultiAssetInfo {
    bytes[] conversionDetails;
    address[] dustTokens;
    FeeDetails feeDetails;
}