// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IERC20Singleton.sol";

contract ERC20Singleton is
  IERC20Singleton,
  Initializable,
  ERC20Upgradeable,
  OwnableUpgradeable
{
  error MaxSupplyReached();

  uint256 maxSupply;

  constructor() initializer {
    __ERC20_init("Singleton Base", "BASE");
    __Ownable_init();
    maxSupply = 1 ether;
    transferOwnership(address(1));
  }

  function initialize(
    bytes calldata _name,
    bytes calldata _symbol,
    uint256 _maxSupply,
    address _owner,
    address _preMintDestination,
    uint256 _preMintAmount
  ) external initializer {
    if (_preMintAmount > _maxSupply) {
      revert MaxSupplyReached();
    }
    if (_preMintAmount > 0) {
      _mint(_preMintDestination, _preMintAmount);
    }
    __ERC20_init(string(_name), string(_symbol));
    __Ownable_init();
    maxSupply = _maxSupply;
    transferOwnership(_owner);
  }

  function mint(address account, uint256 amount) external override onlyOwner {
    if (this.totalSupply() + amount > maxSupply) {
      revert MaxSupplyReached();
    }
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external override onlyOwner {
    _burn(account, amount);
  }
}