// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "./state/StateNFT.sol";
import "./redeem/RedeemNFT.sol";
import "./claim/ClaimNFT.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is PaymentSplitterUpgradeable, ClaimNFT, RedeemNFT {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address aclContract,
        string memory name,
        string memory symbol,
        string memory baseUri,
        string memory collectionUri,
        uint256 maxEditionTokens,
        uint256 claimValue,
        bytes32 whitelistMerkleRoot,
        bytes32 discountMerkleRoot,
        address[] memory payees,
        uint256[] memory shares
    ) external initializer {
        __BaseNFTContract_init(aclContract, name, symbol, baseUri, collectionUri);

        __StateNFTContract_init_unchained();

        __MintNFTContract_init_unchained();

        __BaseClaimNFTContract_init_unchained(maxEditionTokens, claimValue);
        __PublicClaimNFTContract_init_unchained();
        __WhitelistClaimNFTContract_init_unchained(whitelistMerkleRoot);
        __DiscountClaimNFTContract_init_unchained(discountMerkleRoot);
        __ClaimNFTContract_init_unchained();

        __RedeemNFTContract_init_unchained();

        __PaymentSplitter_init(payees, shares);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(RedeemNFT, ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}