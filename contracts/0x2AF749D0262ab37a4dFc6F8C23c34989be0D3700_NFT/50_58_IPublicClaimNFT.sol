// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../base/IBaseClaimNFT.sol";
import "../../state/StateNFTStorage.sol";

interface IPublicClaimNFT is IBaseClaimNFT {
    function togglePublicClaim() external;

    function publicClaim(StateNFTStorage.Edition edition, StateNFTStorage.Size size)
        external
        payable
        returns (uint256 tokenId);

    function freeClaim(StateNFTStorage.Edition edition, StateNFTStorage.Size size) external returns (uint256 tokenId);

    function isPublicClaimAllowed() external view returns (bool);
}