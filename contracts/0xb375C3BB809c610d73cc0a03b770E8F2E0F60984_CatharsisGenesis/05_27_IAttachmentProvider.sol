//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IAttachmentHandler.sol";
import "./IAttachmentRewards.sol";

struct Attachment{
  address collection; //160
  uint16 duplicantId; //176
  uint32 accrued;     //208
  uint32 started;     //240
}

interface IAttachmentProvider {
  event TokenAttached(uint16 indexed tokenId, address indexed collection, uint16 indexed duplicantId);
  event TokenDetached(uint16 indexed tokenId, address indexed collection, uint16 indexed duplicantId);

  // public - nonpayable
  function attachTo(uint16 tokenId, address collection, uint16 duplicantId) external;
  function claim(uint16 tokenId) external;
  function detachFrom(uint16 tokenId, bool reattach) external;
  function transferAttachment(address from, address to, uint16 tokenId) external;

  // public - nonpayable - admin
  function setAttachmentHandler(address collection, AttachmentHandler calldata handler) external;

  // public - view
  function getAttachmentInfo(uint16[] calldata tokenIds) external view returns(AttachmentInfo[] memory);
  function getCategories(uint16 tokenId) external pure returns(Category[] memory);
  function getRewardHandler(uint16 tokenId) external view returns(address);
  function isAttached(uint16 tokenId) external view returns(bool);
}