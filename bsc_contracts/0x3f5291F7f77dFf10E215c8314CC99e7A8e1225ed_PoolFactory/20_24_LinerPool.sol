//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IPoolFactory.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

contract LinearPool is ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant MOD = keccak256("MOD");
    bytes32 public constant ADMIN = keccak256("ADMIN");
    uint256 private constant ONE_YEAR_IN_SECONDS = 365 days;

    // End pool
    bool public isEnd;
    // Pool creator
    address public factory;
    // The reward distribution address
    address public linearRewardDistributor;
    // Max token numbers can stake into this pool
    uint256 public cap;
    // APR of this pool
    uint256 public APR;
    // Lock time to claim reward after staked
    uint256 public lockDuration;
    // Can stake time
    uint256 public startJoinTime;
    // End of stake time
    uint256 public endJoinTime;
    // All token stake
    uint256[] public totalStaked;
    // The accepted token
    IERC20[] public linearAcceptedToken;
    // Reward token
    IERC20[] public linearRewardToken;
    // The accepted token address type
    address[] public linearAcceptedTokenAddress;
    // Token rate each pool
    uint256[] public stakedTokenRate;
    // Cap with decimals
    uint256[] public decimalsCap;
    // decimals of tokens
    uint8[] public decimalsToken;

    // Info of each user that stakes in pool
    mapping(address => LinearStakingData) public linearStakingData;
    // Allow emergency withdraw feature
    bool public linearAllowEmergencyWithdraw;

    event LinearEnded(address pool);
    event LinearDeposit(address indexed account, uint256[] amount);
    event LinearWithdraw(address indexed account, uint256[] amount);
    event LinearRewardsHarvested(address indexed account, uint256[] reward);
    event LinearPendingWithdraw(address indexed account, uint256[] amount);
    event LinearEmergencyWithdraw(address indexed account, uint256[] amount);

    struct LinearStakingData {
        uint256[] balance;
        uint256[] reward;
        uint256 joinTime;
        uint256 updatedTime;
    }

    event AdminRecoverFund(address token, address to, uint256 amount);
    event RewardDisTributor(address reward);

    modifier isMod() {
        require(
            IAccessControlUpgradeable(factory).hasRole(MOD, msg.sender),
            "LinearStakingPool: forbidden"
        );
        _;
    }

    modifier isAdmin() {
        require(
            IAccessControlUpgradeable(factory).hasRole(ADMIN, msg.sender),
            "LinearStakingPool: forbidden"
        );
        _;
    }

    /**
     * @notice Initialize the contract, get called in the first time deploy
     */
    function initialize() external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();

        (
            address[] memory _stakeToken,
            address[] memory _saleToken,
            uint256[] memory _stakedTokenRate,
            uint256 _APR,
            uint256 _cap,
            uint256 _startTimeJoin,
            uint256 _endTimeJoin,
            uint256 _lockDuration,
            address _rewardDistributor
        ) = IPoolFactory(msg.sender).getLinerParameters();

        uint256 _rewardLength = _stakeToken.length;

        require(
            _rewardLength == _saleToken.length &&
                _rewardLength == _stakedTokenRate.length,
            "LinearStakingPool: invalid token length"
        );

        for (uint256 i = 0; i < _rewardLength; i = unsafe_inc(i)) {
            require(
                _saleToken[i] != address(0) && _stakeToken[i] != address(0),
                "LinearStakingPool: invalid token address"
            );

            require(
                _stakeToken[i] == _saleToken[i],
                "LinearStakingPool: stake token and reward token must be the same"
            );

            linearAcceptedToken.push(IERC20(_stakeToken[i]));
            linearRewardToken.push(IERC20(_saleToken[i]));
            totalStaked.push(0);

            uint8 _decimals = _getDecimals(_saleToken[i]);
            decimalsToken.push(_decimals);
            uint256 _formatedCap = (_cap / 1e18) * (10**_decimals);
            decimalsCap.push(_formatedCap);
        }
        linearAcceptedTokenAddress = _stakeToken;
        stakedTokenRate = _stakedTokenRate;
        factory = msg.sender;
        APR = _APR;
        cap = _cap;
        startJoinTime = _startTimeJoin;
        endJoinTime = _endTimeJoin;
        lockDuration = _lockDuration;
        linearRewardDistributor = _rewardDistributor;
    }

    /**
     * @notice Pause contract
     */
    function pauseContract() external isMod {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpauseContract() external isMod {
        _unpause();
    }

    /**
     * @notice Admin withdraw tokens from a contract
     * @param _token token to withdraw
     * @param _to to user address
     * @param _amount amount to withdraw
     */
    function linearAdminRecoverFund(
        address _token,
        address _to,
        uint256 _amount
    ) external isAdmin {
        IERC20(_token).safeTransfer(_to, _amount);
        emit AdminRecoverFund(_token, _to, _amount);
    }

    function linearSetPool() external isMod {
        require(!isEnd, "LinearPool: Pool already ended");
        isEnd = true;
        endJoinTime = block.timestamp;
        emit LinearEnded(address(this));
    }

    /**
     * @notice Deposit token to earn rewards
     * @param _amount amount of token to deposit
     */
    function linearDeposit(uint256[] calldata _amount)
        external
        nonReentrant
        whenNotPaused
    {
        address account = msg.sender;

        _linearDeposit(_amount, account);

        for (uint256 i = 0; i < _amount.length; i = unsafe_inc(i)) {
            linearAcceptedToken[i].safeTransferFrom(
                account,
                address(this),
                _amount[i]
            );
        }
        emit LinearDeposit(account, _amount);
    }

    /**
     * @notice Withdraw token from a pool
     * @param _amount amount to withdraw
     */
    function linearWithdraw(uint256[] memory _amount)
        external
        nonReentrant
        whenNotPaused
    {
        address account = msg.sender;
        LinearStakingData storage stakingData = linearStakingData[account];

        require(
            block.timestamp >= stakingData.joinTime + lockDuration,
            "LinearStakingPool: still locked"
        );

        require(
            stakingData.balance.length > 0,
            "LinearStakingPool: nothing to withdraw"
        );

        _linearHarvest(account);
        require(
            linearRewardDistributor != address(0),
            "LinearStakingPool: invalid distributor"
        );

        for (uint256 i = 0; i < stakingData.balance.length; i = unsafe_inc(i)) {
            require(
                stakingData.balance[i] >= _amount[i],
                "LinearStakingPool: invalid amount"
            );

            stakingData.balance[i] -= _amount[i];
            totalStaked[i] -= _amount[i];
            linearAcceptedToken[i].safeTransfer(account, _amount[i]);
        }

        emit LinearWithdraw(account, _amount);
    }

    /**
     * @notice Claim reward token from a pool
     */
    function linearClaimReward() external nonReentrant whenNotPaused {
        address account = msg.sender;
        LinearStakingData storage stakingData = linearStakingData[account];

        require(
            block.timestamp >= stakingData.joinTime + lockDuration,
            "LinearStakingPool: still locked"
        );

        _linearHarvest(account);
        uint256[] memory _rewards = new uint256[](stakingData.balance.length);
        require(
            linearRewardDistributor != address(0),
            "LinearStakingPool: invalid distributor"
        );

        for (uint256 i = 0; i < stakingData.balance.length; i = unsafe_inc(i)) {
            if (stakingData.reward[i] > 0) {
                uint256 reward = stakingData.reward[i];
                stakingData.reward[i] = 0;
                linearRewardToken[i].safeTransferFrom(
                    linearRewardDistributor,
                    account,
                    reward
                );
                _rewards[i] = reward;
            }
        }
        emit LinearRewardsHarvested(account, _rewards);
    }

    /**
     * @notice Gets number of reward tokens of a user from a pool
     * @param _account address of a user
     * @return rewards earned reward of a user
     */
    function linearPendingReward(address _account)
        public
        view
        returns (uint256[] memory rewards)
    {
        LinearStakingData storage stakingData = linearStakingData[_account];
        uint256[] memory _stakedTokenRate = stakedTokenRate;
        uint256 sum;
        for (uint256 i = 0; i < _stakedTokenRate.length; i = unsafe_inc(i)) {
            sum += _stakedTokenRate[i];
        }
        uint256 startTime = stakingData.updatedTime > 0
            ? stakingData.updatedTime
            : block.timestamp;

        uint256 endTime = block.timestamp;

        if (endJoinTime > 0) endTime = endJoinTime;

        uint256 stakedTimeInSeconds = endTime > startTime
            ? endTime - startTime
            : 0;

        uint256 sumStaked = 0;
        uint8[] memory _decimalsToken = decimalsToken;
        for (uint256 i = 0; i < stakingData.balance.length; i = unsafe_inc(i)) {
            sumStaked += ((1e18 / (10**_decimalsToken[i])) *
                stakingData.balance[i]);
        }
        sumStaked =
            ((sumStaked * stakedTimeInSeconds * APR) / ONE_YEAR_IN_SECONDS) /
            1e20;

        rewards = new uint256[](stakingData.balance.length);
        for (uint256 i = 0; i < stakingData.balance.length; i = unsafe_inc(i)) {
            rewards[i] =
                stakingData.reward[i] +
                ((((sumStaked * _stakedTokenRate[i]) / sum) *
                    (10**_decimalsToken[i])) / 1e18);
        }
    }

    /**
     * @notice Gets number of deposited tokens in a pool
     * @param _account address of a user
     * @return total token deposited in a pool by a user
     */
    function linearBalanceOf(address _account)
        external
        view
        returns (uint256[] memory)
    {
        return linearStakingData[_account].balance;
    }

    /**
     * @notice Update allowance for emergency withdraw
     * @param _shouldAllow should allow emergency withdraw or not
     */
    function linearSetAllowEmergencyWithdraw(bool _shouldAllow) external {
        linearAllowEmergencyWithdraw = _shouldAllow;
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     */
    function linearEmergencyWithdraw() external nonReentrant whenNotPaused {
        require(
            linearAllowEmergencyWithdraw,
            "LinearStakingPool: emergency not allowed"
        );

        address account = msg.sender;
        LinearStakingData storage stakingData = linearStakingData[account];

        require(
            stakingData.balance.length > 0,
            "LinearStakingPool: nothing to withdraw"
        );

        uint256[] memory amount = stakingData.balance;

        stakingData.balance = new uint256[](stakingData.balance.length);
        stakingData.reward = new uint256[](stakingData.balance.length);
        stakingData.updatedTime = block.timestamp;

        for (uint256 i = 0; i < amount.length; i = unsafe_inc(i)) {
            totalStaked[i] -= amount[i];
            linearAcceptedToken[i].safeTransfer(account, amount[i]);
        }
        emit LinearEmergencyWithdraw(account, amount);
    }

    function _linearDeposit(uint256[] calldata _amount, address account)
        internal
    {
        LinearStakingData storage stakingData = linearStakingData[account];
 
        require(
            _amount.length == linearAcceptedToken.length,
            "LinearStakingPool: inffuse amounts"
        );

        require(
            block.timestamp >= startJoinTime,
            "LinearStakingPool: not started yet"
        );

        require(!isEnd, "LinearStakingPool: already closed");

        if (cap > 0) {
            uint256 sumAmount = 0;
            uint256 sumStaked = 0;
            address[]
                memory _linearAcceptedTokenAddress = linearAcceptedTokenAddress;
            for (
                uint256 i = 0;
                i < linearAcceptedTokenAddress.length;
                i = unsafe_inc(i)
            ) {
                uint8 _decimals = _getDecimals(_linearAcceptedTokenAddress[i]);
                sumAmount += (_amount[i] * (1e18 / (10**_decimals)));
                sumStaked += (totalStaked[i] * (1e18 / (10**_decimals)));
            }
            require(
                sumAmount + sumStaked <= cap,
                "LinearStakingPool: pool is full"
            );
        }

        _linearHarvest(account);

        for (uint256 i = 0; i < _amount.length; i = unsafe_inc(i)) {
            stakingData.balance[i] += _amount[i];
            totalStaked[i] += _amount[i];
        }

        stakingData.joinTime = block.timestamp;
    }

    function _linearHarvest(address _account) private {
        LinearStakingData storage stakingData = linearStakingData[_account];
        uint256 _length = stakingData.balance.length;
        if (_length == 0) {
            stakingData.balance = new uint256[](linearAcceptedToken.length);
            stakingData.reward = new uint256[](linearAcceptedToken.length);
        }
        stakingData.reward = linearPendingReward(_account);
        stakingData.updatedTime = block.timestamp;
    }

    function _getDecimals(address _token) internal view returns (uint8) {
        uint8 _decimals = _callOptionalReturn(
            IERC20Metadata(_token),
            abi.encodeWithSelector(IERC20Metadata(_token).decimals.selector)
        );
        require(_decimals >= 0, "LinearStakingPool: invalid decimals");
        return _decimals;
    }

    function _callOptionalReturn(IERC20 token, bytes memory data)
        private
        view
        returns (uint8)
    {
        uint8 decimals = 0;
        bytes memory returndata = address(token).functionStaticCall(
            data,
            "LinearStakingPool: not ERC20"
        );
        if (returndata.length > 0) {
            decimals = abi.decode(returndata, (uint8));
        }

        return decimals;
    }

    function unsafe_inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }
}