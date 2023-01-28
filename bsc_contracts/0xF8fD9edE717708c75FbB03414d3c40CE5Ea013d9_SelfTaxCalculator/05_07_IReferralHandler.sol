// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IReferralHandler {
    function initialize(address, address, address, uint256) external;
    function setTier(uint256 _tier) external;
    function setDepositBox(address) external;
    function checkExistence(uint256, address) external view returns (address);
    function coupledNFT() external view returns (address);
    function referredBy() external view returns (address);
    function ownedBy() external view returns (address);
    function getTier() external view returns (uint256);
    function getTransferLimit() external view returns(uint256);
    function remainingClaims() external view returns (uint256);
    function updateReferralTree(uint256 depth, uint256 NFTtier) external;
    function addToReferralTree(uint256 depth, address referred, uint256 NFTtier) external;
    function mintForRewarder(address recipient, uint256 amount ) external;
    function alertFactory(uint256 reward, uint256 timestamp) external;
}