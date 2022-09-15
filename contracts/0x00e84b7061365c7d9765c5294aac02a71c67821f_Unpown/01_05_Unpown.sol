// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ERC721 } from "solmate/tokens/ERC721.sol";
import { ERC1155 } from "solmate/tokens/ERC1155.sol";
import "solmate/auth/Owned.sol";


/// @title Unpown - protect yourself from replay attacks
// By UnPoWn - protect yourself from being PoWned!
contract Unpown is Owned(msg.sender){

  
  error IncorrectNetwork();
  error SameRecipient();
  error ContractExpired();
  error InvalidInput();

  // Expiry time is set during constructor
  uint256 private deployTime;
  uint256 constant internal CONTRACT_LIFE = 180 days;
  uint256 constant internal DIVIDER = 18446744073709551616;
  uint256 constant internal ONE_HUNDRED_PERCENT = 100_000;
  uint256 public CURRENT_FEE = 1000; 

  function setNewFee(uint256 newFee) onlyOwner public {
    if(newFee>ONE_HUNDRED_PERCENT){
      revert InvalidInput();
    }
    CURRENT_FEE = newFee;
  }

  // Public functions

  function sendEtherOnPoW(address recipient) public payable returns (bool) {
    if(block.timestamp > deployTime + CONTRACT_LIFE){
      revert ContractExpired();
    }
    if(_isEthMainnet()){
      revert IncorrectNetwork();
    }
    _checkRecipient(recipient);
    _sendEther(recipient);
    return true;
  }

  function sendEtherOnPoS(address recipient) public payable  returns (bool) {
    if(block.timestamp > deployTime + CONTRACT_LIFE){
      revert ContractExpired();
    }
    if(!_isEthMainnet()){
      revert IncorrectNetwork();
    }
    _checkRecipient(recipient);
    _sendEther(recipient);
    return true;
  }

  function sendERC20OnPoW(address token, address recipient, uint256 amount) public payable  returns (bool) {
    if(block.timestamp > deployTime + CONTRACT_LIFE){
      revert ContractExpired();
    }
    if(_isEthMainnet()){
      revert IncorrectNetwork();
    }
    _checkRecipient(recipient);
    _sendERC20(token, recipient, amount);
    return true;
  }

  function sendERC20OnPoS(address token, address recipient, uint256 amount) public payable  returns (bool) {
    if(block.timestamp > deployTime + CONTRACT_LIFE){
      revert ContractExpired();
    }
    if(!_isEthMainnet()){
      revert IncorrectNetwork();
    }
    _checkRecipient(recipient);
    _sendERC20(token, recipient, amount);
    return true;
  }

  function sendERC721OnPoW(address token, address recipient, uint256 tokenId) public  returns (bool) {
    if(block.timestamp > deployTime + CONTRACT_LIFE){
      revert ContractExpired();
    }
    if(_isEthMainnet()){
      revert IncorrectNetwork();
    }
    _checkRecipient(recipient);
    _sendERC721(token, recipient, tokenId);
    return true;
  }

  function sendERC721OnPoS(address token, address recipient, uint256 tokenId) public  returns (bool) {
    if(block.timestamp > deployTime + CONTRACT_LIFE){
      revert ContractExpired();
    }
    if(!_isEthMainnet()){
      revert IncorrectNetwork();
    }
    _checkRecipient(recipient);
    _sendERC721(token, recipient, tokenId);
    return true;
  }

  // Internal and private functions


  function _scaleAmountByPercentage(uint256 amount, uint256 scaledPercent)
    internal
    pure
    returns (uint256 scaledAmount)
  {
    assembly {
      scaledAmount := div(mul(amount, scaledPercent), 100000)
    }
  }

  function _isEthMainnet() private view returns (bool){
    return(block.difficulty > DIVIDER);
  }

  function _checkRecipient(address recipient) private view returns (bool){
    if(msg.sender == recipient) revert SameRecipient();
    return true;
  }

  function _sendEther(address recipient) private {
    (bool successOwner, ) = payable(owner).call{ value: _scaleAmountByPercentage(msg.value,CURRENT_FEE)}("");
    require(successOwner);
    (bool successRecipient, ) = payable(recipient).call{ value: _scaleAmountByPercentage(msg.value,ONE_HUNDRED_PERCENT-CURRENT_FEE)}("");
    require(successRecipient);
  }

  function _sendERC20(address token, address recipient, uint256 amount) private {
    ERC20(token).transferFrom(msg.sender, owner, _scaleAmountByPercentage(amount,CURRENT_FEE));
    ERC20(token).transferFrom(msg.sender, recipient, _scaleAmountByPercentage(amount,ONE_HUNDRED_PERCENT-CURRENT_FEE));
  }

  function _sendERC721(address token, address recipient, uint256 tokenId) private {
    // Cannot take a fee
    ERC721(token).transferFrom(msg.sender, recipient, tokenId);
  }

  constructor(){
    deployTime = block.timestamp;
  }
}