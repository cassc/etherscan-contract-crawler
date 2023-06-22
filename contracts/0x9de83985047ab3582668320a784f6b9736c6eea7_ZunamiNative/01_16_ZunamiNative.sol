//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IStrategy.sol';
import './interfaces/IZunamiRebalancer.sol';

/**
 *
 * @title Zunami Protocol v2
 *
 * @notice Contract for StakeDAO & Convex & Curve protocols optimize.
 * Users can use this contract for optimize yield and gas.
 *
 *
 * @dev Zunami is main contract.
 * Contract does not store user funds.
 * All user funds goes to StakeDAO & Convex & Curve pools.
 *
 */

contract ZunamiNative is ERC20, Pausable, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;

    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    uint256 public constant LP_RATIO_MULTIPLIER = 1e18;
    uint256 public constant FEE_DENOMINATOR = 100000;
    uint256 public constant MAX_FEE = 30000; // 30%
    uint256 public constant MIN_LOCK_TIME = 1 days;
    uint256 public constant FUNDS_DENOMINATOR = 10000000000;
    uint8 public constant ALL_WITHDRAWAL_TYPES_MASK = uint8(3); // Binary 11 = 2^0 + 2^1;
    address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant ETH_MOCK_TOKEN_ID = 0;

    uint8 public constant POOL_ASSETS = 5;

    struct PendingWithdrawal {
        uint256 lpShares;
        uint256[POOL_ASSETS] tokenAmounts;
    }

    struct PoolInfo {
        IStrategy strategy;
        uint256 startTime;
        uint256 lpShares;
        bool enabled;
    }

    PoolInfo[] internal _poolInfo;

    uint256 public defaultDepositPid;
    uint256 public defaultWithdrawPid;

    uint8 public availableWithdrawalTypes;
    uint128 public tokenCount;

    address[POOL_ASSETS] public tokens;
    uint256[POOL_ASSETS] public decimalsMultipliers;

    mapping(address => uint256[POOL_ASSETS]) internal _pendingDeposits;
    mapping(address => PendingWithdrawal) internal _pendingWithdrawals;

    uint256 public totalDeposited = 0;
    uint256 public managementFee = 15000; // 15%
    bool public launched = false;

    IZunamiRebalancer public rebalancer;

    event ManagementFeeSet(uint256 oldManagementFee, uint256 newManagementFee);
    event ChangedAvailableWithdrawalTypes(uint256 oldAvailableWithdrawalTypes, uint256 newAvailableWithdrawalTypes);
    event CreatedPendingDeposit(address indexed depositor, uint256[POOL_ASSETS] amounts);
    event CreatedPendingWithdrawal(
        address indexed withdrawer,
        uint256 lpShares,
        uint256[POOL_ASSETS] tokenAmounts
    );
    event RemovedPendingDeposit(address indexed depositor);

    event Deposited(
        address indexed depositor,
        uint256 depositedValue,
        uint256[POOL_ASSETS] amounts,
        uint256 lpShares,
        uint256 pid,
        bool optimized
    );

    event Withdrawn(
        address indexed withdrawer,
        uint256 lpShares,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex,
        uint256 pid,
        bool optimized
    );
    event FailedWithdrawal(
        address indexed withdrawer,
        uint256[POOL_ASSETS] amounts,
        uint256 lpShares,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex
    );

    event AddedPool(uint256 pid, address strategyAddr, uint256 startTime);
    event SetDefaultDepositPid(uint256 pid);
    event SetDefaultWithdrawPid(uint256 pid);
    event SetRebalancer(address rebalancerAddr);
    event ClaimedAllManagementFee(uint256 feeValue);
    event AutoCompoundAll(uint256 compoundedValue);
    event ChangedPoolEnabledStatus(address pool, bool newStatus);
    event UpdatedToken(
        uint256 tid,
        address token,
        uint256 tokenDecimalMultiplier,
        address tokenOld
    );

    modifier startedPool() {
        require(_poolInfo.length != 0, 'pools empty');
        require(
            block.timestamp >= _poolInfo[defaultDepositPid].startTime,
            'deposit not started'
        );
        require(
            block.timestamp >= _poolInfo[defaultWithdrawPid].startTime,
            'withdraw not started'
        );
        _;
    }

    modifier enabledPool(uint256 poolIndex) {
        require(poolIndex < _poolInfo.length && _poolInfo[poolIndex].enabled, 'not enabled');
        _;
    }

    constructor() ERC20('Zunami ETH LP', 'ethZLP') {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);

        availableWithdrawalTypes = ALL_WITHDRAWAL_TYPES_MASK;

        tokens[0] = ETH_MOCK_ADDRESS;
        decimalsMultipliers[0] = 1;
        tokenCount = 1;
    }

    receive() external payable {
        // receive ETH from strategy on moving funds
    }

    function addTokens(address[] memory _tokens, uint256[] memory _tokenDecimalMultipliers)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_tokens.length > 0, 'wrong length');
        uint128 tokenCount_ = tokenCount;
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_tokens[i] != address(0), 'zero address');
            require(_tokenDecimalMultipliers[i] > 0, 'wrong multiplier');
            tokens[tokenCount_] = _tokens[i];
            emit UpdatedToken(tokenCount_, _tokens[i], _tokenDecimalMultipliers[i], address(0));
            decimalsMultipliers[tokenCount_] = _tokenDecimalMultipliers[i];
            tokenCount_ += 1;
        }
        tokenCount = tokenCount_;
    }

    function replaceToken(
        uint256 _tokenIndex,
        address _token,
        uint256 _tokenDecimalMultiplier
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tokenIndex <= tokenCount && _tokenIndex > 0, 'wrong index');
        require(_token != address(0), 'zero address');
        require(_tokenDecimalMultiplier > 0, 'wrong multiplier');
        emit UpdatedToken(_tokenIndex, _token, _tokenDecimalMultiplier, tokens[_tokenIndex]);
        tokens[_tokenIndex] = _token;
        decimalsMultipliers[_tokenIndex] = _tokenDecimalMultiplier;
    }

    function poolInfo(uint256 pid) external view returns (PoolInfo memory) {
        return _poolInfo[pid];
    }

    function pendingDeposits(address user) external view returns (uint256[POOL_ASSETS] memory) {
        return _pendingDeposits[user];
    }

    function pendingWithdrawals(address user) external view returns (PendingWithdrawal memory) {
        return _pendingWithdrawals[user];
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setAvailableWithdrawalTypes(uint8 newAvailableWithdrawalTypes)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newAvailableWithdrawalTypes <= ALL_WITHDRAWAL_TYPES_MASK, 'wrong types');
        emit ChangedAvailableWithdrawalTypes(availableWithdrawalTypes, newAvailableWithdrawalTypes);
        availableWithdrawalTypes = newAvailableWithdrawalTypes;
    }

    /**
     * @dev update managementFee, this is a Zunami commission from protocol profit
     * @param  newManagementFee - minAmount 0, maxAmount MAX_FEE
     */
    function setManagementFee(uint256 newManagementFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newManagementFee <= MAX_FEE, 'wrong fee');
        emit ManagementFeeSet(managementFee, newManagementFee);
        managementFee = newManagementFee;
    }

    /**
     * @dev Returns managementFee for strategy's when contract sell rewards
     * @return Returns commission on the amount of profit in the transaction
     * @param amount - amount of profit for calculate managementFee
     */
    function calcManagementFee(uint256 amount) external view returns (uint256) {
        return (amount * managementFee) / FEE_DENOMINATOR;
    }

    /**
     * @dev Claims managementFee from all active strategies
     */
    function claimAllManagementFee() external {
        uint256 feeTotalValue;
        for (uint256 i = 0; i < _poolInfo.length; i++) {
            feeTotalValue += _poolInfo[i].strategy.claimManagementFees();
        }

        emit ClaimedAllManagementFee(feeTotalValue);
    }

    function autoCompoundAll() external {
        uint256 totalCompounded = 0;
        for (uint256 i = 0; i < _poolInfo.length; i++) {
            PoolInfo memory poolInfo_ = _poolInfo[i];
            if (poolInfo_.lpShares > 0 && poolInfo_.enabled) {
                totalCompounded += poolInfo_.strategy.autoCompound();
            }
        }
        emit AutoCompoundAll(totalCompounded);
    }

    /**
     * @dev Returns total holdings for all pools (strategy's)
     * @return Returns sum holdings (USD) for all pools
     */
    function totalHoldings() public view returns (uint256) {
        uint256 length = _poolInfo.length;
        uint256 totalHold = 0;
        for (uint256 pid = 0; pid < length; pid++) {
            PoolInfo memory poolInfo_ = _poolInfo[pid];
            if (poolInfo_.lpShares > 0 && poolInfo_.enabled) {
                totalHold += poolInfo_.strategy.totalHoldings();
            }
        }
        return totalHold;
    }

    /**
     * @dev Returns price depends on the income of users
     * @return Returns currently price of ZLP (1e18 = 1$)
     */
    function lpPrice() public view returns (uint256) {
        return calcTokenPrice(totalHoldings(), totalSupply());
    }

    function calcTokenPrice(uint256 _holdings, uint256 _tokens) public pure returns (uint256) {
        return (_holdings * 1e18) / _tokens;
    }

    /**
     * @dev Returns number of pools
     * @return number of pools
     */
    function poolCount() external view returns (uint256) {
        return _poolInfo.length;
    }

    /**
     * @dev in this func user sends funds to the contract and then waits for the completion
     * of the transaction for all users
     * @param amounts - array of deposit amounts by user
     */
    function delegateDeposit(uint256[POOL_ASSETS] memory amounts) external payable whenNotPaused startedPool nonReentrant {
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                safeTransferFromNative(IERC20Metadata(tokens[i]), _msgSender(), address(this), amounts[i]);
                _pendingDeposits[_msgSender()][i] += amounts[i];
            }
        }

        emit CreatedPendingDeposit(_msgSender(), amounts);
    }

    /**
     * @dev deposit in one tx, without waiting complete by dev
     * @return Returns amount of lpShares minted for user
     * @param amounts - user send amounts of stablecoins to deposit
     */
    function deposit(uint256[POOL_ASSETS] memory amounts)
        external
        payable
        whenNotPaused
        startedPool
        nonReentrant
        returns (uint256)
    {
        IStrategy strategy = _poolInfo[defaultDepositPid].strategy;

        uint256 holdingsBefore = totalHoldings();

        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                safeTransferFromNative(IERC20Metadata(tokens[i]), _msgSender(), address(strategy), amounts[i]);
            }
        }
        uint256 depositedValue = strategy.deposit{ value: amounts[ETH_MOCK_TOKEN_ID] }(amounts);
        require(depositedValue > 0, 'low deposit');

        return
            processSuccessfulDeposit(_msgSender(), depositedValue, amounts, holdingsBefore, false);
    }

    function processSuccessfulDeposit(
        address user,
        uint256 depositedValue,
        uint256[POOL_ASSETS] memory depositedTokens,
        uint256 holdingsBefore,
        bool optimized
    ) internal returns (uint256 lpShares) {
        if (totalSupply() == 0) {
            lpShares = depositedValue;
        } else {
            lpShares = (totalSupply() * depositedValue) / holdingsBefore;
        }

        _mint(user, lpShares);
        _poolInfo[defaultDepositPid].lpShares += lpShares;
        emit Deposited(
            user,
            depositedValue,
            depositedTokens,
            lpShares,
            defaultDepositPid,
            optimized
        );
        totalDeposited += depositedValue;
    }

    /**
     * @dev Zunami protocol owner complete all active pending deposits of users
     * @param userList - dev send array of users from pending to complete
     */
    function completeDeposits(address[] memory userList)
        external
        nonReentrant
        onlyRole(OPERATOR_ROLE)
    {
        IStrategy strategy = _poolInfo[defaultDepositPid].strategy;
        uint256 holdingsBefore = totalHoldings();

        uint256 holdingsNew;
        uint256[POOL_ASSETS] memory totalAmounts;
        uint256[] memory holdingsPerUser = new uint256[](userList.length);
        for (uint256 i = 0; i < userList.length; i++) {
            holdingsNew = 0;
            for (uint256 x = 0; x < totalAmounts.length; x++) {
                uint256 userTokenDeposit = _pendingDeposits[userList[i]][x];
                totalAmounts[x] += userTokenDeposit;
                holdingsNew += userTokenDeposit * decimalsMultipliers[x];
            }
            holdingsPerUser[i] = holdingsNew;
        }

        uint256 holdingsTotal = 0;
        for (uint256 y = 0; y < POOL_ASSETS; y++) {
            uint256 tokenAmountTotal = totalAmounts[y];
            if (tokenAmountTotal > 0) {
                holdingsTotal += tokenAmountTotal * decimalsMultipliers[y];
                if (y != 0) {
                    safeTransferNative(IERC20Metadata(tokens[y]), address(strategy), tokenAmountTotal);
                }
            }
        }
        uint256 depositedValue = strategy.deposit{ value: totalAmounts[ETH_MOCK_TOKEN_ID] }(totalAmounts);
        require(depositedValue > 0, 'low deposit');

        uint256 holdingsCounted = 0;
        uint256 userDepositedValue = 0;
        for (uint256 z = 0; z < userList.length; z++) {
            address userAddr = userList[z];
            userDepositedValue = (depositedValue * holdingsPerUser[z]) / holdingsTotal;
            processSuccessfulDeposit(
                userAddr,
                userDepositedValue,
                _pendingDeposits[userAddr],
                holdingsBefore + holdingsCounted,
                true
            );
            holdingsCounted += userDepositedValue;
            delete _pendingDeposits[userAddr];
        }
    }

    /**
     * @dev in this func user sends pending withdraw to the contract and then waits
     * for the completion of the transaction for all users
     * @param  lpShares - amount of ZLP for withdraw
     * @param tokenAmounts - array of amounts stablecoins that user want minimum receive
     */
    function delegateWithdrawal(
        uint256 lpShares,
        uint256[POOL_ASSETS] memory tokenAmounts
    ) external whenNotPaused startedPool nonReentrant {
        require(lpShares > 0, 'zero lp');

        PendingWithdrawal memory withdrawal;
        address userAddr = _msgSender();

        withdrawal.lpShares = lpShares;
        withdrawal.tokenAmounts = tokenAmounts;

        _pendingWithdrawals[userAddr] = withdrawal;

        emit CreatedPendingWithdrawal(userAddr, lpShares, tokenAmounts);
    }

    /**
     * @dev withdraw in one tx, without waiting complete by dev
     * @param lpShares - amount of ZLP for withdraw
     * @param tokenAmounts -  array of amounts stablecoins that user want minimum receive
     */
    function withdraw(
        uint256 lpShares,
        uint256[POOL_ASSETS] memory tokenAmounts,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex
    ) external whenNotPaused startedPool nonReentrant {
        require(availableWithdrawalTypes & (0x01 << uint8(withdrawalType)) != 0, 'wrong type');

        IStrategy strategy = _poolInfo[defaultWithdrawPid].strategy;
        address userAddr = _msgSender();

        require(balanceOf(userAddr) >= lpShares, 'wrong lp');
        require(
            strategy.withdraw(
                userAddr,
                calcLpRatioSafe(lpShares, _poolInfo[defaultWithdrawPid].lpShares),
                tokenAmounts,
                withdrawalType,
                tokenIndex
            ),
            'wrong params'
        );

        uint256 userDeposit = (totalDeposited * lpShares) / totalSupply();

        processSuccessfulWithdrawal(
            userAddr,
            userDeposit,
            lpShares,
            withdrawalType,
            tokenIndex,
            false
        );
    }

    function processSuccessfulWithdrawal(
        address user,
        uint256 userDeposit,
        uint256 lpShares,
        IStrategy.WithdrawalType withdrawalType,
        uint128 tokenIndex,
        bool optimized
    ) internal {
        _burn(user, lpShares);
        _poolInfo[defaultWithdrawPid].lpShares -= lpShares;
        totalDeposited -= userDeposit;
        emit Withdrawn(user, lpShares, withdrawalType, tokenIndex, defaultWithdrawPid, optimized);
    }

    function processSuccessfulOptimizedWithdrawal(
        address[] memory userList,
        uint256[POOL_ASSETS] memory lpSharesTotals,
        uint256[POOL_ASSETS] memory prevBalances
    ) internal {
        uint256[POOL_ASSETS] memory diffBalances;
        for (uint256 i = 0; i < POOL_ASSETS; i++) {
            address token = tokens[i];
            if (token == address(0)) break;
            diffBalances[i] = balanceOfNative(IERC20Metadata(token)) - prevBalances[i];
        }

        for (uint256 i = 0; i < userList.length; i++) {
            address user = userList[i];
            PendingWithdrawal memory withdrawal = _pendingWithdrawals[user];

            uint256 userDeposit = (totalDeposited * withdrawal.lpShares) / totalSupply();

            processSuccessfulWithdrawal(
                user,
                userDeposit,
                withdrawal.lpShares,
                IStrategy.WithdrawalType.Base,
                0,
                true
            );

            uint256 transferAmount;
            for (uint256 j = 0; j < POOL_ASSETS; j++) {
                if (lpSharesTotals[j] == 0) continue;
                transferAmount = (diffBalances[j] * withdrawal.lpShares) / lpSharesTotals[j];

                if (transferAmount == 0) continue;
                safeTransferNative(IERC20Metadata(tokens[j]), user, transferAmount);
            }

            delete _pendingWithdrawals[user];
        }
    }

    function calcLpRatioSafe(uint256 outLpShares, uint256 strategyLpShares)
        internal
        pure
        returns (uint256 lpShareRatio)
    {
        lpShareRatio = (outLpShares * LP_RATIO_MULTIPLIER) / strategyLpShares;
        require(lpShareRatio > 0 && lpShareRatio <= LP_RATIO_MULTIPLIER, 'wrong ratio');
    }

    /**
     * @dev Zunami protocol owner complete all active pending withdrawals of users
     * @param userList - users owns pending withdraw to complete
     */
    function completeWithdrawals(
        address[] memory userList,
        uint256[POOL_ASSETS] memory minAmountsTotal
    ) external nonReentrant onlyRole(OPERATOR_ROLE) {
        require(userList.length > 0, 'zero requests');

        IStrategy strategy = _poolInfo[defaultWithdrawPid].strategy;

        uint256 lpSharesTotal;

        uint256 i;
        address user;
        PendingWithdrawal memory withdrawal;
        for (i = 0; i < userList.length; i++) {
            user = userList[i];

            withdrawal = _pendingWithdrawals[user];
            if (balanceOf(user) < withdrawal.lpShares) {
                emit FailedWithdrawal(
                    user,
                    withdrawal.tokenAmounts,
                    withdrawal.lpShares,
                    IStrategy.WithdrawalType.Base,
                    0
                );
                delete _pendingWithdrawals[user];
                continue;
            }

            lpSharesTotal += withdrawal.lpShares;
        }

        require(lpSharesTotal <= _poolInfo[defaultWithdrawPid].lpShares, 'not enough lp');

        uint256[POOL_ASSETS] memory prevBalances = calcPrevTokenBalances();

        if (
            !strategy.withdraw(
                address(this),
                calcLpRatioSafe(lpSharesTotal, _poolInfo[defaultWithdrawPid].lpShares),
                minAmountsTotal,
                IStrategy.WithdrawalType.Base,
                0
            )
        ) {
            removeAllFailedWithdrawals(userList);
            return;
        }

        processSuccessfulOptimizedWithdrawal(userList, fillArrayN(lpSharesTotal), prevBalances);
    }

    function calcPrevTokenBalances()
        internal
        view
        returns (uint256[POOL_ASSETS] memory prevBalances)
    {
        for (uint256 i = 0; i < POOL_ASSETS; i++) {
            address token = tokens[i];
            if (token == address(0)) break;
            prevBalances[i] = balanceOfNative(IERC20Metadata(token));
        }
    }

    function removeAllFailedWithdrawals(address[] memory userList) internal {
        for (uint256 i = 0; i < userList.length; i++) {
            address user = userList[i];
            PendingWithdrawal memory withdrawal = _pendingWithdrawals[user];

            emit FailedWithdrawal(
                user,
                withdrawal.tokenAmounts,
                withdrawal.lpShares,
                IStrategy.WithdrawalType.Base,
                0
            );
            delete _pendingWithdrawals[user];
        }
    }

    function calcWithdrawOneCoin(uint256 lpShares, uint128 tokenIndex)
        external
        view
        returns (uint256 tokenAmount)
    {
        uint256 lpShareRatio = calcLpRatioSafe(lpShares, _poolInfo[defaultWithdrawPid].lpShares);
        return _poolInfo[defaultWithdrawPid].strategy.calcWithdrawOneCoin(lpShareRatio, tokenIndex);
    }

    function calcSharesAmount(uint256[POOL_ASSETS] memory tokenAmounts, bool isDeposit)
        external
        view
        returns (uint256 lpShares)
    {
        return _poolInfo[defaultWithdrawPid].strategy.calcSharesAmount(tokenAmounts, isDeposit);
    }

    /**
     * @dev add a new pool, deposits in the new pool are blocked for one day for safety
     * @param _strategyAddr - the new pool strategy address
     */
    function addPool(address _strategyAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_strategyAddr != address(0), 'zero addr');
        uint256 poolInfoLength_ = _poolInfo.length;
        for (uint256 i = 0; i < poolInfoLength_; i++) {
            require(_strategyAddr != address(_poolInfo[i].strategy), 'duplicate');
        }

        uint256 startTime = block.timestamp + (launched ? MIN_LOCK_TIME : 0);
        _poolInfo.push(
            PoolInfo({
                strategy: IStrategy(_strategyAddr),
                startTime: startTime,
                lpShares: 0,
                enabled: true
            })
        );
        emit AddedPool(poolInfoLength_, _strategyAddr, startTime);
    }

    /**
     * @dev set a default pool for deposit funds
     * @param _newPoolId - new pool id
     */
    function setDefaultDepositPid(uint256 _newPoolId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        enabledPool(_newPoolId)
    {
        require(_newPoolId < _poolInfo.length, 'wrong pid');

        defaultDepositPid = _newPoolId;
        emit SetDefaultDepositPid(_newPoolId);
    }

    /**
     * @dev set a default pool for withdraw funds
     * @param _newPoolId - new pool id
     */
    function setDefaultWithdrawPid(uint256 _newPoolId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        enabledPool(_newPoolId)
    {
        require(_newPoolId < _poolInfo.length, 'incorrect pid');

        defaultWithdrawPid = _newPoolId;
        emit SetDefaultWithdrawPid(_newPoolId);
    }

    function launch() external onlyRole(DEFAULT_ADMIN_ROLE) {
        launched = true;
    }

    modifier onlyRebalancer() {
        require(_msgSender() == address(rebalancer), 'rebalancer');
        _;
    }

    function setRebalancer(address rebalancerAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rebalancerAddr != address(0), 'zero address');

        rebalancer = IZunamiRebalancer(rebalancerAddr);
        emit SetRebalancer(rebalancerAddr);
    }

    function rebalance() external onlyRole(DEFAULT_ADMIN_ROLE) {
        rebalancer.rebalance();
    }

    function increasePoolShares(uint256 pid, uint256 amount) external onlyRebalancer {
        _poolInfo[pid].lpShares += amount;
    }

    function decreasePoolShares(uint256 pid, uint256 amount) external onlyRebalancer {
        _poolInfo[pid].lpShares -= amount;
    }

    /**
     * @dev dev can transfer funds from few strategy's to one strategy for better APY
     * @param _strategies - array of strategy's, from which funds are withdrawn
     * @param withdrawalsPercents - A percentage of the funds that should be transferred
     * @param _receiverStrategy - number strategy, to which funds are deposited
     */
    function moveFundsBatch(
        uint256[] memory _strategies,
        uint256[] memory withdrawalsPercents,
        uint256 _receiverStrategy
    ) external onlyRole(DEFAULT_ADMIN_ROLE) enabledPool(_receiverStrategy) {
        require(_strategies.length == withdrawalsPercents.length, 'wrong arguments');
        require(_receiverStrategy < _poolInfo.length, 'wrong receiver');

        uint256[POOL_ASSETS] memory tokenBalance;
        for (uint256 y = 0; y < POOL_ASSETS; y++) {
            address token = tokens[y];
            if (token == address(0)) break;
            tokenBalance[y] = balanceOfNative(IERC20Metadata(token));
        }

        uint256 pid;
        uint256 zunamiLp;
        for (uint256 i = 0; i < _strategies.length; i++) {
            pid = _strategies[i];
            zunamiLp += _moveFunds(pid, withdrawalsPercents[i]);
        }

        uint256[POOL_ASSETS] memory tokensRemainder;
        for (uint256 y = 0; y < POOL_ASSETS; y++) {
            address token = tokens[y];
            if (token == address(0)) break;
            tokensRemainder[y] = balanceOfNative(IERC20Metadata(token)) - tokenBalance[y];
            if (tokensRemainder[y] > 0) {
                safeTransferNative(
                    IERC20Metadata(token),
                    address(_poolInfo[_receiverStrategy].strategy),
                    tokensRemainder[y]
                );
            }
        }

        _poolInfo[_receiverStrategy].lpShares += zunamiLp;

        require(_poolInfo[_receiverStrategy].strategy.deposit(tokensRemainder) > 0, 'low amount');
    }

    function _moveFunds(uint256 pid, uint256 withdrawPercent) private returns (uint256) {
        uint256 currentLpAmount;

        if (withdrawPercent == FUNDS_DENOMINATOR) {
            _poolInfo[pid].strategy.withdrawAll();

            currentLpAmount = _poolInfo[pid].lpShares;
            _poolInfo[pid].lpShares = 0;
        } else {
            currentLpAmount = (_poolInfo[pid].lpShares * withdrawPercent) / FUNDS_DENOMINATOR;
            uint256[POOL_ASSETS] memory minAmounts;

            _poolInfo[pid].strategy.withdraw(
                address(this),
                calcLpRatioSafe(currentLpAmount, _poolInfo[pid].lpShares),
                minAmounts,
                IStrategy.WithdrawalType.Base,
                0
            );
            _poolInfo[pid].lpShares = _poolInfo[pid].lpShares - currentLpAmount;
        }

        return currentLpAmount;
    }

    /**
     * @dev user remove his active pending deposit
     */
    function removePendingDeposit() external nonReentrant {
        uint256[POOL_ASSETS] memory pendingDeposit =  _pendingDeposits[_msgSender()];
        delete _pendingDeposits[_msgSender()];
        emit RemovedPendingDeposit(_msgSender());

        uint256 tokenAmount_;
        for (uint256 i = 0; i < POOL_ASSETS; i++) {
            tokenAmount_ = pendingDeposit[i];
            if (tokenAmount_ > 0) {
                safeTransferNative(IERC20Metadata(tokens[i]), _msgSender(), tokenAmount_);
            }
        }
    }

    /**
     * @dev governance can withdraw all stuck funds in emergency case
     * @param _token - IERC20Metadata token that should be fully withdraw from Zunami
     */
    function withdrawStuckToken(IERC20Metadata _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenBalance = balanceOfNative(_token);
        if (tokenBalance > 0) {
            safeTransferNative(_token, _msgSender(), tokenBalance);
        }
    }

    function disablePool(uint256 _pid) external onlyRole(PAUSER_ROLE) {
        require(_poolInfo[_pid].enabled, "not enabled");
        _poolInfo[_pid].enabled = false;

        emit ChangedPoolEnabledStatus(address(_poolInfo[_pid].strategy), _poolInfo[_pid].enabled);
    }

    function enablePool(uint256 _pid) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_poolInfo[_pid].enabled, "not disabled");
        _poolInfo[_pid].enabled = true;

        emit ChangedPoolEnabledStatus(address(_poolInfo[_pid].strategy), _poolInfo[_pid].enabled);
    }

    function fillArrayN(uint256 _value) internal pure returns (uint256[POOL_ASSETS] memory values) {
        for (uint256 i; i < POOL_ASSETS; i++) {
            values[i] = _value;
        }
    }

    function balanceOfNative(IERC20Metadata token_) internal view returns (uint256) {
        if (address(token_) == ETH_MOCK_ADDRESS) {
            return address(this).balance;
        } else {
            return token_.balanceOf(address(this));
        }
    }

    function safeTransferNative(
        IERC20Metadata token,
        address receiver,
        uint256 amount
    ) internal {
        if (address(token) == ETH_MOCK_ADDRESS) {
            receiver.call{ value: amount }(''); // don't fail if user contract doesn't accept ETH
        } else {
            token.safeTransfer(receiver, amount);
        }
    }

    function safeTransferFromNative(
        IERC20Metadata token,
        address sender,
        address receiver,
        uint256 amount
    ) internal {
        if (address(token) == ETH_MOCK_ADDRESS) {
            require(msg.value == amount, 'ETH wrong');
        } else {
            token.safeTransferFrom(sender, receiver, amount);
        }
    }
}