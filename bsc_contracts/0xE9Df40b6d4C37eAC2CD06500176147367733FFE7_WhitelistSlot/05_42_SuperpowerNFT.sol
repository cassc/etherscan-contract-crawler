// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Inspired by Everdragons2 NFTs, https://everdragons2.com
// Authors: Francesco Sullo <[email protected]>
// (c) Superpower Labs Inc.

import "./SuperpowerNFTBase.sol";
import "./interfaces/ISuperpowerNFT.sol";
import "./WhitelistSlot.sol";

//import "hardhat/console.sol";

abstract contract SuperpowerNFT is ISuperpowerNFT, SuperpowerNFTBase {
  error Forbidden();
  error CannotMint();
  error ZeroAddress();
  error InvalidSupply();
  error NotEnoughWLSlots();
  error InvalidDeadline();
  error WhitelistNotSetYet();

  using AddressUpgradeable for address;
  uint256 internal _nextTokenId;
  uint256 internal _maxSupply;
  bool internal _mintEnded;

  address[] public factories;

  address public defaultPlayer;

  modifier onlyFactory() {
    if (
      isFactory(_msgSender()) ||
      // owner is authorized as long as there are no factories
      (!hasFactories() && _msgSender() == owner())
    ) _;
    else revert Forbidden();
  }

  modifier canMint(uint256 amount) {
    if (!canMintAmount(amount)) revert CannotMint();
    _;
  }

  function setDefaultPlayer(address player) external onlyOwner {
    if (!player.isContract()) revert NotAContract();
    defaultPlayer = player;
  }

  function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    if (_nextTokenId == 0) {
      _nextTokenId = 1;
    }
    if (_nextTokenId > maxSupply_) revert InvalidSupply();
    _maxSupply = maxSupply_;
  }

  function setFactory(address factory_, bool enabled) external override onlyOwner {
    if (!factory_.isContract()) revert NotAContract();
    if (enabled) {
      if (!isFactory(factory_)) {
        factories.push(factory_);
      }
    } else {
      if (isFactory(factory_)) {
        for (uint256 i = 0; i < factories.length; i++) {
          if (factories[i] == factory_) {
            factories[i] = address(0);
          }
        }
      }
    }
  }

  function isFactory(address factory_) public view returns (bool) {
    for (uint256 i = 0; i < factories.length; i++) {
      if (factories[i] != address(0)) {
        if (factories[i] == factory_) {
          return true;
        }
      }
    }
    return false;
  }

  function hasFactories() public view returns (bool) {
    for (uint256 i = 0; i < factories.length; i++) {
      if (factories[i] != address(0)) {
        return true;
      }
    }
    return false;
  }

  function canMintAmount(uint256 amount) public view returns (bool) {
    return _nextTokenId > 0 && !_mintEnded && _nextTokenId + amount < _maxSupply + 2;
  }

  function mint(address to, uint256 amount) external virtual override onlyFactory canMint(amount) {
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _nextTokenId++);
    }
  }

  function endMinting() external override onlyOwner {
    _mintEnded = true;
  }

  function mintEnded() external view override returns (bool) {
    return _mintEnded;
  }

  function maxSupply() external view override returns (uint256) {
    return _maxSupply;
  }

  function nextTokenId() external view override returns (uint256) {
    return _nextTokenId;
  }
}