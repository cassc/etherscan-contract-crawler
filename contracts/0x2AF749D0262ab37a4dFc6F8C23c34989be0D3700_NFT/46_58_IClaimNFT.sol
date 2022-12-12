// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../state/StateNFTStorage.sol";

import "./public/IPublicClaimNFT.sol";
import "./whitelist/IWhitelistClaimNFT.sol";
import "./discount/IDiscountClaimNFT.sol";

interface IClaimNFT is IPublicClaimNFT, IWhitelistClaimNFT, IDiscountClaimNFT {
    function discountPublicClaim(
        StateNFTStorage.Edition edition,
        StateNFTStorage.Size size,
        bytes32[] calldata whitelistProof,
        uint256 claimValue
    ) external payable returns (uint256 tokenId);

    function discountWhitelistClaim(
        StateNFTStorage.Edition edition,
        StateNFTStorage.Size size,
        bytes32[] calldata whitelistProof,
        bytes32[] calldata discountProof,
        uint256 claimValue
    ) external payable returns (uint256 tokenId);
}