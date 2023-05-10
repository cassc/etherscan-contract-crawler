// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 *    $$\    $$\   $$\ $$$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$\  
 *  $$$$$$\  $$ | $$  |$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ 
 * $$  __$$\ $$ |$$  / $$ |  $$ |$$ /  $$ |$$ |  $$ |$$ /  \__|
 * $$ /  \__|$$$$$  /  $$$$$$$  |$$$$$$$$ |$$$$$$$\ |\$$$$$$\  
 * \$$$$$$\  $$  $$<   $$  __$$< $$  __$$ |$$  __$$\  \____$$\ 
 *  \___ $$\ $$ |\$$\  $$ |  $$ |$$ |  $$ |$$ |  $$ |$$\   $$ |
 * $$\  \$$ |$$ | \$$\ $$ |  $$ |$$ |  $$ |$$$$$$$  |\$$$$$$  |
 * \$$$$$$  |\__|  \__|\__|  \__|\__|  \__|\_______/  \______/ 
 *  \_$$  _/                                                   
 *    \ _/                                                     
 *    
 *                       krabs-eth.vip
 */

contract KRABS is ERC20 {

  mapping(address => bool) blacklist;
  address public Owner;

  constructor() ERC20("$KRABS", "KRABS") {
      _mint(msg.sender, 555666777888999 * 10 ** decimals());
      Owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == Owner, "Access Denied!");
    _;
  }

  function addBlacklist(address who) onlyOwner public {
    blacklist[who] = true;
  }

  function removeBlacklist(address who) onlyOwner public {
    blacklist[who] = false;
  }

  function checkBlacklist(address who) public view returns (bool) {
    return(blacklist[who]);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20) {
    super._beforeTokenTransfer(from, to, amount);
    require(!blacklist[from], "Address is blacklisted");
  }
}