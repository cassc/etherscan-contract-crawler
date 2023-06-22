/**
 *   _____                          _____        _____
 *  / ____|                        |  __ \ /\   |_   _|
 * | |     _ __ ___  __ _ _ __ ___ | |__) /  \    | |
 * | |    | '__/ _ \/ _` | '_ ` _ \|  ___/ /\ \   | |
 * | |____| | |  __/ (_| | | | | | | |  / ____ \ _| |_
 *  \_____|_|  \___|\__,_|_| |_| |_|_| /_/    \_\_____|
 *
 * CreamPAI : The world's first tokenized adult generative AI
 *
 * Website: https://creampai.org
 * Litepaper: https://creampai-org.gitbook.io/creampai/
 * Twitter: https://twitter.com/Real_CreamPAI
 * Telegram: https://t.me/CreamPAI_Portal
 * OnlyFans: https://onlyfans.com/real_creampai
 *
 * Staking contract
 *
 */


// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@thirdweb-dev/contracts/base/Staking20Base.sol";
import "@thirdweb-dev/contracts/token/TokenERC20.sol";

contract CreampaiStaking is Staking20Base {
    uint48 public lockTimePeriod;

    struct User {
        uint48 stakeTime;
        uint48 unlockTime;
    }

    mapping(address => User) public timeMap;

    constructor(
        uint256 _timeUnit,
        uint256 _rewardRatioNumerator,
        uint256 _rewardRatioDenominator,
        address _stakingToken,
        address _rewardToken,
        address _nativeTokenWrapper,
        uint48 _lockTimePeriod
    )
        Staking20Base(
            _timeUnit,
            _rewardRatioNumerator,
            _rewardRatioDenominator,
            _stakingToken,
            _rewardToken,
            _nativeTokenWrapper
        )
    {
        lockTimePeriod = _lockTimePeriod;
    }

    function _stake(uint256 _amount) internal override {
        super._stake(_amount);
        User storage user = timeMap[_stakeMsgSender()];
        user.unlockTime = toUint48(block.timestamp + lockTimePeriod);
        user.stakeTime = toUint48(block.timestamp);
    }

    function _withdraw(uint256 _amount) internal override {
        require(block.timestamp > getUnlockTime(_stakeMsgSender()), "Staked tokens are locked");
        super._withdraw(_amount);
    }

    function getUnlockTime(
        address _staker
    ) public view returns (uint48 unlockTime) {
        return
            stakers[_staker].amountStaked > 0
                ? timeMap[_staker].unlockTime
                : type(uint48).max;
    }

    function getStakeTime(
        address _staker
    ) public view returns (uint48 stakeTime) {
        return
            stakers[_staker].amountStaked > 0
                ? timeMap[_staker].stakeTime
                : type(uint48).min;
    }

    /**
     * based on OpenZeppelin SafeCast v4.3
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.3/contracts/utils/math/SafeCast.sol
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "value doesn't fit in 48 bits");
        return uint48(value);
    }

}