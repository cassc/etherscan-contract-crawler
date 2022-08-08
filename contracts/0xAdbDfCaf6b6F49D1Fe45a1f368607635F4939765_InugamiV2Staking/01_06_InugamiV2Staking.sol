// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*                                                          
@@@  @@@  @@@  @@@  @@@   @@@@@@@@   @@@@@@   @@@@@@@@@@   @@@  
@@@  @@@@ @@@  @@@  @@@  @@@@@@@@@  @@@@@@@@  @@@@@@@@@@@  @@@  
@@!  @@[email protected][email protected]@@  @@!  @@@  [email protected]@        @@!  @@@  @@! @@! @@!  @@!  
[email protected]!  [email protected][email protected][email protected]!  [email protected]!  @[email protected]  [email protected]!        [email protected]!  @[email protected]  [email protected]! [email protected]! [email protected]!  [email protected]!  
[email protected]  @[email protected] [email protected]!  @[email protected]  [email protected]!  [email protected]! @[email protected][email protected]  @[email protected][email protected][email protected]!  @!! [email protected] @[email protected]  [email protected]  
!!!  [email protected]!  !!!  [email protected]!  !!!  !!! [email protected]!!  [email protected]!!!!  [email protected]!   ! [email protected]!  !!!  
!!:  !!:  !!!  !!:  !!!  :!!   !!:  !!:  !!!  !!:     !!:  !!:  
:!:  :!:  !:!  :!:  !:!  :!:   !::  :!:  !:!  :!:     :!:  :!:  
 ::   ::   ::  ::::: ::   ::: ::::  ::   :::  :::     ::    ::  
:    ::    :    : :  :    :: :: :    :   : :   :      :    :    

Contract - https://t.me/geimskip
*/

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract InugamiV2Staking is Ownable {
    IERC20 public immutable inugamiToken;

    bool public stakingEnabled = true;
    uint256 public rewardPercentPerDayBase10000000000 = 5479452;
    uint256 public stakeFeeBase1000 = 10;

    mapping(address => uint256) stakedAmount;
    mapping(address => uint256) solidifiedReward;
    mapping(address => uint256) stakeStartTime;
    mapping(address => bool) noStakeFee;

    event Staked(address indexed owner, uint256 amount);
    event Withdrawn(address indexed owner);

    mapping(address => bool) admins;
    modifier onlyAdmins() {
        require(admins[msg.sender] == true);
        _;
    }

    constructor(IERC20 _inugamiToken) {
        inugamiToken = _inugamiToken;
        addAdmin(msg.sender, true);
    }

    // Staking functions

    function stake(uint256 amount) external {
        require(stakingEnabled, "Staking is currently disabled");
        // Frontend needs to request allowance
        require(inugamiToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance to stake");
        inugamiToken.transferFrom(msg.sender, address(this), amount);

        solidifyCurrentReward(msg.sender);

        uint256 stakeFee = 0;
        if (!noStakeFee[msg.sender]) {
            stakeFee = amount * stakeFeeBase1000 / 1000;
        }
        uint256 stakeAmount = amount - stakeFee;
        stakedAmount[msg.sender] += stakeAmount;

        emit Staked(msg.sender, amount);
    }
    

    function withdraw() external {
        uint256 totalWithdrawl = getPendingReward(msg.sender) + stakedAmount[msg.sender];

        require(inugamiToken.balanceOf(address(this)) >= totalWithdrawl, "Insufficient balance in staking address to withdraw");

        delete stakedAmount[msg.sender];
        delete solidifiedReward[msg.sender];
        delete stakeStartTime[msg.sender];

        inugamiToken.transfer(msg.sender, totalWithdrawl);

        emit Withdrawn(msg.sender);
    }

    // Admin tools

    function addAdmin(address insider, bool _isInsider) public onlyOwner {
        admins[insider] = _isInsider;
    }

    function setDepositFee(uint _stakeFeeBase1000) external onlyOwner {
        stakeFeeBase1000 = _stakeFeeBase1000;
    }

    function setNoStakeFee(address staker, bool _noStakeFee) external onlyAdmins {
        noStakeFee[staker] = _noStakeFee;
    }

    function solidifyAndFreeze(address staker) external onlyAdmins {
        solidifyCurrentReward(staker);
        stakeStartTime[staker] = 0;
    }

    function setStakingEnabled(bool _enabled) external onlyAdmins {
        stakingEnabled = _enabled;
    }

    // Status views

    function getPendingReward(address staker) public view returns (uint256) {
        return getLiquidReward(staker) + solidifiedReward[staker];
    }


    function getStakedAmount(address staker) external view returns (uint256) {
        return stakedAmount[staker];
    }

    // Internal workings

    function getLiquidReward(address staker) internal view returns (uint256) {
        if (stakeStartTime[staker] == 0) return 0;
        if (block.timestamp < stakeStartTime[staker]) return 0;

        uint256 deltaSeconds = block.timestamp - stakeStartTime[staker];
        uint256 amount = stakedAmount[staker] * rewardPercentPerDayBase10000000000 * deltaSeconds / (10000000000 * 24 hours);
        return amount;
    }


    function solidifyCurrentReward(address staker) internal {
        uint256 liquidEarnedAmount = getLiquidReward(staker);
        if (liquidEarnedAmount > 0) {
            solidifiedReward[staker] = liquidEarnedAmount;
        }
        stakeStartTime[msg.sender] = block.timestamp;
    }

    // Panic functions

    function withdrawStuckEth() external onlyOwner {
        bool success;
        (success,) = address(owner()).call{value: address(this).balance}("");
    }

    function withdrawStuckTokens(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }
}