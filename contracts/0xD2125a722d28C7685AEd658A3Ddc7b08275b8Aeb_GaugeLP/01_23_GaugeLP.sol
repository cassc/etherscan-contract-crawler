// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IGovernorTimelock} from "@openzeppelin/contracts/governance/extensions/IGovernorTimelock.sol";

import {IRegistry} from "../../interfaces/IRegistry.sol";
import {IGaugeVoterV2} from "../../interfaces/IGaugeVoterV2.sol";
import {INFTLocker} from "../../interfaces/INFTLocker.sol";
import {IBribe} from "../../interfaces/IBribe.sol";
import {IGaugeV2} from "../../interfaces/IGaugeV2.sol";
import {INFTStaker} from "../../interfaces/INFTStaker.sol";
import {VersionedInitializable} from "../../proxy/VersionedInitializable.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
contract GaugeLP is IGaugeV2, VersionedInitializable {
    IRegistry public override registry;
    address public stake; // the LP token that needs to be staked for rewards

    uint256 public derivedSupply;
    mapping(address => uint256) public derivedBalances;

    uint256 internal DURATION;
    uint256 internal PRECISION;

    mapping(address => bool) public attached;

    // default snx staking contract implementation
    mapping(address => uint256) public rewardRate;
    mapping(address => uint256) public periodFinish;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public rewardPerTokenStored;

    uint256 public maxBoostRequirement;

    mapping(address => mapping(address => uint256)) public lastEarn;
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenStored;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    address[] public rewards;
    mapping(address => bool) public isReward;

    /// @notice A record of balance checkpoints for each account, by index
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint256) public numCheckpoints;

    /// @notice A record of balance checkpoints for each token, by index
    mapping(uint256 => SupplyCheckpoint) public supplyCheckpoints;

    /// @notice The number of checkpoints
    uint256 public supplyNumCheckpoints;

    /// @notice A record of balance checkpoints for each token, by index
    mapping(address => mapping(uint256 => RewardPerTokenCheckpoint))
        public rewardPerTokenCheckpoints;

    /// @notice The number of checkpoints for each token
    mapping(address => uint256) public rewardPerTokenNumCheckpoints;

    // simple re-entrancy check
    uint256 internal _unlocked = 0;
    modifier lock() {
        require(_unlocked == 0, "reentrancy");
        _unlocked = 1;
        _;
        _unlocked = 0;
    }

    function initialize(address _registry, address _stake) public initializer {
        stake = _stake;
        registry = IRegistry(_registry);

        _unlocked = 0;
        maxBoostRequirement = 5000e18; // 5000 MAHAX for max boost

        DURATION = 14 days; // rewards are released over 14 days
        PRECISION = 10**18;
    }

    function getRevision() public pure virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Determine the prior balance for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param timestamp The timestamp to get the balance at
     * @return The balance the account had as of the given block
     */
    function getPriorBalanceIndex(address account, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) return 0;

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].timestamp <= timestamp)
            return (nCheckpoints - 1);

        // Next check implicit zero balance
        if (checkpoints[account][0].timestamp > timestamp) return 0;

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.timestamp == timestamp) return center;
            else if (cp.timestamp < timestamp) lower = center;
            else upper = center - 1;
        }
        return lower;
    }

    function getPriorSupplyIndex(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 nCheckpoints = supplyNumCheckpoints;
        if (nCheckpoints == 0) return 0;

        // First check most recent balance
        if (supplyCheckpoints[nCheckpoints - 1].timestamp <= timestamp)
            return (nCheckpoints - 1);

        // Next check implicit zero balance
        if (supplyCheckpoints[0].timestamp > timestamp) return 0;

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            SupplyCheckpoint memory cp = supplyCheckpoints[center];
            if (cp.timestamp == timestamp) return center;
            else if (cp.timestamp < timestamp) lower = center;
            else upper = center - 1;
        }
        return lower;
    }

    function getPriorRewardPerToken(address token, uint256 timestamp)
        public
        view
        returns (uint256, uint256)
    {
        uint256 nCheckpoints = rewardPerTokenNumCheckpoints[token];
        if (nCheckpoints == 0) return (0, 0);

        // First check most recent balance
        if (
            rewardPerTokenCheckpoints[token][nCheckpoints - 1].timestamp <=
            timestamp
        ) {
            return (
                rewardPerTokenCheckpoints[token][nCheckpoints - 1]
                    .rewardPerToken,
                rewardPerTokenCheckpoints[token][nCheckpoints - 1].timestamp
            );
        }

        // Next check implicit zero balance
        if (rewardPerTokenCheckpoints[token][0].timestamp > timestamp)
            return (0, 0);

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            RewardPerTokenCheckpoint memory cp = rewardPerTokenCheckpoints[
                token
            ][center];
            if (cp.timestamp == timestamp) {
                return (cp.rewardPerToken, cp.timestamp);
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return (
            rewardPerTokenCheckpoints[token][lower].rewardPerToken,
            rewardPerTokenCheckpoints[token][lower].timestamp
        );
    }

    function _writeCheckpoint(address account, uint256 balance) internal {
        uint256 _timestamp = block.timestamp;
        uint256 _nCheckPoints = numCheckpoints[account];

        if (
            _nCheckPoints > 0 &&
            checkpoints[account][_nCheckPoints - 1].timestamp == _timestamp
        ) {
            checkpoints[account][_nCheckPoints - 1].balanceOf = balance;
        } else {
            checkpoints[account][_nCheckPoints] = Checkpoint(
                _timestamp,
                balance
            );
            numCheckpoints[account] = _nCheckPoints + 1;
        }
    }

    function _writeRewardPerTokenCheckpoint(
        address token,
        uint256 reward,
        uint256 timestamp
    ) internal {
        uint256 _nCheckPoints = rewardPerTokenNumCheckpoints[token];

        if (
            _nCheckPoints > 0 &&
            rewardPerTokenCheckpoints[token][_nCheckPoints - 1].timestamp ==
            timestamp
        ) {
            rewardPerTokenCheckpoints[token][_nCheckPoints - 1]
                .rewardPerToken = reward;
        } else {
            rewardPerTokenCheckpoints[token][
                _nCheckPoints
            ] = RewardPerTokenCheckpoint(timestamp, reward);
            rewardPerTokenNumCheckpoints[token] = _nCheckPoints + 1;
        }
    }

    function _writeSupplyCheckpoint() internal {
        uint256 _nCheckPoints = supplyNumCheckpoints;
        uint256 _timestamp = block.timestamp;

        if (
            _nCheckPoints > 0 &&
            supplyCheckpoints[_nCheckPoints - 1].timestamp == _timestamp
        ) {
            supplyCheckpoints[_nCheckPoints - 1].supply = derivedSupply;
        } else {
            supplyCheckpoints[_nCheckPoints] = SupplyCheckpoint(
                _timestamp,
                derivedSupply
            );
            supplyNumCheckpoints = _nCheckPoints + 1;
        }
    }

    function rewardsListLength() external view returns (uint256) {
        return rewards.length;
    }

    // returns the last time the reward was modified or periodFinish if the reward has ended
    function lastTimeRewardApplicable(address token)
        public
        view
        returns (uint256)
    {
        return Math.min(block.timestamp, periodFinish[token]);
    }

    function getReward(address account, address[] memory tokens)
        external
        override
        lock
    {
        registry.ensureNotPaused();
        require(
            msg.sender == account || msg.sender == registry.gaugeVoter(),
            "sender not account or voter"
        );

        _unlocked = 1;
        IGaugeVoterV2(registry.gaugeVoter()).distribute(address(this));
        _unlocked = 2;

        for (uint256 i = 0; i < tokens.length; i++) {
            (
                rewardPerTokenStored[tokens[i]],
                lastUpdateTime[tokens[i]]
            ) = _updateRewardPerToken(tokens[i]);

            uint256 _reward = earned(tokens[i], account);
            lastEarn[tokens[i]][account] = block.timestamp;
            userRewardPerTokenStored[tokens[i]][account] = rewardPerTokenStored[
                tokens[i]
            ];
            if (_reward > 0) _safeTransfer(tokens[i], account, _reward);

            emit ClaimRewards(msg.sender, tokens[i], _reward);
        }

        uint256 _derivedBalance = derivedBalances[account];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply += _derivedBalance;

        _writeCheckpoint(account, derivedBalances[account]);
        _writeSupplyCheckpoint();
    }

    function rewardPerToken(address token) public view returns (uint256) {
        if (derivedSupply == 0) {
            return rewardPerTokenStored[token];
        }
        return
            rewardPerTokenStored[token] +
            (((lastTimeRewardApplicable(token) -
                Math.min(lastUpdateTime[token], periodFinish[token])) *
                rewardRate[token] *
                PRECISION) / derivedSupply);
    }

    function derivedBalance(address account) public view returns (uint256) {
        uint256 _balance = balanceOf[account];

        uint256 _derived = (_balance * 20) / 100;
        uint256 _stake = INFTStaker(registry.staker()).balanceOf(account);

        uint256 _adjusted = ((_balance * _stake * 80) / maxBoostRequirement) /
            100;

        // because of this we are able to max out the boost by 5x
        return Math.min(_derived + _adjusted, _balance);
    }

    function batchRewardPerToken(address token, uint256 maxRuns) external {
        (
            rewardPerTokenStored[token],
            lastUpdateTime[token]
        ) = _batchRewardPerToken(token, maxRuns);
    }

    function _batchRewardPerToken(address token, uint256 maxRuns)
        internal
        returns (uint256, uint256)
    {
        uint256 _startTimestamp = lastUpdateTime[token];
        uint256 reward = rewardPerTokenStored[token];

        if (supplyNumCheckpoints == 0) {
            return (reward, _startTimestamp);
        }

        if (rewardRate[token] == 0) {
            return (reward, block.timestamp);
        }

        uint256 _startIndex = getPriorSupplyIndex(_startTimestamp);
        uint256 _endIndex = Math.min(supplyNumCheckpoints - 1, maxRuns);

        for (uint256 i = _startIndex; i < _endIndex; i++) {
            SupplyCheckpoint memory sp0 = supplyCheckpoints[i];
            if (sp0.supply > 0) {
                SupplyCheckpoint memory sp1 = supplyCheckpoints[i + 1];
                (uint256 _reward, uint256 _endTime) = _calcRewardPerToken(
                    token,
                    sp1.timestamp,
                    sp0.timestamp,
                    sp0.supply,
                    _startTimestamp
                );
                reward += _reward;
                _writeRewardPerTokenCheckpoint(token, reward, _endTime);
                _startTimestamp = _endTime;
            }
        }

        return (reward, _startTimestamp);
    }

    function _calcRewardPerToken(
        address token,
        uint256 timestamp1,
        uint256 timestamp0,
        uint256 supply,
        uint256 startTimestamp
    ) internal view returns (uint256, uint256) {
        uint256 endTime = Math.max(timestamp1, startTimestamp);
        return (
            (((Math.min(endTime, periodFinish[token]) -
                Math.min(
                    Math.max(timestamp0, startTimestamp),
                    periodFinish[token]
                )) *
                rewardRate[token] *
                PRECISION) / supply),
            endTime
        );
    }

    function _updateRewardPerToken(address token)
        internal
        returns (uint256, uint256)
    {
        uint256 _startTimestamp = lastUpdateTime[token];
        uint256 reward = rewardPerTokenStored[token];

        if (supplyNumCheckpoints == 0) {
            return (reward, _startTimestamp);
        }

        if (rewardRate[token] == 0) {
            return (reward, block.timestamp);
        }

        uint256 _startIndex = getPriorSupplyIndex(_startTimestamp);
        uint256 _endIndex = supplyNumCheckpoints - 1;

        if (_endIndex - _startIndex > 1) {
            for (uint256 i = _startIndex; i < _endIndex - 1; i++) {
                SupplyCheckpoint memory sp0 = supplyCheckpoints[i];
                if (sp0.supply > 0) {
                    SupplyCheckpoint memory sp1 = supplyCheckpoints[i + 1];
                    (uint256 _reward, uint256 _endTime) = _calcRewardPerToken(
                        token,
                        sp1.timestamp,
                        sp0.timestamp,
                        sp0.supply,
                        _startTimestamp
                    );
                    reward += _reward;
                    _writeRewardPerTokenCheckpoint(token, reward, _endTime);
                    _startTimestamp = _endTime;
                }
            }
        }

        SupplyCheckpoint memory sp = supplyCheckpoints[_endIndex];
        if (sp.supply > 0) {
            (uint256 _reward, ) = _calcRewardPerToken(
                token,
                lastTimeRewardApplicable(token),
                Math.max(sp.timestamp, _startTimestamp),
                sp.supply,
                _startTimestamp
            );
            reward += _reward;
            _writeRewardPerTokenCheckpoint(token, reward, block.timestamp);
            _startTimestamp = block.timestamp;
        }

        return (reward, _startTimestamp);
    }

    // earned is an estimation, it won't be exact till the supply > rewardPerToken calculations have run
    function earned(address token, address account)
        public
        view
        returns (uint256)
    {
        uint256 _startTimestamp = Math.max(
            lastEarn[token][account],
            rewardPerTokenCheckpoints[token][0].timestamp
        );
        if (numCheckpoints[account] == 0) {
            return 0;
        }

        uint256 _startIndex = getPriorBalanceIndex(account, _startTimestamp);
        uint256 _endIndex = numCheckpoints[account] - 1;

        uint256 reward = 0;

        if (_endIndex - _startIndex > 1) {
            for (uint256 i = _startIndex; i < _endIndex - 1; i++) {
                Checkpoint memory cp0 = checkpoints[account][i];
                Checkpoint memory cp1 = checkpoints[account][i + 1];
                (uint256 _rewardPerTokenStored0, ) = getPriorRewardPerToken(
                    token,
                    cp0.timestamp
                );
                (uint256 _rewardPerTokenStored1, ) = getPriorRewardPerToken(
                    token,
                    cp1.timestamp
                );
                reward +=
                    (cp0.balanceOf *
                        (_rewardPerTokenStored1 - _rewardPerTokenStored0)) /
                    PRECISION;
            }
        }

        Checkpoint memory cp = checkpoints[account][_endIndex];
        (uint256 _rewardPerTokenStored, ) = getPriorRewardPerToken(
            token,
            cp.timestamp
        );
        reward +=
            (cp.balanceOf *
                (rewardPerToken(token) -
                    Math.max(
                        _rewardPerTokenStored,
                        userRewardPerTokenStored[token][account]
                    ))) /
            PRECISION;

        return reward;
    }

    function depositAll() external {
        deposit(IERC20(stake).balanceOf(msg.sender));
    }

    function deposit(uint256 amount) public lock {
        registry.ensureNotPaused();
        require(amount > 0, "amount = 0");

        _safeTransferFrom(stake, msg.sender, address(this), amount);
        totalSupply += amount;
        balanceOf[msg.sender] += amount;

        uint256 _derivedBalance = derivedBalances[msg.sender];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(msg.sender);
        derivedBalances[msg.sender] = _derivedBalance;
        derivedSupply += _derivedBalance;

        if (!attached[msg.sender]) {
            attached[msg.sender] = true;
            IGaugeVoterV2(registry.gaugeVoter()).attachStakerToGauge(
                msg.sender
            );
        }

        _writeCheckpoint(msg.sender, _derivedBalance);
        _writeSupplyCheckpoint();

        emit Deposit(msg.sender, amount);
    }

    function withdrawAll() external {
        withdraw(balanceOf[msg.sender]);
    }

    function withdraw(uint256 amount) public {
        withdrawToken(amount);
    }

    function withdrawToken(uint256 amount) public lock {
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        _safeTransfer(stake, msg.sender, amount);

        if (amount == balanceOf[msg.sender] && attached[msg.sender]) {
            attached[msg.sender] = false;
            IGaugeVoterV2(registry.gaugeVoter()).detachStakerFromGauge(
                msg.sender
            );
        }

        uint256 _derivedBalance = derivedBalances[msg.sender];
        derivedSupply -= _derivedBalance;
        _derivedBalance = derivedBalance(msg.sender);
        derivedBalances[msg.sender] = _derivedBalance;
        derivedSupply += _derivedBalance;

        _writeCheckpoint(msg.sender, derivedBalances[msg.sender]);
        _writeSupplyCheckpoint();

        emit Withdraw(msg.sender, amount);
    }

    function left(address token) external view override returns (uint256) {
        if (block.timestamp >= periodFinish[token]) return 0;
        uint256 _remaining = periodFinish[token] - block.timestamp;
        return _remaining * rewardRate[token];
    }

    function notifyRewardAmount(address token, uint256 amount)
        external
        override
        lock
    {
        require(token != stake, "token = stake");
        require(amount > 0, "amount = 0");
        if (rewardRate[token] == 0)
            _writeRewardPerTokenCheckpoint(token, 0, block.timestamp);
        (
            rewardPerTokenStored[token],
            lastUpdateTime[token]
        ) = _updateRewardPerToken(token);

        if (block.timestamp >= periodFinish[token]) {
            _safeTransferFrom(token, msg.sender, address(this), amount);
            rewardRate[token] = amount / DURATION;
        } else {
            uint256 _remaining = periodFinish[token] - block.timestamp;
            uint256 _left = _remaining * rewardRate[token];
            require(amount > _left, "amount > left");
            _safeTransferFrom(token, msg.sender, address(this), amount);
            rewardRate[token] = (amount + _left) / DURATION;
        }

        require(rewardRate[token] > 0, "rewardrate = 0");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(
            rewardRate[token] <= balance / DURATION,
            "Provided reward too high"
        );
        periodFinish[token] = block.timestamp + DURATION;

        if (!isReward[token]) {
            isReward[token] = true;
            rewards.push(token);
        }

        emit NotifyReward(msg.sender, token, amount);
    }

    /// @dev in case admin needs to execute some calls directly
    function emergencyCall(address target, bytes memory signature)
        external
        onlyTimelock
    {
        (bool success, bytes memory response) = target.call(signature);
        require(success, string(response));
    }

    function setMaxBoost(uint256 _maxBoostRequirement) external onlyTimelock {
        emit MaxBoostRequirementChanged(
            maxBoostRequirement,
            _maxBoostRequirement
        );
        maxBoostRequirement = _maxBoostRequirement;
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0, "invalid code length");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "transfer failed"
        );
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.code.length > 0, "invalid code length");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "transferFrom failed"
        );
    }

    function _safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        require(token.code.length > 0, "invalid code length");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "approve failed"
        );
    }

    modifier onlyTimelock() {
        require(
            msg.sender == IGovernorTimelock(registry.governor()).timelock(),
            "not timelock"
        );
        _;
    }
}