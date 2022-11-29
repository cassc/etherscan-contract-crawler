//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct AttachmentHandler{
  address rewarder;
  bool isEnabled;
}

enum Category {
  NONE,
  HEAD,     //  1 -    1
  FACE,     //  2 -    2
  JACKET,   //  3 -    4
  HOODIE,   //  4 -    8
  SHIRT,    //  5 -   16
  BOTTOMS,  //  6 -   32
  SHOES,    //  7 -   64
  BACKPACK, //  8 -  128
  WRIST,    //  9 -  256
  NECK,     // 10 -  512
  RING,     // 11 - 1024
  EMOTE,    // 12 - 2048  
  MUSIC     // 13 - 4096
}

interface IAttachmentHandler{
  // public - nonpayable
  function attach(address from, uint16 tokenId, uint16 duplicantId) external;
  function claim(address from, uint16 tokenId, uint16 duplicantId) external;
  function detach(address from, uint16 tokenId, uint16 duplicantId) external;

  // public - nonpayable - admin
  function setAttachmentProvider(address provider, bool isSupported) external;
}