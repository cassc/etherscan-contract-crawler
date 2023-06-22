/**
 *Submitted for verification at Etherscan.io on 2023-06-20
*/

// SPDX-License-Identifier: MIT

/*

 /$$$$$$$$ /$$$$$$   /$$$$$$  /$$$$$$$$
| $$_____//$$__  $$ /$$__  $$|__  $$__/
| $$     | $$  \ $$| $$  \__/   | $$
| $$$$$  | $$$$$$$$|  $$$$$$    | $$
| $$__/  | $$__  $$ \____  $$   | $$
| $$     | $$  | $$ /$$  \ $$   | $$
| $$     | $$  | $$|  $$$$$$/   | $$
|__/     |__/  |__/ \______/    |__/

  /$$$$$$   /$$$$$$   /$$$$$$  /$$   /$$
 /$$__  $$ /$$__  $$ /$$__  $$| $$  | $$
| $$  \__/| $$  \ $$| $$  \__/| $$  | $$
| $$      | $$$$$$$$|  $$$$$$ | $$$$$$$$
| $$      | $$__  $$ \____  $$| $$__  $$
| $$    $$| $$  | $$ /$$  \ $$| $$  | $$
|  $$$$$$/| $$  | $$|  $$$$$$/| $$  | $$
 \______/ |__/  |__/ \______/ |__/  |__/

 /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$  /$$      /$$ /$$$$$$ /$$   /$$ /$$$$$$$$
| $$__  $$ /$$__  $$| $$__  $$ /$$__  $$| $$$    /$$$|_  $$_/| $$$ | $$| $$_____/
| $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$| $$$$  /$$$$  | $$  | $$$$| $$| $$
| $$  | $$| $$  | $$| $$$$$$$/| $$$$$$$$| $$ $$/$$ $$  | $$  | $$ $$ $$| $$$$$
| $$  | $$| $$  | $$| $$____/ | $$__  $$| $$  $$$| $$  | $$  | $$  $$$$| $$__/
| $$  | $$| $$  | $$| $$      | $$  | $$| $$\  $ | $$  | $$  | $$\  $$$| $$
| $$$$$$$/|  $$$$$$/| $$      | $$  | $$| $$ \/  | $$ /$$$$$$| $$ \  $$| $$$$$$$$
|_______/  \______/ |__/      |__/  |__/|__/     |__/|______/|__/  \__/|________/

 /$$    /$$  /$$$$$$  /$$   /$$ /$$    /$$$$$$$$
| $$   | $$ /$$__  $$| $$  | $$| $$   |__  $$__/
| $$   | $$| $$  \ $$| $$  | $$| $$      | $$
|  $$ / $$/| $$$$$$$$| $$  | $$| $$      | $$
 \  $$ $$/ | $$__  $$| $$  | $$| $$      | $$
  \  $$$/  | $$  | $$| $$  | $$| $$      | $$
   \  $/   | $$  | $$|  $$$$$$/| $$$$$$$$| $$
    \_/    |__/  |__/ \______/ |________/|__/

contract by steviep.eth

*/

pragma solidity ^0.8.17;


interface IFastCashMoneyPlus {
  function transfer(address, uint256) external;
}

interface IDopamineMachines {
  function tokenIdToProjectId(uint256) external view returns (uint256);
  function ownerOf(uint256) external view returns (address);
}

contract FastCashDopamineVault {
  IFastCashMoneyPlus public constant FastCashContract = IFastCashMoneyPlus(0xcA5228D1fe52D22db85E02CA305cddD9E573D752);
  IDopamineMachines public constant DopamineMachineContract = IDopamineMachines(0x99a9B7c1116f9ceEB1652de04d5969CcE509B069);

  mapping(uint256 => bool) public redemptions;

  function redeem(uint256 tokenId) external {
    require(DopamineMachineContract.tokenIdToProjectId(tokenId) == 457, 'Token must be a Dopamine Machine');
    require(DopamineMachineContract.ownerOf(tokenId) == msg.sender, 'Only owner can redeem for FastCash');
    require(!redemptions[tokenId], 'FastCash has already been redeemed');

    redemptions[tokenId] = true;

    FastCashContract.transfer(msg.sender, 1000000000000000000);
  }
}