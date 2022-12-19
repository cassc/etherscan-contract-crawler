//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AirdropHustler is Ownable {
  address[] internal addressesForAirdropHustler;
  mapping(address => bool) public addressToAllowedAirdropHustler;
  mapping(address => bool) public addressHasReceiveAirdropHustler;
  mapping(address => uint256) public addressToAllowedAirdropQtyHustler;

  constructor() {}

  function addAddressesForAirdopHustler(
    address[] memory _addresses,
    uint256[] memory _qtys
  ) public onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      addressToAllowedAirdropQtyHustler[_addresses[i]] = _qtys[i];
      if (!addressToAllowedAirdropHustler[_addresses[i]]) {
        addressToAllowedAirdropHustler[_addresses[i]] = true;
        addressesForAirdropHustler.push(_addresses[i]);
      }
    }
  }

  function addAddressForAirdropHustler(address _address, uint256 _qty)
    public
    onlyOwner
  {
    addressToAllowedAirdropQtyHustler[_address] = _qty;
    if (!addressToAllowedAirdropHustler[_address]) {
      addressToAllowedAirdropHustler[_address] = true;
      addressesForAirdropHustler.push(_address);
    }
  }

  function airdropAddressCountHustler() public view returns (uint256) {
    return addressesForAirdropHustler.length;
  }

  function makeAddressAbleToReceiveAirdropHustler(address _address)
    public
    onlyOwner
  {
    addressHasReceiveAirdropHustler[_address] = false;
    addressToAllowedAirdropQtyHustler[_address] = 0;
  }
}