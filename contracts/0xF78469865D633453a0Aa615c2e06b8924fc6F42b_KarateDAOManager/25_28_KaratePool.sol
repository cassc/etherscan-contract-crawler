//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./Signatures.sol";

contract KaratePool {

   bool private allowanceSet;
   IERC20 private token;
   Ownable private storageContract;

   constructor(address tokenAddress, address storageContractAddress) {
       token = IERC20(tokenAddress);
       storageContract = Ownable(storageContractAddress);
   }

   function daoContract() internal view returns (address owner) {
       return storageContract.owner();
   }

   function createAllowance(address claimContract) external {
       require(msg.sender == daoContract(), 'Only active DAO contract can call');
       require(!allowanceSet, "Allowance already set");
       token.approve(claimContract, token.balanceOf(address(this)));
       allowanceSet = true;
   }
}