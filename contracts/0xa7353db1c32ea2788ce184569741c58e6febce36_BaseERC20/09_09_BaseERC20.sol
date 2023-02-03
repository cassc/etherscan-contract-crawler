// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/**
 * BaseERC20 is a basic erc20, burnable,
 * ownable token that is used for accounting purposes,
 * and to trade ownership over current and future token positions
 * The deployment plan is to distribute tokens to many accounts using multicall
 * then to renounce ownership, effectively making minting unavailable after that point
 */
contract BaseERC20 is ERC20, ERC20Burnable, Ownable, Multicall {
  constructor(string memory name_, string memory symbol_)
    ERC20(name_, symbol_)
    Ownable()
  {}

  /**
   * @param account the account to mint to
   * @param amount the amount to mint to
   * @notice this method is no longer available once ownership is renounced
   */
  function mint(address account, uint96 amount) public onlyOwner {
    _mint(account, amount);
  }
  /**
   * mint to many accounts at the same time
   * @param mints a list of bitpacked mints to mint
   * @notice this method is no longer available once ownership is renounced
   */
  function mintMany(uint256[] calldata mints) external onlyOwner {
    uint256 len = mints.length;
    for (uint256 i = 0; i < len; ++i) {
      uint256 mnt = mints[i];
      _mint(address(uint160(mnt >> 96)), uint96(mnt));
    }
  }
}