/***
 *    ███╗   ███╗ █████╗ ██╗  ██╗███████╗██╗      ██████╗ ██╗    ██╗
 *    ████╗ ████║██╔══██╗╚██╗██╔╝██╔════╝██║     ██╔═══██╗██║    ██║
 *    ██╔████╔██║███████║ ╚███╔╝ █████╗  ██║     ██║   ██║██║ █╗ ██║
 *    ██║╚██╔╝██║██╔══██║ ██╔██╗ ██╔══╝  ██║     ██║   ██║██║███╗██║
 *    ██║ ╚═╝ ██║██║  ██║██╔╝ ██╗██║     ███████╗╚██████╔╝╚███╔███╔╝
 *    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ 
 *                                                                  
 *     █████╗  ██████╗ ██████╗███████╗███████╗███████╗              
 *    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝              
 *    ███████║██║     ██║     █████╗  ███████╗███████╗              
 *    ██╔══██║██║     ██║     ██╔══╝  ╚════██║╚════██║              
 *    ██║  ██║╚██████╗╚██████╗███████╗███████║███████║              
 *    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝              
 *                                                                  
 *     ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗      
 *    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║      
 *    ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║      
 *    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║      
 *    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗ 
 *     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝ 
 * @title MaxFlowO2 Access Control
 * @author @MaxFlowO2 on twitter/github
 * @dev this is an EIP 173 compliant ownable plus access control mechanism where you can 
 * copy/paste what access role(s) you need or want. This is due to Library Access, and 
 * using this line of 'using Role for Access.Role' after importing my library
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../lib/Access.sol";
import "../utils/ContextV2.sol";

abstract contract MaxAccess is ContextV2 {
  using Access for Access.Role;

  // events

  // Roles  
  Access.Role private _owner;
  Access.Role private _developer;

  // Constructor to init()
  constructor() {
    _owner.push(_msgSender());
    _developer.push(_msgSender());
  }

  // Modifiers
  modifier onlyOwner() {
    require(_owner.active() == _msgSender(), "EIP173: You are not Owner!");
    _;
  }

  modifier onlyNewOwner() {
    require(_owner.pending() == _msgSender(), "EIP173: You are not the Pending Owner!");
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner.active();
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "EIP173: Transfer can not be address(0)");
    _owner.transfer(newOwner);
  }

  function acceptOwnership() public virtual onlyNewOwner {
    _owner.accept();
  }

  function declineOwnership() public virtual onlyNewOwner {
    _owner.decline();
  }

  function pushOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "EIP173: Transfer can not be address(0)");
    _owner.push(newOwner);
  }

  function renounceOwnership() public virtual onlyOwner {
    _owner.push(address(0));
  }

  // Modifiers
  modifier onlyDeveloper() {
    require(_developer.active() == _msgSender(), "EIP173: You are not Developer!");
    _;
  }

  modifier onlyNewDeveloper() {
    require(_developer.pending() == _msgSender(), "EIP173: You are not the Pending Developer!");
    _;
  }

  function developer() public view virtual returns (address) {
    return _developer.active();
  }

  function transferDeveloper(address newDeveloper) public virtual onlyDeveloper {
    require(newDeveloper != address(0), "EIP173: Transfer can not be address(0)");
    _developer.transfer(newDeveloper);
  }

  function acceptDeveloper() public virtual onlyNewDeveloper {
    _developer.accept();
  }

  function declineDeveloper() public virtual onlyNewDeveloper {
    _developer.decline();
  }

  function pushDeveloper(address newDeveloper) public virtual onlyDeveloper {
    require(newDeveloper != address(0), "EIP173: Transfer can not be address(0)");
    _developer.push(newDeveloper);
  }

  function renounceDeveloper() public virtual onlyDeveloper {
    _developer.push(address(0));
  }
}