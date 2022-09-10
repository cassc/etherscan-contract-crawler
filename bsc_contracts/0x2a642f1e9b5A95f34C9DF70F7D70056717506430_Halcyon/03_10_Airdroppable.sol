// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "../vendor/@openzeppelin/contracts/access/Ownable.sol";

abstract contract AirDroppable is Ownable
{
  mapping(address => uint256) internal _airdrops;
  address[] internal _accounts;
  bool internal _airdropEnabled;
  uint256 internal _distributedAirdrops;
  
  event AirDrop(uint256 amount, address[] accounts);
  event SwitchAirDrop(bool status);
  
  
  /**
   * @dev
   *
   * - abstract, implementation in base contract
   */
  function sendAirDrops() external virtual;
  
  
  function switchAirDrop(bool mode) external onlyOwner
  {
    require(mode != _airdropEnabled, "AirDrop mode already set.");
    
    _airdropEnabled = mode;
    emit SwitchAirDrop(_airdropEnabled);
  }
  
  
  function setAirDrop(address[] memory accounts, uint256 amount) external onlyOwner
  {
    for (uint256 i = 0; i < accounts.length; i++)
    {
      address account = accounts[i];
      
      _airdrops[account] += amount;
      _accounts.push(account);
    }
    
    emit AirDrop(amount, accounts);
  }
  
  
  function unsetAirDrop(address account) external onlyOwner
  {
    _airdrops[account] = 0;
    
    address[] memory accounts = new address[](1);
    accounts[0] = account;
    
    emit AirDrop(0, accounts);
  }
  
  
  function getDistributedAirDrops() external view returns (uint256)
  {
    return _distributedAirdrops;
  }
}