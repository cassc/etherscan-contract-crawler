// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ISmartChefInitializable} from "../interfaces/ISmartChefInitializable.sol";

/**
 * @title FireCat's FireCatTriggerStorage contract
 * @notice main: 
 * @author FireCat Finance
 */
contract FireCatTriggerStorage {
    IERC20 cakeToken;
    ISmartChefInitializable smartChef;
    
    address public fireCatRegistry;
    address public fireCatNFT;
    address public fireCatIssuePool;
    address public fireCatGate;
    address public fireCatReserves;
    address public swapRouter;

    uint256 public totalFunds;  // redeem funds from mining pools
    uint256 public totalInvest;  // reinvest funds to mining pools

    address public stakeToken;
    uint256 public totalStaked;  // cake total staked amount
    uint256 public totalClaimed;
    uint256 public rewardPerTokenStored;
    mapping(uint256 => uint256) public staked;
    mapping(uint256 => uint256) public claimed;
    mapping(uint256 => uint256) public userOwnRewardPerToken;

    // fee or share factor config
    uint256 public exitFeeFacotr;
    uint256 public reservesShareFactor;
    uint256 public inviterShareFactor;

    // mining pools config 
    uint256[] public weightsArray;
    address[] public smartChefArray;

    // swap router
    mapping(address => address[]) public swapPath;
    

    
}