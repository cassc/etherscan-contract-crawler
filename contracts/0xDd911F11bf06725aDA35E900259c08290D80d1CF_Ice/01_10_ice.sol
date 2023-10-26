// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Ice is ERC20, Ownable {
  using SafeERC20 for ERC20;

  constructor() ERC20("Ice Coin", "ICE") {}

  uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18;

  mapping(address => bool) public blacklists;
  bool public blacklistState;
  bool public whitelistState;
  mapping(address => bool) public whitelist;

  function mint(address to, uint256 amount) public onlyOwner {
    require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
    _mint(to, amount);
  }

  function setBlacklistsState(bool state) external onlyOwner {
    blacklistState = state;
  }

  function setWhitelistState(bool state) external onlyOwner {
    whitelistState = state;
  }

  function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
    blacklists[_address] = _isBlacklisting;
  }

  function setWhitelist(address[] memory _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = true;
    }
  }

  function removeFromWhitelist(address[] memory _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      whitelist[_addresses[i]] = false;
    }
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    if (blacklistState) {
      require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }
    if (whitelistState) {
      require(whitelist[to], "Not whitelisted");
    }
    super._beforeTokenTransfer(from, to, amount);
  }

  function burn(uint256 value) external {
    _burn(msg.sender, value);
  }
}