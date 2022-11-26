// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";


contract TeamsAccess is Ownable {
   event SetAccess(address member, bool enable);

   mapping(address => bool) private teamMember;

   modifier onlyTeam() {
      require(teamMember[msg.sender], "Caller is not the Team");
   _;
   }

   //add team user
   function setAccess(address member ,bool enable) public onlyOwner {
      teamMember[member] = enable;
      emit SetAccess(member, enable);
   }

}