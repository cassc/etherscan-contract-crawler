// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IWHAssetv2 {
    event Wrap(address indexed account, uint32 indexed tokenId, uint88 cost, uint88 amount, uint48 strike, uint32 expiration);
    event Unwrap(address indexed account, uint32 indexed tokenId, uint128 closePrice, uint128 optionProfit);

    struct Underlying {
        bool active;
        address owner;
        uint88 amount;
        uint48 expiration;
        uint48 strike;
    }

    function wrap(uint128 amount, uint period, address to, bool mintToken, uint minUSDCPremium) payable external returns (uint newTokenId);
    function unwrap(uint tokenId) external;
    function autoUnwrap(uint tokenId, address rewardRecipient) external returns (uint);
    function autoUnwrapAll(uint[] calldata tokenIds, address rewardRecipient) external returns (uint);
    function wrapAfterSwap(uint total, uint protectionPeriod, address to, bool mintToken, uint minUSDCPremium) external returns (uint newTokenId);
}