// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Base
import "./base/TokenSaver.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


//Utils
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./libraries/LowGasSafeMath.sol";


contract FanTokenStaking is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    TokenSaver
{
    using LowGasSafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

     uint32 public constant monthInSeconds = 300; // 5 min
//     uint32 public constant monthInSeconds = 2628000;

    uint32 public constant PERIOD_DECIMALS = 1000;
    uint8 public constant APY_PERIOD = 12;

    struct Deposit {
        address depositToken;
        uint256 amount;
        uint8 aFactor;
        uint8 period;
        uint64 start;
        uint64 end;
        uint256 reward;
        bool claim;
    }

    struct TotalDeposits {
        address depositToken;
        uint256 depositId;
        uint256 amount;
    }

    struct Rewards {
        address receiver;
        uint256 depositId;
    }

    IERC20Upgradeable public rewardToken;
    uint256 public rewordTokenRate;

    // @dev Deposit tokenAddress => percent reword
    mapping(address => uint256) public depositTokensRates;

    address[] public depositFanToken;

    // @dev tokenAddress => amount Locked token amount
    mapping(address => uint256) public totalLocked;

    // @dev number of months to percent reword
    mapping(uint8 => uint8) public aFactors;

    // @dev receiver => Deposit struct
    mapping(address => Deposit[]) public depositsOf;

    /**
   * @dev Minimum amount of tokens that can be deposited.
   * If zero, there is no minimum.
   */
    uint96 public minimumDeposit;

    uint256 private unlocked;

    uint256 public startPeriod;

    // Reward from period
    mapping(uint256 => Rewards[]) rewardsFromPeriod;

    modifier lock() {
        require(unlocked == 1, "FanTokenStaking: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // Events
    event RewardsClaimed(uint256 depositId, address fanTokenAddress, uint256 amount, address indexed receiver, uint256 timestamp);
    event Deposited(uint256 depositId, address fanTokenAddress, uint256 amount, uint256 start, uint256 end, uint8 aFactor, address indexed receiver, address indexed from);
    event Withdrawn(uint256 indexed depositId, address indexed receiver, address indexed from, uint256 amount, uint256 timestamp);
    event DepositDestroyed(uint256 indexed depositId, address indexed account, uint256 amount);
    event AddRewords(address indexed from, uint256 amount, uint256 period);

    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _rewardToken,
        uint256 _rewordTokenRate,
        address[] memory _depositTokens,
        uint256[] memory _depositTokensRates
    ) external initializer {
        __Ownable_init();
        __Pausable_init();

        rewardToken = IERC20Upgradeable(_rewardToken);
        rewordTokenRate = _rewordTokenRate;

        setTokenRates(_depositTokens, _depositTokensRates);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        minimumDeposit = 10**3;
        unlocked = 1;

        startPeriod = block.timestamp;

        aFactors[6] = 70; // 7%
        aFactors[7] = 75; // 7,5%
        aFactors[8] = 80; // 8%
        aFactors[9] = 85; // 8,5%
        aFactors[10] = 90; // 9%
        aFactors[11] = 95; // 9,5%
        aFactors[12] = 100; // 10%
    }

   /**
   * @dev Deposit `amount` of `depositToken` for `duration` month.
   *
   * Uses transferFrom - caller must have approved the contract to spend `amount`
   * of `depositToken`.
   *
   * If the emergency unlock has been triggered, deposits will fail.
   *
   * `amount` must be greater than `minimumDeposit`.
   */
    function deposit(address _depositToken, uint256 _amount, uint8 _stakingPeriodMonth, address _receiver)
    external lock whenNotPaused {
        require(_amount > minimumDeposit, "FanTokenStaking.deposit: Minimum deposit");
        require(depositTokensRates[_depositToken] > 0, "FanTokenStaking.deposit: Wrong token");

        uint8 _aFactor = aFactors[_stakingPeriodMonth];
        require(_aFactor > 0, "FanTokenStaking.deposit: Wrong period");

        IERC20Upgradeable(_depositToken).safeTransferFrom(_msgSender(), address(this), _amount);

        uint64 _endPeriod = uint64(block.timestamp) + uint64(_stakingPeriodMonth) * monthInSeconds;
        uint256 _depositId = depositsOf[_receiver].length;

        depositsOf[_receiver].push(Deposit({
            depositToken : _depositToken,
            amount : _amount,
            aFactor : _aFactor,
            period : _stakingPeriodMonth,
            start : uint64(block.timestamp),
            end : _endPeriod,
            claim: false,
            reward: 0
        }));

        uint256 claimPeriod = (_endPeriod - startPeriod) / monthInSeconds + 1;
        rewardsFromPeriod[claimPeriod].push(Rewards({
            receiver: _receiver,
            depositId: _depositId
        }));

        totalLocked[_depositToken] += _amount;

        emit Deposited(_depositId, _depositToken, _amount, block.timestamp, _endPeriod, _aFactor, _receiver, _msgSender());
    }

   /**
   * @dev Withdraw the tokens locked in `_depositId`.
   * The caller will incur an early withdrawal fee if the lock duration has not elapsed.
   * All of the dividend tokens received when the lock was created will be burned from the
   * caller's account.
   * This can only be executed by the lock owner.
   */
    function destroyLock(uint256 _depositId) external lock {
        uint256 _amount = depositsOf[_msgSender()][_depositId].amount;
        _withdraw(_depositId, _amount);

        emit DepositDestroyed(_depositId, _msgSender(), _amount);
    }

   /**
   * @dev Claim reword tokens and Withdraw the tokens locked in `_depositId`.
   * At the end of the period, all dividend tokens, will be returned
   * This can only be executed by the deposit owner.
   */
    function claimAndWithdraw(uint256 _depositId) public lock whenNotPaused {
        require(_depositId < depositsOf[_msgSender()].length, "FanTokenStaking.claimAndWithdraw: Deposit does not exist");
        Deposit memory userDeposit = depositsOf[_msgSender()][_depositId];

        require(userDeposit.claim == false, "FanTokenStaking.claimAndWithdraw: Deposit is clime");

        require(block.timestamp >= userDeposit.end, "FanTokenStaking.claimAndWithdraw: too soon");
        require(depositsOf[_msgSender()][_depositId].amount >= minimumDeposit, "FanTokenStaking.claimAndWithdraw: min amount");
        require(depositsOf[_msgSender()][_depositId].reward > 0, "FanTokenStaking.claimAndWithdraw: Rewards not distributed");


        uint256 shareAmount = depositsOf[_msgSender()][_depositId].reward;
        require(rewardToken.balanceOf(address(this)) >= shareAmount, "FanTokenStaking.claimAndWithdraw: not enough balance");

        _withdraw(_depositId, userDeposit.amount);

        depositsOf[_msgSender()][_depositId].claim = true;
        rewardToken.safeTransfer(_msgSender(), shareAmount);

        emit RewardsClaimed(_depositId, userDeposit.depositToken, shareAmount, _msgSender(), block.timestamp);
    }

    /**
    * @dev Bath clime an withdraw
    * This can only be executed by the deposit owner
    */
    function bathClimeAndWithdraw() external {
        require(depositsOf[_msgSender()].length > 0, "FanTokenStaking.bathClimeAndWithdraw: Deposits does not exist");
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < depositsOf[_msgSender()].length; i++) {
            if (block.timestamp >= depositsOf[_msgSender()][i].end
                && depositsOf[_msgSender()][i].amount > minimumDeposit
                && depositsOf[_msgSender()][i].reward > 0
                && depositsOf[_msgSender()][i].claim == false
            ) {
                totalRewards += depositsOf[_msgSender()][i].reward;
            }
        }

        require(totalRewards > 0, "FanTokenStaking.bathClimeAndWithdraw: no deposits for the clime");

        for (uint256 i = 0; i < depositsOf[_msgSender()].length; i++) {
            if (block.timestamp >= depositsOf[_msgSender()][i].end && depositsOf[_msgSender()][i].amount > minimumDeposit && depositsOf[_msgSender()][i].reward > 0) {
                claimAndWithdraw(i);
            }
        }
    }

    function _withdraw(uint256 _depositId, uint256 _amount) internal {
        Deposit memory userDeposit = depositsOf[_msgSender()][_depositId];

        require(userDeposit.amount > minimumDeposit && userDeposit.amount >= _amount, "TimeLockPool.withdraw: Insufficient balance");

        totalLocked[userDeposit.depositToken] -= userDeposit.amount;
        userDeposit.amount -= _amount;

        IERC20Upgradeable(userDeposit.depositToken).safeTransfer(_msgSender(), _amount);

        depositsOf[_msgSender()][_depositId] = userDeposit;
    }

    function calcDividendsMultiplier(address _token, uint8 _aFactor, uint8 _period, uint256 _amount)
    internal view returns (uint256 dividends, uint256 dividendsOfUsd, uint256 tokenAmountReword)
    {
        dividends = (_amount.mul(_aFactor) / PERIOD_DECIMALS).mul(_period * 10**8 / APY_PERIOD) / 10**8;
        dividendsOfUsd = depositTokensRates[_token].mul(dividends);
        tokenAmountReword = dividendsOfUsd / rewordTokenRate;
    }

    function calcDividends(address _token, uint8 _period, uint256 _amount)
    public view returns (uint8 aFactor, uint256 reword) {
        aFactor = aFactors[_period];
        (,,reword) = calcDividendsMultiplier(_token, aFactor, _period, _amount);
    }

    function getTotalDeposits(address _account) public view returns (TotalDeposits[] memory) {
        TotalDeposits[] memory total = new TotalDeposits[](depositFanToken.length);
        TotalDeposits memory totalDeposit;
        for (uint256 tai = 0; tai < depositFanToken.length; tai++) {
            totalDeposit.depositToken = depositFanToken[tai];

            totalDeposit.amount = 0;
            for (uint256 i = 0; i < depositsOf[_account].length; i++) {
                totalDeposit.depositId = i;
                if (depositFanToken[tai] == depositsOf[_account][i].depositToken) {
                    totalDeposit.amount += depositsOf[_account][i].amount;
                }
            }
            total[tai] = totalDeposit;
        }

        return total;
    }

    function getDepositsOf(address _account) public view returns (Deposit[] memory) {
        return depositsOf[_account];
    }

    function getDepositsOfLength(address _account) public view returns (uint256) {
        return depositsOf[_account].length;
    }

    function setTokenRates(address[] memory _depositTokens, uint256[] memory _rates)
    internal {
        require(_depositTokens.length == _rates.length, "FanTokenStaking.setTokenRates: quantity");
        for (uint256 i = 0; i < _depositTokens.length; i++) {
            require(_depositTokens[i] != address(0), "FanTokenStaking.setRewordTokenRate: zero address");
            if (!existsFanToken(_depositTokens[i])) {
                depositFanToken.push(_depositTokens[i]);
            }

            depositTokensRates[_depositTokens[i]] = _rates[i];
        }
    }

    function existsFanToken(address _depositToken) public view returns (bool) {
        for (uint i = 0; i < depositFanToken.length; i++) {
            if (depositFanToken[i] == _depositToken) {
                return true;
            }
        }
        return false;
    }

    function updateTokenRate(address[] memory _tokens, uint256[] memory _rates)
    external onlyRole(DEFAULT_ADMIN_ROLE) {
        setTokenRates(_tokens, _rates);
    }

    function setRewordTokenRate(uint256 _rewordTokenRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_rewordTokenRate > 0, "FanTokenStaking.setRewordTokenRate: zero");
        rewordTokenRate = _rewordTokenRate;
    }

    function setMinimumDeposit(uint96 _minimumDeposit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minimumDeposit = _minimumDeposit;
    }

    function updateAFactors(uint8[] memory _periods, uint8[] memory _percents) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_periods.length == _percents.length, "FanTokenStaking.updateAFactors: quantity");
        for (uint256 i = 0; i < _periods.length; i++) {
            aFactors[_periods[i]] = _percents[i];
        }
    }

    function calcRewardsFromPeriod(uint256 _period) public view returns(uint256 totalRewards) {
        Rewards memory reward;
        Deposit memory deposits;
        uint256 amount = 0;
        for (uint256 i = 0; i < rewardsFromPeriod[_period].length; i++) {
            reward = rewardsFromPeriod[_period][i];
            deposits = depositsOf[reward.receiver][reward.depositId];
            ( , amount) = calcDividends(deposits.depositToken, deposits.period, deposits.amount);
            if (deposits.reward == 0) {
                totalRewards += amount;
            }
        }
    }

    function distributeRewords(uint256 _startPeriod, uint256 _endPeriod) external {
        uint256 totalAmount = 0;

        for (uint256 i = _startPeriod; i <= _endPeriod; i++) {
            totalAmount += calcRewardsFromPeriod(i);
        }

        require(totalAmount > 0, "distributeRewords: Rewards have already been distributed or no rewards are required for this period");
        require(rewardToken.balanceOf(_msgSender()) >= totalAmount, "FanTokenStaking.distributeRewords: Insufficient balance");

        Rewards memory reward;
        Deposit memory deposits;
        uint256 _amount = 0;

        if (totalAmount > 0) {
            for (uint256 _period = _startPeriod; _period <= _endPeriod; _period++) {
                for (uint256 i = 0; i < rewardsFromPeriod[_period].length; i++) {
                    reward = rewardsFromPeriod[_period][i];
                    deposits = depositsOf[reward.receiver][reward.depositId];
                    ( , _amount) = calcDividends(deposits.depositToken, deposits.period, deposits.amount);

                    depositsOf[reward.receiver][reward.depositId].reward = _amount;
                }
                emit AddRewords(_msgSender(), _amount, _period);
            }

            rewardToken.safeTransferFrom(_msgSender(), address(this), totalAmount);
        }
    }

    function getCurrentPeriod() external view returns(uint256) {
        return (block.timestamp - startPeriod) / monthInSeconds + 1;
    }

    function getTotalDistributeRewardsFromPeriods(uint256 _from, uint256 _to) external view
    returns(uint256 totalDistributeAmount, uint256 totalClimedAmount)
    {
        totalDistributeAmount = 0;
        totalClimedAmount = 0;

        Rewards memory _reward;
        Deposit memory _deposit;

        for (uint256 _period = _from; _period <= _to; _period++) {
            for (uint256 i = 0; i < rewardsFromPeriod[_period].length; i++) {
                    _reward = rewardsFromPeriod[_period][i];
                    _deposit = depositsOf[_reward.receiver][_reward.depositId];
                    totalDistributeAmount += _deposit.reward;
                    if (_deposit.claim) {
                        totalClimedAmount += _deposit.reward;
                    }
            }
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}