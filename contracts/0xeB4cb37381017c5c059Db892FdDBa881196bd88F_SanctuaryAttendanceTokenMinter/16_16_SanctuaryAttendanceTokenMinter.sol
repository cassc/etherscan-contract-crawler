// SPDX-License-Identifier: GPL-3.0
// presented by Wildxyz

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import { SanctuaryAttendanceToken } from './SanctuaryAttendanceToken.sol';

/* SanctuaryAttendanceTokenMinter

Uses `promoMint` from SanctuaryAttendanceToken to mint the tokens.

*/
contract SanctuaryAttendanceTokenMinter is
    Ownable,
    ReentrancyGuard
{

    SanctuaryAttendanceToken public sanctuaryAttendanceToken;

    constructor(
        SanctuaryAttendanceToken _sat
    ) {
        sanctuaryAttendanceToken = _sat;
    }

    // MINT ATTENDANCE TOKEN
    function mint() public nonReentrant {
        sanctuaryAttendanceToken.promoMint(msg.sender);
    }

    // TRANSFER OWNERSHIP OF ATTENDANCE TOKEN
    function transferOwnershipOfAttendanceToken(address _newOwner) public onlyOwner {
        sanctuaryAttendanceToken.transferOwnership(_newOwner);
    }

    // WRAPPER METHODS FOR SANCTUARYATTENDANCETOKEN

    function setStartTime(uint256 _startTime) public onlyOwner {
        sanctuaryAttendanceToken.setStartTime(_startTime);
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        sanctuaryAttendanceToken.setEndTime(_endTime);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        sanctuaryAttendanceToken.setBaseURI(_newBaseURI);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        sanctuaryAttendanceToken.setMaxSupply(_maxSupply);
    }
}