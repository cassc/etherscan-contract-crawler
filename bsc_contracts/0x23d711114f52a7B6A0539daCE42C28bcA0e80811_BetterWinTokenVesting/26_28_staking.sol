// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
contract StakingAPY is Pausable, Ownable {
   
    IERC20 public erc20token  ;
    //declaring default APY (default 0.1% daily or 36.5% APY yearly)
    uint256 public APY = 100;

   

    //declaring total staked
    uint256 public totalStaked;

    //users staking balance
    mapping(address => uint256) public stakingBalance;

    mapping(address => bool) public hasStaked;

    mapping(address => bool) public isStakingAtm;

    //array of all stakers
    address[] public stakers;

    constructor() {
       
    }

  
    //stake tokens function

    function stake(uint256 _amount) public whenNotPaused{
        //must be more than 0
        require(_amount > 0, "amount cannot be 0");

        //User adding test tokens
        erc20token.transferFrom(msg.sender, address(this), _amount);
        totalStaked = totalStaked + _amount;

        //updating staking balance for user by mapping
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        //checking if user staked before or not, if NOT staked adding to array of stakers
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        //updating staking status
        hasStaked[msg.sender] = true;
        isStakingAtm[msg.sender] = true;
    }

    //unstake tokens function

    function unstake() public {
        //get staking balance for user

        uint256 balance = stakingBalance[msg.sender];

        //amount should be more than 0
        require(balance > 0, "amount has to be more than 0");

        //transfer staked tokens back to user
        erc20token.transfer(msg.sender, balance);
        totalStaked = totalStaked - balance;

        //reseting users staking balance
        stakingBalance[msg.sender] = 0;

        //updating staking status
        isStakingAtm[msg.sender] = false;
    }

    
    

    //airdropp tokens
    function redistributeRewards() public onlyOwner{
        
        //doing drop for all addresses
        for (uint256 i = 0; i < stakers.length; i++) {
            address recipient = stakers[i];

            //calculating daily apy for user
            uint256 balance = stakingBalance[recipient] * APY;
            balance = balance / 100000;

            if (balance > 0) {
                erc20token.transfer(recipient, balance);
            }
        }
    }

    
    
    function setAPY(uint256 _value) public onlyOwner{
        //only owner can issue airdrop
        
        require(
            _value > 0,
            "APY value has to be more than 0, try 100 for (0.100% daily) instead"
        );
        APY = _value;
    }
    function setStakingToken(address token) public onlyOwner {
        erc20token = IERC20(token);
    }
   function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}