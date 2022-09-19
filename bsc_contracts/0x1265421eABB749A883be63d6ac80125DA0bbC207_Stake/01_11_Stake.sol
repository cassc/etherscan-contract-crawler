// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Interfaces.sol";

contract Stake is AccessControl {
  // roles
  bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("");

  address public _GPCAddr;
  // events
  event ValueReceived(address user, uint amount);
  event WithDrawn(address user, uint amount);
  event GPCMinted(address user, uint amount);
  // mappings and owner
  mapping(address => uint256) public funds;
  address[] public funders;
  address payable owner;

  constructor(address GPCAddr) {
    _setRoleAdmin(WITHDRAW_ROLE, ADMIN_ROLE);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(WITHDRAW_ROLE, msg.sender);
    owner = payable(msg.sender);
    _GPCAddr = GPCAddr;
  }

  function withdraw_all() public onlyRole(WITHDRAW_ROLE) {
    uint amount = address(this).balance;
    payable(msg.sender).transfer(amount);
    emit WithDrawn(msg.sender, amount);
  }

  function withdraw(uint256 amount) public onlyRole(WITHDRAW_ROLE) {
    payable(msg.sender).transfer(amount);
    emit WithDrawn(msg.sender, amount);
  }

  function funders_len() public view returns (uint) {
    return funders.length;
  }

  function total_funds() public view returns (uint256) {
    uint256 funds_in_total = 0;
    uint i;
    for(i=0; i<funders.length; i++) {
      funds_in_total += funds[funders[i]];
    }

    return funds_in_total;
  }

  function balance() public view returns (uint256) {
    return  address(this).balance;
  }
  function addWithDrawer(address withDrawer) public onlyRole(ADMIN_ROLE) {
    grantRole(WITHDRAW_ROLE, withDrawer);
  }
  function revokeWithDrawer(address withDrawer) public onlyRole(ADMIN_ROLE) {
    revokeRole(WITHDRAW_ROLE, withDrawer);
  }

  receive() external payable {
    require(msg.value > 0.01 ether && funds[msg.sender] + msg.value < 100 ether, "invest out of range");
    funders.push(msg.sender);
    funds[msg.sender] += msg.value;
    
    emit ValueReceived(msg.sender, msg.value);

    uint gpcMintAmount = 1040 * msg.value / 1000000000000000000;
    IGPCToken(_GPCAddr).dispense(msg.sender, gpcMintAmount);

    emit GPCMinted(msg.sender, gpcMintAmount);
  }
}