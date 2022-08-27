// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/* 
     (             *        )      )     )           (                 
     )\ )        (  `    ( /(   ( /(  ( /(   (       )\ )              
    (()/(   (    )\))(   )\())  )\()) )\())  )\ )   (()/( (   (   (    
     /(_))  )\  ((_)()\ ((_)\  ((_)\ ((_)\  (()/(    /(_)))\  )\  )\   
    (_))_  ((_) (_()((_)  ((_)  _((_) _((_)  /(_))_ (_)) ((_)((_)((_)  
     |   \ | __||  \/  | / _ \ | \| ||_  /  (_)) __||_ _|\ \ / / | __| 
     | |) || _| | |\/| || (_) || .` | / /     | (_ | | |  \ V /  | _|  
     |___/ |___||_|  |_| \___/ |_|\_|/___|     \___||___|  \_/   |___| 

    Lil Demonz Giveaway All Rights Reserved 2022
    Developed by ATOMICON.PRO ([email protected])
*/

import "@openzeppelin/contracts/access/Ownable.sol";

contract LilDemonzGiveaway is Ownable {
    
    uint16 constant public DEMONZ_COUNT = 1490;

    /// @notice Giveaway funds to a list of DEMONZ holders
    function giveaway(address[] memory demonzHolders, uint16[] memory demonzCount) external onlyOwner {
        require(demonzHolders.length == demonzCount.length, "Arrays of holders and tokens count should have the same length");

        uint256 sumPerHolder = getCurrentRewardPerHolder();
        uint16 totalDemonzCount = 0;

        for(uint index = 0; index < demonzHolders.length; index++) {
            payable(demonzHolders[index]).transfer(sumPerHolder * demonzCount[index]);
            totalDemonzCount += demonzCount[index];   
        }

        require(totalDemonzCount == DEMONZ_COUNT, "There should be exactly 1490 DEMONZ holders specified");
    }

    /// @notice Get current reward based on the treasure pool
    function getCurrentRewardPerHolder() public view returns(uint256) {
        return address(this).balance / DEMONZ_COUNT;
    }

    /// @dev Recieve any amount of ether
    receive() external payable {}
}