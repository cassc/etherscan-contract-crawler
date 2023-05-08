// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RektPepeAirdrop is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  using SafeERC20 for IERC20;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyOwner {}

  function withdraw(
    address payable receiver,
    address tokenAddress,
    uint256 amount
  ) public virtual onlyOwner {
    require(receiver != address(0x0), "BHP:E-403");
    IERC20 tokenContract = IERC20(tokenAddress);
    if (tokenContract.balanceOf(address(this)) >= amount) {
      tokenContract.approve(address(this), amount);
      tokenContract.safeTransfer(receiver, amount);
    }
  }
}