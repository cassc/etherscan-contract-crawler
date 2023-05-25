// SPDX-License-Identifier: MIT
//
// ...............   ...............   ...............  .....   ...............
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// :==============.  ===============  :==============:  -====  .==============-
// .::::-====-::::.  ===============  :====-:::::::::.  -====  .====-::::-====-
//      :====.       ===============  :====:            -====  .====:    .====-
//      :====.       ===============  :====:            -====  .====:    .====-
//
// Learn more at https://topia.gg or Twitter @TOPIAgg

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TOPIAToken is ERC20, ERC20Capped, Ownable {
  constructor()
  ERC20("TOPIA", "TOPIA")
  ERC20Capped(5000000000 ether) {}

  function mint(address _to, uint256 _amount) external onlyOwner {
    _mint(_to, _amount);
  }

  /**
   * Overrides
   */

  function _mint(address _to, uint256 _amount) internal override(ERC20, ERC20Capped) {
    super._mint(_to, _amount);
  }
}