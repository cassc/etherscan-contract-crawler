// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/*
   _____                      ___          __   _ _      _   
  / ____|                    | \ \        / /  | | |    | |  
 | (___  _ __ ___   __ _ _ __| |\ \  /\  / /_ _| | | ___| |_ 
  \___ \| '_ ` _ \ / _` | '__| __\ \/  \/ / _` | | |/ _ \ __|
  ____) | | | | | | (_| | |  | |_ \  /\  / (_| | | |  __/ |_ 
 |_____/|_| |_| |_|\__,_|_|   \__| \/  \/ \__,_|_|_|\___|\__|

*/ 


import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';



abstract contract Administrable is Context, Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;
  event GrantedAdminRole(address indexed newAdmin);
  event RevokedAdminRole(address indexed oldAdmin);

  EnumerableSet.AddressSet private _admins;
  
  modifier onlyAdmin() {
    require(_msgSender() == owner() || _admins.contains(_msgSender()), 'Administrable: caller is not an administrator or the owner');
    _;
  }

  function admins() public view returns (address[] memory) { 
    return _admins.values();
  }

  function grantAdminRole(address newAdmin) external onlyOwner {
    _grantAdminRole(newAdmin);
  }

  function revokeAdminRole(address oldAdmin) external onlyOwner {
    _revokeAdminRole(oldAdmin);
  }

  function _grantAdminRole(address newAdmin) internal {
    require(newAdmin != address(0), 'Administrable: grant to the zero address');
    _admins.add(newAdmin);
    emit GrantedAdminRole(newAdmin);
  }

  function _revokeAdminRole(address oldAdmin) internal {
    require(oldAdmin != address(0), 'Administrable: revoke to the zero address');
    _admins.remove(oldAdmin);
    emit RevokedAdminRole(oldAdmin);
  }
}