// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Wallet is OwnableUpgradeable {

  receive() external payable {}

  function __Wallet_init() external initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
  }

  function invoke(address payable _to, uint _value, bytes memory _payload) public onlyOwner returns (bytes memory) {
    (bool success, bytes memory returnData) = _to.call{value: _value}(_payload);
    require(success, "Transaction failed, aborting");
    return returnData;
  }

}