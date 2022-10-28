// contracts/TokenizedMetalInterface.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface TokenizedMetalInterface {
   function totalSupply() external view returns (uint256);
   function decimals() external view returns (uint8);
   function transferOwnership(address newOwner) external;   

   function mintTokens(uint256 amount) external;
   function burnTokens(uint256 amount) external;   
   function pauseTransfers() external;
   function resumeTransfers() external;   

   function transfer(address to, uint256 amount) external;
   function transferFrom(address from, address to, uint256 amount) external;
   function forceTransfer(address sender_, address recipient_, uint256 amount_, bytes32 details_) external;   

   function whitelistAddress(address account_, uint256 level_, uint direction_) external;
   function setMinterAddress(address minterAddress_) external;
   function setFeeForLevel(uint level_, uint fee_, uint feeAdded_) external;

   function setFeeCollectionAddress(address feeManager_) external;
   function getFeeCollectionAddress() external view returns (address);
}