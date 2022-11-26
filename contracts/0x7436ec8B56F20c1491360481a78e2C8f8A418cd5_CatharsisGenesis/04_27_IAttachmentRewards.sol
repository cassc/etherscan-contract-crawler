//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct AttachmentInfo{
  address collection; //160
  uint16 tokenId;     //176
  uint16 tokenModel;  //192
  uint32 accrued;     //224
  uint32 pending;     //256
}

interface IAttachmentRewards {
  // public - nonpayable
  function handleRewards(address from, AttachmentInfo calldata info) external;

  // public - nonpayable - admin
  function setAttachmentProvider(address provider, bool isSupported) external;
  function setRewardProvider(address provider) external;
}