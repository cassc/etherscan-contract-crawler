// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;
import {
  MintableBurnableSyntheticToken
} from './MintableBurnableSyntheticToken.sol';
import {
  ERC20Permit
} from '../../@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import {ERC20} from '../../@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {MintableBurnableERC20} from './MintableBurnableERC20.sol';
import {
  BaseControlledMintableBurnableERC20
} from './BaseControlledMintableBurnableERC20.sol';

/**
 * @title Synthetic token contract
 * Inherits from ERC20Permit and MintableBurnableSyntheticToken
 */
contract MintableBurnableSyntheticTokenPermit is
  ERC20Permit,
  MintableBurnableSyntheticToken
{
  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  )
    MintableBurnableSyntheticToken(tokenName, tokenSymbol, tokenDecimals)
    ERC20Permit(tokenName)
  {}

  /**
   * @notice Returns the number of decimals used
   */
  function decimals()
    public
    view
    virtual
    override(ERC20, BaseControlledMintableBurnableERC20)
    returns (uint8)
  {
    return BaseControlledMintableBurnableERC20.decimals();
  }
}