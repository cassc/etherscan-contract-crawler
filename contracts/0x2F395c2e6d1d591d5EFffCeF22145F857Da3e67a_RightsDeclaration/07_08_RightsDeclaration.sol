// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../iscc/MintangibleRegistrar.sol";
import "../rights/RightsProtocol.sol";

contract RightsDeclaration is Ownable {

  // Address of ISCC Registrar Smart Contract
  address private _isccAddr;

  // Address of Rights Protocol Smart contract
  address private _rightsProtocolAddr;

  // List of addresses that can make declarations using this contract
  mapping(address => bool) _allowed;

  constructor(address isccAddr_, address rightsProtocolAddr_) {
    _isccAddr = isccAddr_;
    _rightsProtocolAddr = rightsProtocolAddr_;
  }
  
  function isccAddr() public view returns (address) {
    return _isccAddr;
  }

  function setIsccAddr(address isccAddr_) public onlyOwner {
    _isccAddr = isccAddr_;
  }

  function rightsProtocolAddr() public view returns (address) {
    return _rightsProtocolAddr;
  }

  function setRightsProtocolAddr(address rightsProtocolAddr_) public onlyOwner {
    _rightsProtocolAddr = rightsProtocolAddr_;
  }

  function addAllowed(address addr) public onlyOwner {
    _allowed[addr] = true;
   }

  function isAllowed(address addr) internal view returns (bool) {
    return _allowed[addr];
  }

  function removeAllowed(address addr) public onlyOwner {
    _allowed[addr] = false;
  }

  function declare(
    address contractAddr, 
    uint256 tokenID, 
    string calldata rightsURI, 
    string calldata isccCode, 
    string calldata isccURI, 
    string calldata isccMessage)
    public returns (uint256) 
  {
    require(isAllowed(msg.sender) == true, "RightsDeclaration: Caller is not allowed to make declarations");
    MintangibleRegistrar(_isccAddr).declare(isccCode, isccURI, isccMessage);
    uint rightsID = RightsProtocol(_rightsProtocolAddr).declare(contractAddr, tokenID, rightsURI, false);
    return rightsID;
  }
 
}