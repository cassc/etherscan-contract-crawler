//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AniftyERC20 is ERC20, Ownable {
  using SafeMath for uint256;
  mapping(address => bool) public whitelist;

  constructor(uint256 initialSupply) public ERC20("Anifty", "ANI") { 
    _mint(msg.sender, initialSupply*10**decimals());
  }

  function burn(uint256 _amount) public {
    _burn(msg.sender, _amount);
  }

  function burn(address _account, uint256 _amount) public onlyWhitelist {
    _burn(_account, _amount);
  }

  function removeWhitelistAddress(address[] memory _whitelistAddresses) public onlyOwner {
    for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
    whitelist[_whitelistAddresses[i]] = false;
    }
  }

  function addWhitelistAddress(address[] memory _whitelistAddresses) public onlyOwner {
    for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
    whitelist[_whitelistAddresses[i]] = true;
    }
  }

  // Only whitelist can burn, e.g Anifty Lootbox contract
  modifier onlyWhitelist() {
    require(whitelist[msg.sender] == true, "Caller is not from a whitelist address");
    _;
  }
}