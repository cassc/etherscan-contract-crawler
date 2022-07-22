// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyEngine {
    event RoyaltyCfgUpdated(
        address indexed collection,
        address setter,
        address payable[] receivers,
        uint256[] fees
    );

    function updatetRoyaltyConfigByOwner(
        address collection,
        address setter,
        address payable[] calldata receivers,
        uint256[] calldata fees
    ) external;

    function updatetRoyaltyConfigBySetter(
        address collection,
        address setter,
        address payable[] calldata receivers,
        uint256[] calldata fees
    ) external;

    function overrideRoyaltyConfig(
        address collection,
        address setter,
        address payable[] calldata receivers,
        uint256[] calldata fees
    ) external;

    function getRoyalty(
        address collection,
        uint256 tokenId,
        uint256 value
    )
        external
        returns (address payable[] memory recipients, uint256[] memory amounts);
}