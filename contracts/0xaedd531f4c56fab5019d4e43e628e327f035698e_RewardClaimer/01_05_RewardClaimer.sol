// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/Pausable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
* @title Enables claiming of POW rewards for staking MetaHeroes
*
* @author Niftydude
*/
contract RewardClaimer is Ownable, Pausable  {

    IERC20 immutable POW;
    StakingContract immutable STAKING;

    mapping(address => bool) public claimed;

    event ClaimedRewards(address indexed account, uint256 amount);

    error AlreadyClaimed();
    error NothingToClaim();

    constructor(address _stakingContract, address _powAddress) {
        POW = IERC20(_powAddress);        
        STAKING = StakingContract(_stakingContract);

        _pause();
    }                                      

    /**
    * @notice external function to claim rewards accrued by message sender
    */
    function claim() external whenNotPaused {
        if(claimed[msg.sender]) revert AlreadyClaimed();

        uint256 claimableRewards = STAKING.calculateRewardsByAccount(msg.sender);
        if(claimableRewards == 0) revert NothingToClaim();

        claimed[msg.sender] = true;

        POW.transfer(msg.sender, claimableRewards);

        emit ClaimedRewards(msg.sender, claimableRewards);
    }     

    /**
    * @notice withdraw POW tokens from contract
    * 
    * @param to the wallet to transfer the tokens to
    * @param amount the amount of tokens to withdraw
    */
    function withdraw(address to, uint256 amount) external onlyOwner {
        require(
            POW.balanceOf(address(this)) >= amount, 
            "Withdraw: balance exceeded");

        POW.transfer(to, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }        
}

interface StakingContract {
    function calculateRewardsByAccount(address account) external view returns (uint256);    
    function rewardPerBlock() external view returns (uint128);
 }