// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import {IRoyaltyRegistry} from "royalty-registry-solidity/IRoyaltyRegistry.sol";
import "openzeppelin/interfaces/IERC2981.sol";
import "solmate/utils/SafeTransferLib.sol";
import "reservoir-oracle/ReservoirOracle.sol";

import "./Pair.sol";

/// @title CaviarEthRoyaltyRouter
/// @author out.eth
/// @notice This contract is used to swap NFTs and pay royalties.
contract CaviarEthRoyaltyRouter is Owned, ERC721TokenReceiver {
    using SafeTransferLib for address;

    /// @notice The royalty registry from manifold.xyz.
    IRoyaltyRegistry public royaltyRegistry;

    constructor(address _royaltyRegistry) Owned(msg.sender) {
        royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
    }

    receive() external payable {}

    /// @notice Set the royalty registry.
    /// @param _royaltyRegistry The new royalty registry.
    function setRoyaltyRegistry(address _royaltyRegistry) public onlyOwner {
        royaltyRegistry = IRoyaltyRegistry(_royaltyRegistry);
    }

    /// @notice Make a buy and pay royalties.
    /// @param pair The pair address.
    /// @param tokenIds The tokenIds to buy.
    /// @param maxInputAmount The maximum amount of ETH to spend.
    /// @param deadline The deadline for the swap.
    /// @return inputAmount The amount of ETH spent.
    function nftBuy(address pair, uint256[] calldata tokenIds, uint256 maxInputAmount, uint256 deadline)
        public
        payable
        returns (uint256 inputAmount)
    {
        // make the swap
        inputAmount = Pair(pair).nftBuy{value: maxInputAmount}(tokenIds, maxInputAmount, deadline);

        // payout the royalties
        address nft = Pair(pair).nft();
        uint256 salePrice = inputAmount / tokenIds.length;
        uint256 totalRoyaltyAmount = _payRoyalties(nft, tokenIds, salePrice);
        inputAmount += totalRoyaltyAmount;

        // transfer the NFTs to the msg.sender
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }

        // Refund any surplus ETH
        if (address(this).balance > 0) {
            msg.sender.safeTransferETH(address(this).balance);
        }
    }

    /// @notice Sell NFTs and pay royalties.
    /// @param pair The pair address.
    /// @param tokenIds The tokenIds to sell.
    /// @param minOutputAmount The minimum amount of ETH to receive.
    /// @param deadline The deadline for the swap.
    /// @param proofs The proofs for the NFTs.
    /// @return outputAmount The amount of ETH received.
    function nftSell(
        address pair,
        uint256[] calldata tokenIds,
        uint256 minOutputAmount,
        uint256 deadline,
        bytes32[][] calldata proofs,
        ReservoirOracle.Message[] calldata messages
    ) public returns (uint256 outputAmount) {
        // transfer the NFTs to this contract
        address nft = Pair(pair).nft();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(nft).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }

        // approve the pair to transfer nfts from this contract
        _approve(address(nft), pair);

        // make the swap
        outputAmount = Pair(pair).nftSell(tokenIds, minOutputAmount, deadline, proofs, messages);

        // payout the royalties
        uint256 salePrice = outputAmount / tokenIds.length;
        uint256 totalRoyaltyAmount = _payRoyalties(nft, tokenIds, salePrice);
        outputAmount -= totalRoyaltyAmount;

        // Transfer ETH to sender
        msg.sender.safeTransferETH(address(this).balance);
    }

    /// @notice Get the royalty rate with 18 decimals of precision for a specific NFT collection.
    /// @param tokenAddress The NFT address.
    function getRoyaltyRate(address tokenAddress) public view returns (uint256) {
        address lookupAddress = royaltyRegistry.getRoyaltyLookupAddress(tokenAddress);
        (, uint256 royaltyAmount) = _getRoyalty(lookupAddress, 10, 1e18);
        return royaltyAmount;
    }

    /// @notice Approves the pair for transfering NFTs from this contract.
    /// @param tokenAddress The NFT address.
    /// @param pair The pair address.
    function _approve(address tokenAddress, address pair) internal {
        if (!ERC721(tokenAddress).isApprovedForAll(address(this), pair)) {
            ERC721(tokenAddress).setApprovalForAll(pair, true);
        }
    }

    /// @notice Pay royalties for a list of NFTs at a specified price for each NFT.
    /// @param tokenAddress The NFT address.
    /// @param tokenIds The tokenIds to pay royalties for.
    /// @param salePrice The sale price for each NFT.
    /// @return totalRoyaltyAmount The total amount of royalties paid.
    function _payRoyalties(address tokenAddress, uint256[] calldata tokenIds, uint256 salePrice)
        internal
        returns (uint256 totalRoyaltyAmount)
    {
        address lookupAddress = royaltyRegistry.getRoyaltyLookupAddress(tokenAddress);

        address recipient;
        totalRoyaltyAmount;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (address _recipient, uint256 royaltyAmount) = _getRoyalty(lookupAddress, tokenIds[i], salePrice);
            totalRoyaltyAmount += royaltyAmount;
            recipient = _recipient; // assume that royalty recipient is the same for all NFTs
        }

        if (totalRoyaltyAmount > 0 && recipient != address(0)) {
            recipient.safeTransferETH(totalRoyaltyAmount);
        }
    }

    /// @notice Get the royalty for a specific NFT.
    /// @param lookupAddress The lookup address for the NFT royalty info.
    /// @param tokenId The tokenId to get the royalty for.
    /// @param salePrice The sale price for the NFT.
    function _getRoyalty(address lookupAddress, uint256 tokenId, uint256 salePrice)
        internal
        view
        returns (address recipient, uint256 royaltyAmount)
    {
        if (IERC2981(lookupAddress).supportsInterface(type(IERC2981).interfaceId)) {
            (recipient, royaltyAmount) = IERC2981(lookupAddress).royaltyInfo(tokenId, salePrice);
        }
    }
}