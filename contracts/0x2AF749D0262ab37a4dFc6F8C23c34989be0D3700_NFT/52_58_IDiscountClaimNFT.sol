// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../base/IBaseClaimNFT.sol";
import "../../state/StateNFTStorage.sol";

interface IDiscountClaimNFT is IBaseClaimNFT {
    function setDiscountMerkleRoot(bytes32 discountMerkleRoot) external;

    function isDiscountClaimAllowed(bytes32[] calldata discountProof, uint256 claimValue) external view returns (bool);
}