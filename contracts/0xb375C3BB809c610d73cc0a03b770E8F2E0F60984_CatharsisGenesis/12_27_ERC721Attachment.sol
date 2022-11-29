// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../Shared/IAttachmentHandler.sol";
import "../Shared/IAttachmentProvider.sol";
import "../Shared/IAttachmentRewards.sol";

import "./ERC721Batch.sol";

abstract contract ERC721Attachment is IAttachmentProvider, ERC721Batch{
  mapping(uint16 => Attachment) public attachments;
  mapping(address => AttachmentHandler) public attachmentHandlers;

  //nonpayable - public
  function attachTo(uint16 tokenId, address collection, uint16 duplicantId) external{
    //checks
    require(ERC721B.ownerOf(tokenId) == msg.sender, "Owner required");

    Attachment memory attachment = attachments[tokenId];
    require(attachment.started < 2, "Already attached");

    AttachmentHandler memory handler = attachmentHandlers[collection];
    require(handler.isEnabled, "Unsupported collection");

    //effects
    uint32 time = uint32(block.timestamp);
    attachments[tokenId] = Attachment(
      collection,         //collection
      duplicantId,        //duplicantId
      attachment.accrued, //accrued
      time                //started
    );
 

    //interactions
    IAttachmentHandler(collection).attach(msg.sender, tokenId, duplicantId);
    emit TokenAttached(tokenId, collection, duplicantId);
  }

  function claim(uint16 tokenId) external{
    //checks
    require(ERC721B.ownerOf(tokenId) == msg.sender, "Owner required");

    Attachment memory attachment = attachments[tokenId];
    require(attachment.started > 1, "Not attached");

    uint32 time = uint32(block.timestamp);
    uint32 pending = (time - attachment.started);

    AttachmentInfo memory info = AttachmentInfo(
      attachment.collection,  //collection
      tokenId,                //tokenId
      tokens[tokenId].model,  //tokenModel
      attachment.accrued,     //accrued
      pending                 //pending
    );

    //effects
    attachments[tokenId] = Attachment(
      attachment.collection,      //collection
      attachment.duplicantId,     //duplicantId
      attachment.accrued + pending, //accrued
      time                        //started
    );

    //interactions
    IAttachmentHandler(attachment.collection).claim(msg.sender, tokenId, attachment.duplicantId);

    AttachmentHandler memory handler = attachmentHandlers[attachment.collection];
    IAttachmentRewards(handler.rewarder).handleRewards(msg.sender, info);
  }

  function detachFrom(uint16 tokenId, bool reattach) external {
    require(ERC721B.ownerOf(tokenId) == msg.sender, "Owner required");

    Attachment memory attachment = attachments[tokenId];
    require(attachment.started > 1, "Not attached");

    uint32 time = uint32(block.timestamp);
    uint32 pending = (time - attachment.started);

    AttachmentInfo memory info = AttachmentInfo(
      attachment.collection,  //collection
      tokenId,                //tokenId
      tokens[tokenId].model,  //tokenModel
      attachment.accrued,     //accrued
      pending                 //pending
    );

    reattach = reattach && attachmentHandlers[attachment.collection].isEnabled;
    if(reattach){
      attachments[tokenId] = Attachment(
        attachment.collection,      //collection
        attachment.duplicantId,     //duplicantId
        attachment.accrued + pending, //accrued
        time                        //started
      );
    }
    else{
      attachments[tokenId] = Attachment(
        address(0),                 //collection
        0,                          //duplicantId
        attachment.accrued + pending, //accrued
        1                           //started
      );
    }

    if(!reattach){
      IAttachmentHandler(attachment.collection).detach(msg.sender, tokenId, attachment.duplicantId);
    }

    AttachmentHandler memory handler = attachmentHandlers[attachment.collection];
    IAttachmentRewards(handler.rewarder).handleRewards(msg.sender, info);
    emit TokenDetached(tokenId, attachment.collection, attachment.duplicantId);
  }

  function transferAttachment(address from, address to, uint16 tokenId) external{
    require(attachmentHandlers[msg.sender].isEnabled, "");
    require(attachments[tokenId].collection == msg.sender, "");
    require(ERC721B.ownerOf(tokenId) == from, "");

    ERC721B._transfer(from, to, tokenId);
  }


  //view - public
  function getAttachmentInfo(uint16[] calldata tokenIds) external view returns (AttachmentInfo[] memory infos) {
    uint32 time = uint32(block.timestamp);

    infos = new AttachmentInfo[]( tokenIds.length );
    for(uint256 i; i < tokenIds.length; ++i ){
      uint16 tokenId = tokenIds[i];
      Token memory token = tokens[tokenId];
      Attachment memory attachment = attachments[tokenId];
      if( attachment.started > 1 ){
        uint32 pending = time - attachment.started;
        infos[i] = AttachmentInfo(
          attachment.collection,  //collection
          tokenId,                //tokenId
          token.model,            //tokenModel
          attachment.accrued,     //accrued
          pending                 //pending
        );
      }
      else{
        infos[i] = AttachmentInfo(
          address(0),         //collection
          tokenId,            //tokenId
          token.model,        //tokenModel
          attachment.accrued, //accrued
          0                   //pending
        );
      }
    }
  }

  function getCategories(uint16) external pure returns(Category[] memory categories){
    categories = new Category[]( 1 );
    categories[0] = Category.RING;
  }

  function getRewardHandler(uint16 tokenId) external view returns(address){
    Attachment memory attachment = attachments[tokenId];
    return attachmentHandlers[attachment.collection].rewarder;
  }

  function isAttached(uint16 tokenId) public view returns(bool){
    return attachments[tokenId].started > 1;
  }


  //view - override
  function ownerOf(uint256 tokenId) public view override(ERC721B, IERC721) returns(address currentOwner){
    if (tokenId > type(uint16).max || !_exists(tokenId))
      revert("ERC721Attachment: query for nonexistent token");

    if(isAttached(uint16(tokenId)))
      currentOwner = address(this);
    else
      currentOwner = ERC721B.ownerOf(tokenId);
  }

  function _transfer(address from, address to, uint256 tokenId) internal override{
    require(!isAttached(uint16(tokenId)), "Cannot transfer while attached");

    ERC721B._transfer( from, to, tokenId );
  }
}