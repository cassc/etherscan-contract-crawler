// Copyright (c) 2023, GSKNNFT Inc
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.20;

interface IRoyalties {
  function setRoyaltyAddress(address _royaltyAddress) external;
  
  function setRoyaltyFee(uint96 _feeNumerator) external;
  
  function changeRoyalties(address _newRoyaltyAddress, uint96 _royaltyFee) external;
  
  function changePayoutAddresses(address[] calldata _newPayoutAddresses, uint16[] calldata _newPayoutBasisPoints) external;
  
  function setRoyalty(uint96 _fee, address _recipient) external;
  
  function activateHolderRoyalties(bool _val, uint256 _perc) external;
  
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
  
  function withdrawRoyalties() external;
    
  function beforeTokenTransfers_(address from, address to, uint256, uint256) external payable;
}