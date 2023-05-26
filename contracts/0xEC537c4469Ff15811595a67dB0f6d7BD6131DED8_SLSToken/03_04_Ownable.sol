//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Ownable {

  address private owner;

  event NewOwner(address oldOwner, address newOwner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function contractOwner() external view returns (address) {
    return owner;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), 'Ownable: address is not valid');
    owner = _newOwner;
    emit NewOwner(msg.sender, _newOwner);
  } 
}