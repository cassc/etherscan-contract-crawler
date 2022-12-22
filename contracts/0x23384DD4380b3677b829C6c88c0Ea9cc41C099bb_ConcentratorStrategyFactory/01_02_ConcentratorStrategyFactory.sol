// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract ConcentratorStrategyFactory {
  event NewConcentratorStrategy(address indexed _strategy);

  function createStrategy(address _implementation) external returns (address) {
    address _stratrgy = Clones.clone(_implementation);

    emit NewConcentratorStrategy(_stratrgy);

    return _stratrgy;
  }
}