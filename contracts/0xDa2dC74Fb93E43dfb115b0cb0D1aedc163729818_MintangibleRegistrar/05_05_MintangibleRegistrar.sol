// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IISCCHub.sol";
import "./IISCCRegistrar.sol";

contract MintangibleRegistrar is IISCCRegistrar, Ownable {

   address private _hub;
   mapping(address => bool) _allowed;

   constructor(address hub_) {
      _hub = hub_;
   }

   function hub() public view returns (address) {
      return _hub;
   }

   function setHub(address hub_) public onlyOwner {
      _hub = hub_;
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

   function declare(string calldata iscc, string calldata url, string calldata message) external override  {
      require(isAllowed(msg.sender) == true, "MintangibleRegistrar: Caller is not allowed to make declarations");
      IISCCHub(_hub).announce(iscc, url, message);
   }
}