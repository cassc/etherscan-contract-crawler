/**
 *Submitted for verification at Etherscan.io on 2023-07-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract ProfitSubscription{

    address private owner;
    uint256 public price;
    string public name;

    mapping(uint256 => uint256) public discordServerSubscriptions; 

    constructor(){
        owner = msg.sender;
        price = 100000000000000000;
        name = "3gm Profit @3gmdev";
    }

    function purchaseProfit3gm(uint256 discordServerID, uint256 months) external payable{
        // Checks payment
        if(msg.value < price * months) revert("Incorrect payment");

        // Handling subscription time
        if(discordServerSubscriptions[discordServerID] > block.timestamp){
            discordServerSubscriptions[discordServerID] += months * 2592000;
        }
        else{
            discordServerSubscriptions[discordServerID] = block.timestamp + months * 2592000;
        }

        // ETH transfer to 3gm
        (bool sent, ) = owner.call{value: msg.value}("");
        if(!sent) revert();
    }

    function adminEdit(uint256[] calldata discordServerIDs, uint256[] calldata timestamps) external{
        if(msg.sender != owner) revert();

        for(uint256 i; i < discordServerIDs.length;){
            discordServerSubscriptions[discordServerIDs[i]] = timestamps[i];
            unchecked{
                i++;
            }
        }
    }

    function changePrice(uint256 newPrice) external{
        if(msg.sender != owner) revert();

        price = newPrice;
    }

    function getDiscordServerSubscriptions(uint256[] memory discordServerIDs) public view returns (uint256[] memory){
        for(uint256 i; i < discordServerIDs.length;){
            discordServerIDs[i] = discordServerSubscriptions[discordServerIDs[i]];
            unchecked{
                i++;
            }
        }
        return discordServerIDs;
    }
}