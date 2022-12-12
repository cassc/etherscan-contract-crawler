// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../../mint/IMintNFT.sol";
import "../../state/StateNFTStorage.sol";

interface IBaseClaimNFT is IMintNFT {
    function setClaimValue(uint256 claimValue) external;

    function toggleClaim() external;

    function getClaimValue() external view returns (uint256);

    function getEditionTokenCounter(StateNFTStorage.Edition edition) external view returns (uint256);

    function isClaimAllowed() external view returns (bool);
}