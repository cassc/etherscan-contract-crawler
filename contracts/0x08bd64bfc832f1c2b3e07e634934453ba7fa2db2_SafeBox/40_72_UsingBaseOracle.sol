pragma solidity 0.6.12;

import '../../interfaces/IBaseOracle.sol';

contract UsingBaseOracle {
  IBaseOracle public immutable base;

  constructor(IBaseOracle _base) public {
    base = _base;
  }
}