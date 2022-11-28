// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract HyperMoveUpgradeable is
  Initializable,
  ERC20Upgradeable,
  OwnableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20VotesUpgradeable
{
  /// @notice Initialize The Hypermove Token Contract
  function initialize() public initializer {
    __ERC20_init("HyperMove", "HMove");
    __Ownable_init();
    __ERC20Permit_init("HMove");
    __ERC20Votes_init();

    _mint(msg.sender, 1000000000 * 10**decimals());
  }

  /// @inheritdoc ERC20Upgradeable
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    super._beforeTokenTransfer(from, to, amount);
  }

  /// @inheritdoc ERC20Upgradeable
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._afterTokenTransfer(from, to, amount);
  }

  /// @inheritdoc ERC20Upgradeable
  function _mint(address to, uint256 amount)
    internal
    override(ERC20Upgradeable, ERC20VotesUpgradeable)
  {
    super._mint(to, amount);
  }

  /// @inheritdoc ERC20Upgradeable
  function _burn(address account, uint256 amount)
    internal
    override(ERC20Upgradeable, ERC20VotesUpgradeable)
  {
    super._burn(account, amount);
  }

  function mint(address account, uint256 amount) external onlyOwner {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external onlyOwner {
    _burn(account, amount);
  }
}