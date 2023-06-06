// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ICrowdfundWithPodiumEditions {
    struct Edition {
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        // The price at which each token will be sold, in ETH.
        uint256 price;
        // The account that will receive sales revenue.
        address payable fundingRecipient;
        // The number of tokens sold so far.
        uint256 numSold;
        bytes32 contentHash;
    }

    struct EditionTier {
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        // The price at which each token will be sold, in ETH.
        uint256 price;
        bytes32 contentHash;
    }

    function buyEdition(uint256 editionId, address recipient)
        external
        payable
        returns (uint256 tokenId);

    function editionPrice(uint256 editionId) external view returns (uint256);

    function createEditions(
        EditionTier[] memory tier,
        // The account that should receive the revenue.
        address payable fundingRecipient,
        address minter
    ) external;

    function contractURI() external view returns (string memory);
}