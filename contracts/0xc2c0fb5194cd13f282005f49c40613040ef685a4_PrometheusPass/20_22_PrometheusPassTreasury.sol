//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";



abstract contract PrometheusPassTreasury is Ownable {

  address payable private _treasury;

  event SetTreasury(address prevTreasury, address newTreasury);
  event TreasuryReceivedValue(address treasury, uint amount);

  function setTreasury(address payable newTreasury) public onlyOwner {
    require(
      newTreasury != address(0),
      "Setting treasury to 0 address"
    );
    _treasury = newTreasury;
    emit SetTreasury(_treasury, newTreasury);
  }

  function getTreasury() public view returns (address) {
    return _treasury;
  }

  function _sendToTreasury(uint amount) internal {
    (bool sendValueSuccess, ) = getTreasury().call{value: amount}("");
    require(sendValueSuccess, "Failed to send value to treasury");
    emit TreasuryReceivedValue(_treasury, amount);
  }

  constructor(address payable treasury) {
    setTreasury(treasury);
  }

}