//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AirdropBigBoys is Ownable {
  address[] internal addressesForAirdropBigBoys;
  mapping(address => bool) public addressToAllowedAirdropBigBoys;
  mapping(address => bool) public addressHasReceiveAirdropBigBoys;
  mapping(address => uint256) public addressToAllowedAirdropQtyBigBoys;

  constructor() {}

  function addAddressesForAirdopBigBoys(
    address[] memory _addresses,
    uint256[] memory _qtys
  ) public onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      addressToAllowedAirdropQtyBigBoys[_addresses[i]] = _qtys[i];
      if (!addressToAllowedAirdropBigBoys[_addresses[i]]) {
        addressToAllowedAirdropBigBoys[_addresses[i]] = true;
        addressesForAirdropBigBoys.push(_addresses[i]);
      }
    }
  }

  function addAddressForAirdropBigBoys(address _address, uint256 _qty)
    public
    onlyOwner
  {
    addressToAllowedAirdropQtyBigBoys[_address] = _qty;
    if (!addressToAllowedAirdropBigBoys[_address]) {
      addressToAllowedAirdropBigBoys[_address] = true;
      addressesForAirdropBigBoys.push(_address);
    }
  }

  function airdropAddressCountBigBoys() public view returns (uint256) {
    return addressesForAirdropBigBoys.length;
  }

  function makeAddressAbleToReceiveAirdropBigBoys(address _address)
    public
    onlyOwner
  {
    addressHasReceiveAirdropBigBoys[_address] = false;
    addressToAllowedAirdropQtyBigBoys[_address] = 0;
  }
}