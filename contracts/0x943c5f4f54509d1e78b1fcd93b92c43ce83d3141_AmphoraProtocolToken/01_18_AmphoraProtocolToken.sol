// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IAmphoraProtocolToken} from '@interfaces/governance/IAmphoraProtocolToken.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC20, ERC20Permit, ERC20VotesComp} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol';

contract AmphoraProtocolToken is IAmphoraProtocolToken, ERC20VotesComp, Ownable {
  constructor(
    address _account,
    uint256 _initialSupply
  ) ERC20('Amphora Protocol', 'AMPH') ERC20Permit('Amphora Protocol') {
    if (_account == address(0)) revert AmphoraProtocolToken_InvalidAddress();
    if (_initialSupply <= 0) revert AmphoraProtocolToken_InvalidSupply();

    _mint(_account, _initialSupply);
  }

  /// @notice Mint a specified amount of tokens to a specified address
  function mint(address _dst, uint256 _rawAmount) public onlyOwner {
    _mint(_dst, _rawAmount);
  }
}