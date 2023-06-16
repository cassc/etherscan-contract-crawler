//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IVault.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IStakingFactory.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract Staking is IStaking, Context, ReentrancyGuard {
    uint256 public constant DAY_DURATION = 86400;
    uint256 public constant PERC_DENOMINATOR = 100;

    IVault public immutable VAULT;
    IStakingFactory public immutable FACTORY;
    IERC20 public immutable TOKEN;

    GeneralVariables public generalInfo;
    uint256 public totalStaked;

    mapping(address => UserInfo) public userStakes;

    modifier onlyFactory() {
        require(_msgSender() == address(FACTORY), "Only factory");
        _;
    }

    modifier initialized() {
        require(generalInfo.openTime > 0, "Initialize");
        _;
    }

    constructor(
        address _factory,
        address _vault,
        address _token
    ) {
        require(
            _factory != address(0) &&
                _vault != address(0) &&
                _token != address(0)
        );
        VAULT = IVault(_vault);
        TOKEN = IERC20(_token);
        FACTORY = IStakingFactory(_factory);
    }

    function initStaking(GeneralVariables memory _generalInfo)
        external
        override
        onlyFactory
    {
        generalInfo = _generalInfo;
    }

    function stake(uint256 amount) external initialized nonReentrant {
        address sender = _msgSender();
        uint256 currentTime = block.timestamp;
        UserInfo storage info = userStakes[sender];

        require(
            amount > 0 &&
                amount + info.totalStakedAmount <= generalInfo.maxStakeAmount &&
                totalStaked + amount <= generalInfo.maxGoalOfStaking,
            "Wrong amount params"
        );
        require(
            currentTime > generalInfo.openTime &&
                currentTime < generalInfo.closeTime,
            "Wrong time params"
        );

        if (info.totalStakedAmount == 0) {
            FACTORY.addUserStaking(sender);
        }
        info.previousReward = getReward(sender);
        info.updateTime = currentTime;
        info.totalStakedAmount += amount;
        totalStaked += amount;

        require(
            TOKEN.transferFrom(sender, address(this), amount),
            "Transfer failed"
        );
    }

    function unstake() external initialized nonReentrant {
        address sender = _msgSender();
        uint256 stakedAmount = userStakes[sender].totalStakedAmount;
        require(stakedAmount > 0, "Not staker");

        uint256 rewardAmount = getReward(sender);
        uint256 penalty = block.timestamp > generalInfo.closeTime
            ? 0
            : (stakedAmount * generalInfo.penalty) / PERC_DENOMINATOR;

        totalStaked -= stakedAmount;
        delete (userStakes[sender]);
        FACTORY.removeUserStaking(sender);

        if (rewardAmount > 0) VAULT.sendReward(rewardAmount, sender);
        if (penalty > 0)
            require(
                TOKEN.transfer(address(VAULT), penalty),
                "Penalty transfer failed"
            );
        uint256 toTransfer = stakedAmount - penalty;
        if (toTransfer > 0) {
            require(
                TOKEN.transfer(sender, stakedAmount - penalty),
                "Token transfer failed"
            );
        }
    }

    function getReward(address user) public view returns (uint256) {
        return userStakes[user].previousReward + calcCurrentReward(user);
    }

    function totalGenInfo() public view returns (GeneralVariables memory, uint256) {
        return (generalInfo, totalStaked);        
    }

    function userStakesReward(address user) public view returns(UserInfo memory, uint256){
        return (userStakes[user], getReward(user));
    }

    function calcCurrentReward(address user)
        private
        view
        returns (uint256 amount)
    {
        UserInfo memory info = userStakes[user];
        uint256 rightBound = block.timestamp < generalInfo.closeTime
            ? block.timestamp
            : generalInfo.closeTime;
        uint256 secondsAmount = rightBound - info.updateTime;
        amount =
            (info.totalStakedAmount * generalInfo.APR * secondsAmount) /
            (PERC_DENOMINATOR * 365 * DAY_DURATION);
    }
}