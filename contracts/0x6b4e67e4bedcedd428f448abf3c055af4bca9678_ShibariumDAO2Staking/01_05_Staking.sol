/**

 ______     __  __     __     ______     ______     ______     __     __  __     __    __    
/\  ___\   /\ \_\ \   /\ \   /\  == \   /\  __ \   /\  == \   /\ \   /\ \/\ \   /\ "-./  \   
\ \___  \  \ \  __ \  \ \ \  \ \  __<   \ \  __ \  \ \  __<   \ \ \  \ \ \_\ \  \ \ \-./\ \  
 \/\_____\  \ \_\ \_\  \ \_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \_____\  \ \_\ \ \_\ 
  \/_____/   \/_/\/_/   \/_/   \/_____/   \/_/\/_/   \/_/ /_/   \/_/   \/_____/   \/_/  \/_/                                                                                              
 _____     ______     ______                                                                 
/\  __-.  /\  __ \   /\  __ \                                                                
\ \ \/\ \ \ \  __ \  \ \ \/\ \                                                               
 \ \____-  \ \_\ \_\  \ \_____\                                                              
  \/____/   \/_/\/_/   \/_____/                                                              


    Website: https://shibariumdao.io
    Telegram: https://t.me/ShibariumDAO

**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ShibariumDAO2Staking is ReentrancyGuard, Ownable {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 claimedAmountShib;
        uint256 claimedAmountBone;
        bool withdrawn;
    }

    mapping(address => Stake[]) public stakes;

    mapping(address => uint256) public claimedNumber;
    uint256 constant CLAIM_FEE_NUMERATOR = 50;
    uint256 constant CLAIM_FEE_DENOMINATOR = 10000;

    IERC20 public immutable SHIBDAO;
    IERC20 public immutable SHIB;
    IERC20 public immutable BONE;

    uint256 public constant SHIBDAO_SUPPLY_FREE = 500_000_000 ether; // 1/2 of total supply
    uint256 public SHIB_REWARD_AMOUNT;
    uint256 public BONE_REWARD_AMOUNT;

    uint256 public constant LOCK_TIME = 30 days;

    event StakeAdded(address staker, uint256 amount, uint256 lockTime);
    event StakeRemoved(address staker, uint256 amount, uint256 lockTime);
    event RewardsClaimed(
        address staker,
        uint256 shibAmount,
        uint256 boneAmount
    );

    constructor(
        address _shibdao,
        address _shib,
        address _bone
    ) ReentrancyGuard() Ownable() {
        SHIBDAO = IERC20(_shibdao);
        SHIB = IERC20(_shib);
        BONE = IERC20(_bone);
    }

    function addStake(uint256 amount) external nonReentrant {
        bool success = SHIBDAO.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        stakes[msg.sender].push(Stake(amount, block.timestamp, 0, 0, false));
        emit StakeAdded(msg.sender, amount, block.timestamp);
    }

    function removeStake(uint256 index) external nonReentrant {
        Stake storage stake = stakes[msg.sender][index];

        require(stake.startTime + LOCK_TIME <= block.timestamp, "Stake locked");
        require(!stake.withdrawn, "Stake already withdrawn");

        bool success = SHIBDAO.transfer(msg.sender, stake.amount);
        require(success, "Transfer failed");

        stake.withdrawn = true;

        emit StakeRemoved(msg.sender, stake.amount, block.timestamp);
    }

    function claimRewards(uint256 index) external nonReentrant {
        Stake storage stake = stakes[msg.sender][index];

        (uint256 amountShib, uint256 amountBone) = getRewards(
            msg.sender,
            index
        );
        stake.claimedAmountShib += amountShib;
        stake.claimedAmountBone += amountBone;

        uint256 claimFeeNumerator = getClaimFee(msg.sender);

        uint256 amountShibFee = (amountShib * claimFeeNumerator) /
            CLAIM_FEE_DENOMINATOR;
        uint256 amountBoneFee = (amountBone * claimFeeNumerator) /
            CLAIM_FEE_DENOMINATOR;

        bool shibSuccess = SHIB.transfer(
            msg.sender,
            amountShib - amountShibFee
        );
        require(shibSuccess, "Transfer failed");
        bool boneSuccess = BONE.transfer(
            msg.sender,
            amountBone - amountBoneFee
        );
        require(boneSuccess, "Transfer failed");

        claimedNumber[msg.sender] += 1;

        emit RewardsClaimed(msg.sender, amountShib, amountBone);
    }

    function getClaimFee(address claimant) public view returns (uint256) {
        uint256 baseFee = claimedNumber[claimant] * CLAIM_FEE_NUMERATOR;
        if (baseFee > 600) {
            return 600;
        } else {
            return baseFee;
        }
    }

    function getRewards(
        address staker,
        uint256 index
    ) public view returns (uint256, uint256) {
        Stake storage stake = stakes[staker][index];
        uint256 shibAmountTotal = (SHIB_REWARD_AMOUNT * stake.amount) /
            SHIBDAO_SUPPLY_FREE;
        uint256 boneAmountTotal = (BONE_REWARD_AMOUNT * stake.amount) /
            SHIBDAO_SUPPLY_FREE;

        uint256 timeElapsed = block.timestamp - stake.startTime;
        if (timeElapsed > LOCK_TIME) timeElapsed = LOCK_TIME;

        uint256 shibAmount = (shibAmountTotal * timeElapsed) / LOCK_TIME;
        uint256 boneAmount = (boneAmountTotal * timeElapsed) / LOCK_TIME;

        uint256 shibAmountToClaim = shibAmount - stake.claimedAmountShib;
        uint256 boneAmountToClaim = boneAmount - stake.claimedAmountBone;

        return (shibAmountToClaim, boneAmountToClaim);
    }

    function getStakes(
        address user
    ) external view returns (Stake[] memory userStakes) {
        return stakes[user];
    }

    function setRewards(
        uint256 shibAmount,
        uint256 boneAmount
    ) external onlyOwner {
        SHIB_REWARD_AMOUNT = shibAmount;
        BONE_REWARD_AMOUNT = boneAmount;
    }

    function unstickTokens(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }
}