// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IInvestmentEarnings} from '../../interfaces/IInvestmentEarnings.sol';

contract MockPool {
  // Reserved storage space to avoid layout collisions.
  uint256[100] private ______gap;

  address internal _addressesProvider;
  address[] internal _reserveList;

  function initialize(address provider) external {
    _addressesProvider = provider;
  }

  function addReserveToReservesList(address reserve) external {
    _reserveList.push(reserve);
  }

  function getReservesList() external view returns (address[] memory) {
    address[] memory reservesList = new address[](_reserveList.length);
    for (uint256 i; i < _reserveList.length; i++) {
      reservesList[i] = _reserveList[i];
    }
    return reservesList;
  }
}

import {FintochPool} from '../../protocol/pool/FintochPool.sol';

contract MockPoolInherited is FintochPool {
  uint16 internal _maxNumberOfReserves = 128;

  constructor(
    IInvestmentEarnings investmentEarnings,
    address srcToken,
    address[] memory _owners,
    uint _required
  ) FintochPool(investmentEarnings, srcToken, _owners, _required) {}

  function setMaxNumberOfReserves(uint16 newMaxNumberOfReserves) public {
    _maxNumberOfReserves = newMaxNumberOfReserves;
  }

}