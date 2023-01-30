// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Flipping Club - flippingclub.xyz
/**
 *  ______ _ _             _                _____ _       _
 * |  ____| (_)           (_)              / ____| |     | |
 * | |__  | |_ _ __  _ __  _ _ __   __ _  | |    | |_   _| |__
 * |  __| | | | '_ \| '_ \| | '_ \ / _` | | |    | | | | | '_ \
 * | |    | | | |_) | |_) | | | | | (_| | | |____| | |_| | |_) |
 * |_|    |_|_| .__/| .__/|_|_| |_|\__, |  \_____|_|\__,_|_.__/
 *            | |   | |             __/ |
 *   _____ _  |_|   |_|  _         |___/  _____            _                  _
 *  / ____| |      | |  (_)              / ____|          | |                | |
 * | (___ | |_ __ _| | ___ _ __   __ _  | |     ___  _ __ | |_ _ __ __ _  ___| |_
 *  \___ \| __/ _` | |/ / | '_ \ / _` | | |    / _ \| '_ \| __| '__/ _` |/ __| __|
 *  ____) | || (_| |   <| | | | | (_| | | |___| (_) | | | | |_| | | (_| | (__| |_
 * |_____/ \__\__,_|_|\_\_|_| |_|\__, |  \_____\___/|_| |_|\__|_|  \__,_|\___|\__|
 *                                __/ |
 *                               |___/
 *
 * @title Flipping Club Staking Contract - Dependency v4.1 - flippingclub.xyz
 * @author Flipping Club Team
 */

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./migratingSourceFunctions.sol";

contract Stakeable is ReentrancyGuard {
    using SafeMath for uint256;
    uint256 private initialTimestamp;
    uint256 private _maxAllowancePerKey = 5000000000000000000;
    uint256 private timePeriod;
    uint256 private maxPositions = 4;
    uint256 private MinStakeValueToClosePosition = 100000000000000000;
    uint256 private MovePercentageBasisNumber = 50;
    uint256 private minWithdraw = 100000000000000000;
    address private StakingAccount;
    bool private MoveFundsUponReceipt;
    bool private partialWithdraw = true;
    bool private lockdown = false;
    bool private MovePercentageOfFundsUponReceipt = true;
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));
    bytes32 private constant CLAIM = keccak256(abi.encodePacked("CLAIM"));
    Stakeholder[] internal stakeholders;
    mapping(bytes32 => mapping(address => bool)) public roles;
    mapping(address => uint256) internal stakes;
    mapping(uint256 => poolGroup[]) private poolGroups;
    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);
    event Withdrawn(address indexed, uint256 amount, uint256 timestamp);
    event Extended(
        address user,
        uint256 amount,
        uint256 since,
        uint256 reward,
        uint256 timePeriod,
        uint256 usedKeys
    );
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp,
        uint256 _plan,
        uint256 timePeriod,
        uint256 usedKeys
    );
    event Migrated(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp,
        uint256 _plan,
        uint256 timePeriod,
        uint256 usedKeys
    );
    struct Stake {
        address user;
        uint256 amount;
        uint256 since;
        uint256 percentage;
        uint256 timePeriod;
        uint256 reward;
        uint256 usedKeys;
        bool paused;
        uint256 poolID;
    }
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }
    struct poolGroup {
        uint256 id;
        bool active;
    }
    struct StakingSummary {
        Stake[] stakes;
    }

    constructor() {
        stakeholders.push();
    }

    function _addStakeholder(address staker) private returns (uint256) {
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    function _stake(
        uint256 _amount,
        uint256 _percentage,
        uint256 _timePeriodInSeconds,
        address _Sender,
        uint256 usedKeys,
        uint256 poolID
    ) internal {
        require(poolGroups[poolID].length > 0, "No Pool");
        require(StakingAccount != address(0), "Staking account not set.");
        require(canStake(_Sender, _percentage), "Max open positions.");
        if (MoveFundsUponReceipt) {
            payable(StakingAccount).transfer(_amount);
        }
        if (MovePercentageOfFundsUponReceipt) {
            payable(StakingAccount).transfer(
                (_amount.mul(MovePercentageBasisNumber)).div(100)
            );
        }
        uint256 index = stakes[_Sender];
        uint256 timestamp = block.timestamp;
        if (index == 0) {
            index = _addStakeholder(_Sender);
        }
        initialTimestamp = block.timestamp;
        timePeriod = initialTimestamp.add(_timePeriodInSeconds);
        stakeholders[index].address_stakes.push(
            Stake(
                payable(_Sender),
                _amount,
                timestamp,
                _percentage,
                timePeriod,
                0,
                usedKeys,
                false,
                poolID
            )
        );
        emit Staked(
            _Sender,
            _amount,
            index,
            timestamp,
            _percentage,
            timePeriod,
            usedKeys
        );
    }

    function _admin_stake(
        uint256 _amount,
        uint256 _percentage,
        uint256 _timePeriodInSeconds,
        address _Sender,
        uint256 _startTime,
        uint256 usedKeys,
        uint256 rewards,
        uint256 poolID
    ) internal {
        require(canStake(_Sender, _percentage), "Max open positions.");
        require(poolGroups[poolID].length > 0, "No Pool");
        uint256 index = stakes[_Sender];
        uint256 timestamp = _startTime;
        if (index == 0) {
            index = _addStakeholder(_Sender);
        }
        initialTimestamp = _startTime;
        timePeriod = initialTimestamp.add(_timePeriodInSeconds);
        stakeholders[index].address_stakes.push(
            Stake(
                payable(_Sender),
                _amount,
                timestamp,
                _percentage,
                timePeriod,
                rewards,
                usedKeys,
                false,
                poolID
            )
        );
        emit Staked(
            _Sender,
            _amount,
            index,
            timestamp,
            _percentage,
            timePeriod,
            usedKeys
        );
    }

    function _migrateStake(
        uint256 _amount,
        uint256 _percentage,
        uint256 _timePeriodInSeconds,
        uint256 _startTime,
        uint256 usedKeys,
        uint256 _reward,
        uint256 poolID
    ) internal {
        require(poolGroups[poolID].length > 0, "No Pool");
        require(canStake(msg.sender, _percentage), "Max open positions.");
        uint256 index = stakes[msg.sender];
        if (index == 0) {
            index = _addStakeholder(msg.sender);
        }
        stakeholders[index].address_stakes.push(
            Stake(
                msg.sender,
                _amount,
                _startTime,
                _percentage,
                _timePeriodInSeconds,
                _reward,
                usedKeys,
                false,
                poolID
            )
        );
        emit Migrated(
            msg.sender,
            _amount,
            index,
            _startTime,
            _percentage,
            _timePeriodInSeconds,
            usedKeys
        );
    }

    function calculateStakeReward(Stake memory _current_stake)
        private
        view
        returns (uint256)
    {
        if (block.timestamp > _current_stake.timePeriod) {
            return
                (_current_stake.amount.mul(_current_stake.percentage)).div(100);
        }
        return 0;
    }

    function toggleStakeStatus(
        address _staker,
        bool _status,
        uint256 index
    ) external onlyRole(EXEC) {
        uint256 user_index = stakes[_staker];
        require(user_index > 0, "Address not registered.");
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(current_stake.amount > 0, "No active positions.");
        stakeholders[user_index].address_stakes[index].paused = _status;
    }

    function _withdrawStake(uint256 index) internal {
        require(lockdown == false, "Contract Locked.");
        uint256 user_index = stakes[msg.sender];
        require(user_index > 0, "Address not registered.");
        require(index <= maxPositions - 1, "Index out of range.");
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(
            poolGroups[current_stake.poolID][0].active,
            "Pool Temporary Suspended"
        );
        require(current_stake.amount > 0, "No active positions.");
        require(
            block.timestamp >= current_stake.timePeriod,
            "Not matured yet."
        );
        uint256 reward = current_stake.reward.add(
            calculateStakeReward(current_stake)
        );
        require(reward > 0, "Claim not ready.");
        uint256 _amount = current_stake.amount.add(reward);
        require(_amount >= minWithdraw, "Amount is less than minimum");
        require(address(this).balance > _amount, "Not enough balance.");
        delete stakeholders[user_index].address_stakes[index];
        stakeholders[user_index].address_stakes[index] = stakeholders[
            user_index
        ].address_stakes[stakeholders[user_index].address_stakes.length - 1];
        stakeholders[user_index].address_stakes.pop();
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount, block.timestamp);
    }

    function _withdrawReturn(uint256 index) internal {
        require(lockdown == false, "Contract Locked.");
        uint256 user_index = stakes[msg.sender];
        require(user_index > 0, "Address not registered.");
        require(partialWithdraw, "Partial withdraw is not enabled.");
        require(index <= maxPositions - 1, "Index out of range.");
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(
            poolGroups[current_stake.poolID][0].active,
            "Pool Temporary Suspended"
        );
        require(current_stake.amount > 0, "No active positions.");

        require(
            block.timestamp >= current_stake.timePeriod,
            "Not matured yet."
        );
        uint256 reward = current_stake.reward.add(
            calculateStakeReward(current_stake)
        );
        require(reward > 0, "Claim not ready.");
        uint256 _amount = reward;
        require(_amount >= minWithdraw, "Amount is less than minimum");
        require(address(this).balance > _amount, "Not enough balance.");

        if (
            _enoughKeys(
                stakeholders[user_index].address_stakes[index].amount,
                stakeholders[user_index].address_stakes[index].percentage,
                reward,
                stakeholders[user_index].address_stakes[index].usedKeys
            )
        ) {
            uint256 timeDiff = (
                stakeholders[user_index].address_stakes[index].timePeriod
            ).sub(stakeholders[user_index].address_stakes[index].since);
            stakeholders[user_index].address_stakes[index].since = block
                .timestamp;
            stakeholders[user_index].address_stakes[index].timePeriod = block
                .timestamp
                .add(timeDiff);
            stakeholders[user_index].address_stakes[index].reward = 0;
            payable(msg.sender).transfer(_amount);
            emit Withdrawn(msg.sender, _amount, block.timestamp);
            emit Extended(
                stakeholders[user_index].address_stakes[index].user,
                stakeholders[user_index].address_stakes[index].amount,
                stakeholders[user_index].address_stakes[index].since,
                stakeholders[user_index].address_stakes[index].reward,
                stakeholders[user_index].address_stakes[index].timePeriod,
                stakeholders[user_index].address_stakes[index].usedKeys
            );
        } else {
            _amount = current_stake.amount.add(reward);
            delete stakeholders[user_index].address_stakes[index];
            stakeholders[user_index].address_stakes[index] = stakeholders[
                user_index
            ].address_stakes[
                    stakeholders[user_index].address_stakes.length - 1
                ];
            stakeholders[user_index].address_stakes.pop();
            payable(msg.sender).transfer(_amount);
            emit Withdrawn(msg.sender, _amount, block.timestamp);
        }
    }

    function _admin_withdraw_close(
        uint256 index,
        address payable _spender,
        bool refund
    ) internal {
        uint256 user_index = stakes[_spender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        uint256 reward = current_stake.reward.add(
            calculateStakeReward(current_stake)
        );

        uint256 claimable = current_stake.amount.add(reward);
        delete stakeholders[user_index].address_stakes[index];
        stakeholders[user_index].address_stakes[index] = stakeholders[
            user_index
        ].address_stakes[stakeholders[user_index].address_stakes.length - 1];
        stakeholders[user_index].address_stakes.pop();
        if (refund) {
            require(address(this).balance >= claimable, "Not enough balance.");
            payable(_spender).transfer(claimable);
        }
    }

    function _extendStake(uint256 index) public {
        require(lockdown == false, "Contract Locked.");
        uint256 user_index = stakes[msg.sender];
        require(user_index > 0, "Address not registered.");
        require(index <= maxPositions - 1, "Index out of range.");
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        require(current_stake.amount > 0, "No active positions.");
        uint256 reward = current_stake.reward.add(
            calculateStakeReward(current_stake)
        );
        require(
            poolGroups[current_stake.poolID][0].active,
            "Pool Temporary Suspended"
        );
        require(reward > 0, "Extend not Possible.");
        require(
            _enoughKeys(
                stakeholders[user_index].address_stakes[index].amount,
                stakeholders[user_index].address_stakes[index].percentage,
                reward,
                stakeholders[user_index].address_stakes[index].usedKeys
            ),
            "Not enough allowance left."
        );
        uint256 timeDiff = (
            stakeholders[user_index].address_stakes[index].timePeriod
        ).sub(stakeholders[user_index].address_stakes[index].since);
        stakeholders[user_index].address_stakes[index].since = block.timestamp;
        stakeholders[user_index].address_stakes[index].timePeriod = block
            .timestamp
            .add(timeDiff);
        stakeholders[user_index].address_stakes[index].reward = reward;
        emit Extended(
            stakeholders[user_index].address_stakes[index].user,
            stakeholders[user_index].address_stakes[index].amount,
            stakeholders[user_index].address_stakes[index].since,
            stakeholders[user_index].address_stakes[index].reward,
            stakeholders[user_index].address_stakes[index].timePeriod,
            stakeholders[user_index].address_stakes[index].usedKeys
        );
    }

    function _enoughKeys(
        uint256 _amount,
        uint256 _PlanReward,
        uint256 _FutReward,
        uint256 _numKeys
    ) internal view returns (bool) {
        if (
            _amount.mul(_PlanReward).div(100).add(_FutReward) <=
            _numKeys.mul(_maxAllowancePerKey)
        ) {
            return true;
        }
        return false;
    }

    function _stakeLength(address _staker) external view returns (uint256) {
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        return summary.stakes.length;
    }

    function getAllStakes(address _staker)
        external
        view
        returns (StakingSummary memory)
    {
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].reward = summary.stakes[s].reward.add(
                availableReward
            );
        }
        return summary;
    }

    function getSingleStake(address _staker, uint256 index)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(index <= maxPositions - 1, "Index out of range.");
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        require(summary.stakes.length > 0, "No active positions.");
        require(summary.stakes.length > index, "Index not valid.");

        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].reward = summary.stakes[s].reward.add(
                availableReward
            );
        }
        return (
            summary.stakes[index].amount,
            summary.stakes[index].since,
            summary.stakes[index].percentage,
            summary.stakes[index].timePeriod,
            summary.stakes[index].reward,
            summary.stakes[index].usedKeys
        );
    }

    function _hasStake(address _staker, uint256 index)
        internal
        view
        returns (bool)
    {
        require(index <= maxPositions - 1, "Index out of range.");
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        if (summary.stakes.length > 0 && summary.stakes.length > index) {
            return true;
        }
        return false;
    }

    function canStake(address _staker, uint256 _percentage)
        private
        view
        returns (bool result)
    {
        StakingSummary memory summary = StakingSummary(
            stakeholders[stakes[_staker]].address_stakes
        );
        if (summary.stakes.length >= maxPositions) {
            return false;
        }

        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            if (summary.stakes[s].percentage == _percentage) {
                return false;
            }
        }
        return true;
    }

    function setMaxPositions(uint256 _maxPositions) external onlyRole(ADMIN) {
        maxPositions = _maxPositions;
    }

    function setMinStakeValueToClosePosition(
        uint256 _MinStakeValueToClosePosition
    ) external onlyRole(ADMIN) {
        MinStakeValueToClosePosition = _MinStakeValueToClosePosition;
    }

    function setStakingAccount(address _StakingAccount)
        external
        onlyRole(ADMIN)
    {
        StakingAccount = _StakingAccount;
    }

    function setMoveFundsUponReceipt(bool _MoveFundsUponReceipt)
        external
        onlyRole(ADMIN)
    {
        MoveFundsUponReceipt = _MoveFundsUponReceipt;
    }

    function setMovePercentageBasisNumber(uint256 _MovePercentageBasisNumber)
        external
        onlyRole(ADMIN)
    {
        MovePercentageBasisNumber = _MovePercentageBasisNumber;
    }

    function setPartialWithdraw(bool _partialWithdraw)
        external
        onlyRole(ADMIN)
    {
        partialWithdraw = _partialWithdraw;
    }

    function setMovePercentageOfFundsUponReceipt(
        bool _MovePercentageOfFundsUponReceipt
    ) external onlyRole(ADMIN) {
        MovePercentageOfFundsUponReceipt = _MovePercentageOfFundsUponReceipt;
    }

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Not authorized.");
        _;
    }

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function grantRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        _grantRole(_role, _account);
    }

    function _revokeRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account)
        external
        onlyRole(ADMIN)
    {
        _revokeRole(_role, _account);
    }

    function set_maxAllowancePerKey(uint256 __maxAllowancePerKey)
        external
        onlyRole(ADMIN)
    {
        _maxAllowancePerKey = __maxAllowancePerKey;
    }

    function setMinWithdraw(uint256 _minWithdraw) external onlyRole(ADMIN) {
        minWithdraw = _minWithdraw;
    }

    function toggleLockdown(bool _status) external onlyRole(EXEC) {
        lockdown = _status;
    }

    function addPoolGroup(uint256 id, bool active) external onlyRole(ADMIN) {
        poolGroups[id].push(poolGroup(id, active));
    }

    function getPoolGroup(uint256 poolID)
        public
        view
        returns (poolGroup memory)
    {
        require(poolGroups[poolID].length > 0, "No Pool");
        poolGroup memory pool = poolGroups[poolID][0];
        return pool;
    }

    function deletePoolGroup(uint256 poolID) external onlyRole(ADMIN) {
        require(poolGroups[poolID].length > 0, "No Pool");
        delete poolGroups[poolID];
    }

    function togglePoolGroupStatus(uint256 poolID, bool _status)
        external
        onlyRole(EXEC)
    {
        poolGroups[poolID][0].active = _status;
    }
}