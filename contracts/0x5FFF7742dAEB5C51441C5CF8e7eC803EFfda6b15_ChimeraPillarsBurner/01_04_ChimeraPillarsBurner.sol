// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Delegated.sol';

interface IChimeraPillars{
  function burnFrom( address account, uint[] calldata tokenIds ) external;
}

contract ChimeraPillarsBurner is Delegated {
  bool public isBurnActive = false;

  IChimeraPillars public ChimeraPillars = IChimeraPillars(0x6f3B255eFA6b2d4133c4F208E98E330e8CaF86f3);

  function setIsBurnActive ( bool _isBurnActive ) external onlyDelegates {
    isBurnActive = _isBurnActive;
  }

  function setChimeraPillars ( IChimeraPillars principal ) external onlyDelegates {
    ChimeraPillars = principal;
  }

  function burnFrom ( address account, uint[] calldata tokenIds ) external {
    require( isBurnActive, "Burn is not currently active" );
    require( account == msg.sender, "Can only burn your own" );

    ChimeraPillars.burnFrom( account, tokenIds );
  }
}