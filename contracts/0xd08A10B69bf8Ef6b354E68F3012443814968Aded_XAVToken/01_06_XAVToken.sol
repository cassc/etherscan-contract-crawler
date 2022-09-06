// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract XAVToken is ERC20, Ownable {
  bool private canMint;

  /// @notice initiates the contract with predefined params
  /// @dev initiates the contract with predefined params
  /// @param _name name of the erc20 token
  /// @param _symbol symbol of the erc20 token
  constructor(string memory _name, string memory _symbol)
    public
    ERC20(_name, _symbol)
  {
    canMint = true;
  }

  /// @notice Locks the cap and disables mint func.
  /// @dev Should be called only once. Allows owner to lock the cap and disable mint function.
  function setCapped() external onlyOwner {
    require(canMint == true, 'Cannot execute setCapped more than once.');
    canMint = false;
  }

  /// @notice Increases XAV total supply.
  /// @dev Allows owner to mint XAV tokens.
  /// @param account address of the owner
  /// @param amount amount to mint
  function mint(address account, uint256 amount) external onlyOwner {
    require(canMint == true, 'Total supply is now capped, cannot mint more');
    _mint(account, amount);
  }
}