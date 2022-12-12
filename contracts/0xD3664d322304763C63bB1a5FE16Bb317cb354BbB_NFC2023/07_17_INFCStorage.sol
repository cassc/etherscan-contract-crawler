// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface INFCStorage {
    function phase() external view returns (uint256);
    function emergency() external view returns (bool);
    function salesLocked() external view returns (bool);
    function basePrice() external view returns (uint256);
    function merkleRoot() external view returns (bytes32);
    function storeWhitelistClaim(address _address) external;
    function redeem(address _nft_contract, uint256 _nft_id) external;
    function whitelistClaimed(address _address) external view returns (bool);
    function checkEligibility(address _nft_contract, uint256 _nft_id) external;
}