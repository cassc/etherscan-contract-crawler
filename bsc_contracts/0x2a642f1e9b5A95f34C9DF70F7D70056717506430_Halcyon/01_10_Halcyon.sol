/*
██   ██  █████  ██       ██████ ██    ██  ██████  ███    ██
██   ██ ██   ██ ██      ██       ██  ██  ██    ██ ████   ██
███████ ███████ ██      ██        ████   ██    ██ ██ ██  ██
██   ██ ██   ██ ██      ██         ██    ██    ██ ██  ██ ██
██   ██ ██   ██ ███████  ██████    ██     ██████  ██   ████

LOYALTY   PROPERITY   CARE

https://halcyoninitiative.com
https://t.me/HalcyonInitiative official chat
https://t.me/halcyontoken announcements
https://t.me/HalcyonInitiativeSupport (app support)
https://t.me/HalcyonCCbot (token checker service)
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "../features/Deflationary.sol";
import "../features/Airdroppable.sol";

contract Halcyon is Deflationary, AirDroppable
{
  string constant NAME_ = "Halcyon Initiative";
  string constant SYMBOL_ = "HALCYON";
  uint256 constant DECIMALS_ = 18;
  uint256 constant TOKENSUPPLY_ = 10 ** 9;
  
  
  constructor() ERC20(NAME_, SYMBOL_, DECIMALS_, TOKENSUPPLY_)
  {
    ERC20._mint(_msgSender(), ERC20.totalSupply());
  }
  
  
  function sendAirDrops() external override onlyOwner
  {
    require(_airdropEnabled, "AirDrops are disabled.");
    
    address marketingVault = getVaultByName("Marketing").wallet;
    require(marketingVault != address(0), "Marketing Vault not set.");
    require(ERC20.balanceOf(marketingVault) > 0, "AirDrops are depleted.");
    
    for (uint256 i = 0; i < _accounts.length;)
    {
      address account = _accounts[i];
      
      uint256 amount = _airdrops[account];
      
      if (amount > 0)
      {
        _distributedAirdrops += amount;
        _airdrops[account] = 0;
        
        ERC20._transfer(marketingVault, account, amount);
      }
      
      _accounts[i] = _accounts[_accounts.length - 1];
      _accounts.pop();
    }
  }
}