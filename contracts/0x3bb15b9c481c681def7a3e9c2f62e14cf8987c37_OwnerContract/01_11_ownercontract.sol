//SPDX-License-Identifier: Unlicense

/*

OpenSea can eat my ass

 __   __  __   __  ______    _______  ___  
|  | |  ||  | |  ||    _ |  |       ||   | 
|  |_|  ||  | |  ||   | ||  |    ___||   | 
|       ||  |_|  ||   |_||_ |   |___ |   | 
|_     _||       ||    __  ||    ___||   | 
  |   |  |       ||   |  | ||   |___ |   | 
  |___|  |_______||___|  |_||_______||___| 


*/

pragma solidity ^0.8.15;

import "./DayNight.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Contract that will own YureiDayAndNight
contract OwnerContract is Ownable {
    YureiDayAndNight yurei;

    constructor(address _yureiAddress) public {
        yurei = YureiDayAndNight(_yureiAddress);
    }

    function MakeMeOwner() onlyOwner public {

        yurei.transferOwnership(msg.sender);

    }
    function ClaimDaynNight() public {
        yurei.batchMint(1, msg.sender, 1);
    }
}