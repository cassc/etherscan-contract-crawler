//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./CactusRewardToken.sol";
import "./interfaces/ICactusToken.sol";
import "./interfaces/ICactusRewarding.sol";

contract Staking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable crt;
    ICactusToken public cactt;
    address public rewardingContract;

    mapping(address => UserDetails) private userInfo;
    address[] private _downlines;

    uint256 public totalStaked = 0;
    uint256 public constant MAX_STAKING_PERIOD = 31560000; // 1 year
    uint256 public constant MIN_CACTT = 1000000000000000000000;
    uint256 public constant MIN_STAKE = 50000000000000000000;
    uint256 public constant MAX_STAKE = 30000000000000000000000;
    uint256 public constant MAX_YIELD = 50000000000000000000000;

    uint256 public constant FIRST_GEN_COMMISSION = 300; //percentage in BPS
    uint256 public constant SECOND_GEN_COMMISSION = 200; //percentage in BPS
    uint256 public constant THIRD_GEN_COMMISSION = 100; //percentage in BPS
    uint256 public constant HARVEST_TAX_IN_BPS = 500;

    bool public isStakingEnabled = false;
    uint256 public totalParticipants;
    uint256 public totalPayouts;

    struct UserDetails {
        uint256 amount; //amount of crt the user have provided
        uint256 rewardDebt;
        uint256 initialTime;
        uint256 totalWithdrawal;
        uint256 apy;
        uint256 referralEarnings;
    }

    event RewardingContractChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    constructor(ICactusToken _cactt, address _crt) {
        cactt = _cactt;
        crt = _crt;
    }

    function safeCRTTransfer(address _to, uint256 _amount) internal {
        uint256 crtBal = CactusRewardToken(crt).balanceOf(address(this));
        if (_amount > crtBal) {
            CactusRewardToken(crt).mint(_to, _amount);
        } else {
            CactusRewardToken(crt).transfer(_to, _amount);
        }
    }

    function updateUserStake(address _address) internal {
        uint256 rewardAmount = getRewards(_address);
        userInfo[_address].rewardDebt = rewardAmount;
        userInfo[_address].initialTime = block.timestamp;
    }

    function stake(uint256 amount) external nonReentrant {
        require(isStakingEnabled, "Staking is disabled");
        require(amount >= MIN_STAKE, "Minimum to stake is 50 CRT");
        require(amount <= MAX_STAKE, "Maximum to stake is 30,000 CRT");

        CactusRewardToken(crt).transferFrom(msg.sender, address(this), amount);

        updateUserStake(msg.sender);

        if (userInfo[msg.sender].amount < 1) {
            if (cactt.balanceOf(msg.sender) >= MIN_CACTT) {
                userInfo[msg.sender].apy = 350;
            } else {
                userInfo[msg.sender].apy = 250;
            }

            totalParticipants = totalParticipants.add(1);
        }

        userInfo[msg.sender].amount = userInfo[msg.sender].amount.add(amount);
        userInfo[msg.sender].initialTime = block.timestamp;
        totalStaked = totalStaked.add(amount);

        payReferrerCommission(msg.sender, amount);
    }

    function harvest() external nonReentrant {
        uint256 rewardAmount = getRewards(msg.sender);
        require(rewardAmount > 0, "harvest: not enough funds");

        updateUserStake(msg.sender);

        userInfo[msg.sender].rewardDebt = 0;
        userInfo[msg.sender].totalWithdrawal = userInfo[msg.sender]
            .totalWithdrawal
            .add(rewardAmount);

        uint256 claimingFee = rewardAmount.mul(HARVEST_TAX_IN_BPS).div(10000);
        uint256 payoutAmount = rewardAmount.sub(claimingFee);

        totalPayouts = totalPayouts.add(payoutAmount);
        safeCRTTransfer(msg.sender, payoutAmount);
    }

    function getRewards(address account) public view returns (uint256) {
        uint256 pendingReward = 0;
        if (userInfo[account].amount > 0) {
            uint256 stakeAmount = userInfo[account].amount;
            uint256 timeDiff;
            unchecked {
                timeDiff = block.timestamp - userInfo[account].initialTime;
            }
            uint256 rewardRate = userInfo[account].apy;
            if (timeDiff >= MAX_STAKING_PERIOD) {
                uint256 amount = stakeAmount.mul(rewardRate).div(100);
                if (amount >= MAX_YIELD) {
                    return pendingReward = MAX_YIELD;
                }
                return amount;
            }
            uint256 rewardAmount = (((stakeAmount * (rewardRate)) / 100) *
                timeDiff) / MAX_STAKING_PERIOD;

            if (rewardAmount >= MAX_YIELD) {
                pendingReward = MAX_YIELD;
            }
            pendingReward = rewardAmount;
        }

        uint256 pending = userInfo[account].rewardDebt.add(pendingReward);
        return pending;
    }

    function getUserDetails(address account)
        external
        view
        returns (UserDetails memory, uint256)
    {
        uint256 reward = getRewards(account);
        return (
            UserDetails(
                userInfo[account].amount,
                userInfo[account].rewardDebt,
                userInfo[account].initialTime,
                userInfo[account].totalWithdrawal,
                userInfo[account].apy,
                userInfo[account].referralEarnings
            ),
            reward
        );
    }

    function disableStaking() external onlyOwner returns (bool) {
        isStakingEnabled = false;
        return true;
    }

    function enableStaking() external onlyOwner returns (bool) {
        isStakingEnabled = true;
        return true;
    }

    function userUplines(address _user) internal returns (address[] memory) {
        address referrer = ICactusRewarding(rewardingContract).getReferrer(
            _user
        );
        if (referrer != address(0)) {
            _downlines.push(referrer);

            for (uint256 i = 0; i < 3; i++) {
                address ref = _downlines[_downlines.length - 1];
                address refUpline = ICactusRewarding(rewardingContract)
                    .getReferrer(ref);
                if (refUpline != address(0)) {
                    _downlines.push(refUpline);
                }
            }
        }

        address[] memory downlineArr = _downlines;
        delete _downlines;
        return downlineArr;
    }

    function getCommission(uint256 index, uint256 _amount)
        private
        pure
        returns (uint256)
    {
        if (index == 0) {
            return _amount.mul(FIRST_GEN_COMMISSION).div(10000);
        }
        if (index == 1) {
            return _amount.mul(SECOND_GEN_COMMISSION).div(10000);
        }
        return _amount.mul(THIRD_GEN_COMMISSION).div(10000);
    }

    function payReferrerCommission(address _user, uint256 _transactionAmount)
        internal
    {
        if (rewardingContract != address(0)) {
            address referrer = ICactusRewarding(rewardingContract).getReferrer(
                _user
            );

            if (referrer != address(0)) {
                address[] memory userUps = userUplines(_user);

                for (uint256 i = 0; i < userUps.length; i++) {
                    uint256 uCommission = getCommission(i, _transactionAmount);

                    if (userInfo[userUps[i]].amount < 1) {
                        if (cactt.balanceOf(userUps[i]) >= MIN_CACTT) {
                            userInfo[userUps[i]].apy = 350;
                        } else {
                            userInfo[userUps[i]].apy = 250;
                        }

                        totalParticipants = totalParticipants.add(1);
                    }

                    updateUserStake(userUps[i]);

                    userInfo[userUps[i]].amount = userInfo[userUps[i]]
                        .amount
                        .add(uCommission);

                    userInfo[userUps[i]].referralEarnings = userInfo[userUps[i]]
                        .referralEarnings
                        .add(uCommission);
                    userInfo[userUps[i]].initialTime = block.timestamp;
                }
            }
        }
    }

    function setRewardingContractAddress(address _newAddress) public onlyOwner {
        emit RewardingContractChanged(rewardingContract, _newAddress);
        rewardingContract = _newAddress;
    }
}