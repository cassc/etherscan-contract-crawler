// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**

   8 888888888o.      ,o888888o.        ,o888888o.
   8 8888    `88.    8888     `88.     8888     `88.
   8 8888     `88 ,8 8888       `8. ,8 8888       `8.
   8 8888     ,88 88 8888           88 8888
   8 8888.   ,88' 88 8888           88 8888
   8 888888888P'  88 8888           88 8888
   8 8888`8b      88 8888           88 8888
   8 8888 `8b.    `8 8888       .8' `8 8888       .8'
   8 8888   `8b.     8888     ,88'     8888     ,88'
   8 8888     `88.    `8888888P'        `8888888P'

*/

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@mikker/contracts/contracts/UpdatableSplitter.sol";

contract MultiFlusher is AccessControl {
  bytes32 public constant FLUSHWORTHY = keccak256("FLUSHWORTHY");

  UpdatableSplitter[] private _splitters;

  constructor(address[] memory splitterAddresses) {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(FLUSHWORTHY, _msgSender());

    setSplitters(splitterAddresses);
  }

  function splitters() public view returns (UpdatableSplitter[] memory) {
    return _splitters;
  }

  function setSplitters(address[] memory splitterAddresses) public onlyRole(DEFAULT_ADMIN_ROLE) {
    delete _splitters;

    for (uint256 i = 0; i < splitterAddresses.length; i++) {
      _splitters.push(
        UpdatableSplitter(payable(splitterAddresses[i]))
      );
    }
  }

  function flush() external onlyRole(FLUSHWORTHY) {
    for(uint256 i = 0; i < _splitters.length; i++) {
      _splitters[i].flushCommon();
    }
  }
}