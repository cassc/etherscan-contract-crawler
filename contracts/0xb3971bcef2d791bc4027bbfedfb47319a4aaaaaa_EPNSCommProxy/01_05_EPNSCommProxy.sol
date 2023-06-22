// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract EPNSCommProxy is TransparentUpgradeableProxy {


    constructor(
      address _logic,
      address _governance,
      address _pushChannelAdmin,
      string memory _chainName
    ) public payable TransparentUpgradeableProxy(_logic, _governance, abi.encodeWithSignature('initialize(address,string)', _pushChannelAdmin, _chainName)) {}

}