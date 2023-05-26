// SPDX-License-Identifier: UNLICENCED
// Copyright 2021 Arran Schlosberg (@divergencearran)
pragma solidity 0.8.10;

import "@divergencetech/ethier/contracts/erc721/ERC721Common.sol";
import "@divergencetech/ethier/contracts/sales/LinearDutchAuction.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title PROOF Collective NFT
/// @author @divergencearran
contract PROOFCollective is ERC721Common, LinearDutchAuction {
    using Strings for uint256;

    constructor(
        string memory name,
        string memory symbol,
        address payable beneficiary
    )
        ERC721Common(name, symbol)
        LinearDutchAuction(
            LinearDutchAuction.DutchAuctionConfig({
                startPoint: 0, // disabled at deployment
                startPrice: 5 ether,
                unit: AuctionIntervalUnit.Time,
                decreaseInterval: 900, // 15 minutes
                decreaseSize: 0.5 ether,
                numDecreases: 9
            }),
            0.5 ether,
            Seller.SellerConfig({
                totalInventory: 1000,
                lockTotalInventory: true,
                maxPerAddress: 2,
                maxPerTx: 1,
                freeQuota: 75,
                lockFreeQuota: true,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {}

    /// @notice Entry point for purchase of a single token.
    function buy() external payable {
        Seller._purchase(msg.sender, 1);
    }

    /**
    @notice Internal override of Seller function for handling purchase (i.e.
    minting).
     */
    function _handlePurchase(
        address to,
        uint256 num,
        bool
    ) internal override {
        for (uint256 i = 0; i < num; i++) {
            _safeMint(to, totalSold() + i);
        }
    }

    /// @notice Prefix for tokenURI return values.
    string public baseTokenURI;

    /// @notice Set the baseTokenURI.
    function setBaseTokenURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    /// @notice Returns the token's metadata URI.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    /**
    @notice Returns total number of existing tokens.
    @dev Using ERC721Enumerable is unnecessarily expensive wrt gas. However
    Etherscan uses totalSupply() so we provide it here.
     */
    function totalSupply() external view returns (uint256) {
        return totalSold();
    }
}