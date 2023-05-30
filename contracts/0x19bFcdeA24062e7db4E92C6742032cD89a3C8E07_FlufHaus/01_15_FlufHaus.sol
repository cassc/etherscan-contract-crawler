// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FlufHaus is ERC1155, ERC1155Holder, Ownable {

  string public name;

  constructor() ERC1155("http://3.122.178.254:3001/api/token/{id}") {
    name = "FLUF Haus";
  }

  function setTokenURI(string memory _tokenURI) public onlyOwner {
      _setURI(_tokenURI);
  }
  
  function getTokenURI(uint256 _id) 
    public 
    view 
    returns (string memory)
  {
    string memory idToString = Strings.toString(_id);
    string memory uri = uri(_id);
    string memory tokenURI = string(abi.encodePacked(uri, idToString));
    return tokenURI;
  }

  function setContractName(string memory _name) public onlyOwner {
    name = _name;
  }

  function mintBatch(uint256[] memory ids, uint256[] memory amounts)
    public
    onlyOwner
  {
    _mintBatch(msg.sender, ids, amounts, "");
  }

  function withdrawFunds() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function emergencyTokenWithdraw(uint256 _asset, uint256 _amount)
    public
    onlyOwner
  {
    _safeTransferFrom(address(this), msg.sender, _asset, _amount, "");
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, ERC1155Receiver)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}