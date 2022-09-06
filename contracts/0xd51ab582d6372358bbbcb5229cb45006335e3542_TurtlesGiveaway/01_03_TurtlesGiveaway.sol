// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/* 
    Turtles Giveaway All Rights Reserved 2022
    Developed by ATOMICON.PRO ([email protected])
*/

import "@openzeppelin/contracts/access/Ownable.sol";

contract TurtlesGiveaway is Ownable {
    
    /// @notice Giveaway funds to a list of accounts
    function giveaway(address[] memory wallets) external onlyOwner {
        uint256 sumPerWallet = getCurrentRewardPerWallet(wallets.length);

        for(uint index = 0; index < wallets.length; index++) {
            payable(wallets[index]).transfer(sumPerWallet);        
        }
    }

    /// @notice Get current reward based on the treasure pool
    function getCurrentRewardPerWallet(uint walletsCount) public view returns(uint256) {
        return address(this).balance / walletsCount;
    }

    /// @dev Recieve any amount of ether
    receive() external payable {}
}