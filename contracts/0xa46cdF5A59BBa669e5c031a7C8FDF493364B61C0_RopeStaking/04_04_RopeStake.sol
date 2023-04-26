// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
    _     _______  _______  _______  _______  _______  _______  _______  _______ 
 __|_|___(  ____ \(  ___  )(  ____ )(  ____ \(  ____ )(  ___  )(  ____ )(  ____ \
(  _____/| (    \/| (   ) || (    )|| (    \/| (    )|| (   ) || (    )|| (    \/
| (|_|__ | |      | |   | || (____)|| (__    | (____)|| |   | || (____)|| (__    
(_____  )| |      | |   | ||  _____)|  __)   |     __)| |   | ||  _____)|  __)   
/\_|_|) || |      | |   | || (      | (      | (\ (   | |   | || (      | (      
\_______)| (____/\| (___) || )      | (____/\| ) \ \__| (___) || )      | (____/\
   |_|   (_______/(_______)|/       (_______/|/   \__/(_______)|/       (_______/
                                                                                 
                                             

************************************************
*                                              *
*                  Cope Rope                   *
*       https://twitter.com/coperopenft        *
*                                              *
*                                              *
************************************************

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RopeStaking is Ownable{
    mapping(uint256 => uint256) private staked;
    mapping(uint256 => uint256) private tokensEmitted;
    mapping(uint256 => uint256) private lastClaimed;

    address private ropeContract;
    IERC20 private copeToken;

    constructor(){}

    modifier onlyRopeContract {
        require(msg.sender == ropeContract, "Only rope contract can call this method");
        _;
    }

    function changeRopeContract(address _ropeContract) external onlyOwner{
        ropeContract = _ropeContract;
    }

    function changeCopeTokenContract(address _copeTokenContract) external onlyOwner {
        copeToken = IERC20(_copeTokenContract);
    }

    function isStaked(uint256 tokenId) external view returns(bool){
        // If above 0, then its currently staked
        return staked[tokenId] > 0;
    }

    function getStakeTime(uint256 tokenId) external view returns(uint256){
        return block.timestamp - staked[tokenId];
    }

    function stake(uint256 tokenId) external onlyRopeContract {
        require(staked[tokenId] == 0, "Already coping");
        staked[tokenId] = block.timestamp;
        lastClaimed[tokenId] = block.timestamp;
    }

    function unstake(uint256 tokenId) external onlyRopeContract {
        uint256 stakedTime = staked[tokenId];
        require(stakedTime != 0, "Rope not copping");
        require(block.timestamp - stakedTime > 259200, "Minimum 3 day stake");

        uint256 tokenReward = (16198 * (10**15)) * (block.timestamp - lastClaimed[tokenId]);

        // tokensRemaining < tokenReward
        if((13999999 * (10**18)) - tokensEmitted[tokenId] < tokenReward){
            // tokenReward = tokensRemaining
            tokenReward = (13999999 * (10**18)) - tokensEmitted[tokenId];
        }

        // cap tokenReward
        if(tokenReward > (13999999 * (10**18))){
            tokenReward = (13999999 * (10**18));
        }

        tokensEmitted[tokenId] += tokenReward;
        copeToken.transfer(tx.origin, tokenReward);

        lastClaimed[tokenId] = 0;
        staked[tokenId] = 0;
    }

    function claimReward() external onlyRopeContract {
        copeToken.transfer(tx.origin, 5999999 * (10**18));
    }

    function claim(uint256 tokenId) external onlyRopeContract {
        require(block.timestamp - lastClaimed[tokenId] > 86400, "24 hours required between cope");
        uint256 stakedTime = staked[tokenId];

        uint256 tokenReward = (16198 * (10**15)) * (block.timestamp - lastClaimed[tokenId]);

        // tokensRemaining < tokenReward
        if((13999999 * (10**18)) - tokensEmitted[tokenId] < tokenReward){
            // tokenReward = tokensRemaining
            tokenReward = (13999999 * (10**18)) - tokensEmitted[tokenId];
        }

        // cap tokenReward
        if(tokenReward > (13999999 * (10**18))){
            tokenReward = (13999999 * (10**18));
        }

        tokensEmitted[tokenId] += tokenReward;
        copeToken.transfer(tx.origin, tokenReward);

        lastClaimed[tokenId] = block.timestamp;
    }
}