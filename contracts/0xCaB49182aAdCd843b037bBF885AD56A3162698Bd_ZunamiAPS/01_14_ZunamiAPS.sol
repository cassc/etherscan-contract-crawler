//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './interfaces/IStrategyAPS.sol';

/**
 *
 * @title Zunami Protocol
 *
 * @notice Contract for Convex&Curve protocols optimize.
 * Users can use this contract for optimize yield and gas.
 *
 *
 * @dev Zunami is main contract.
 * Contract does not store user funds.
 * All user funds goes to Convex&Curve pools.
 *
 */

contract ZunamiAPS is ERC20, Pausable, AccessControl {
    using SafeERC20 for IERC20Metadata;

    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    uint8 public constant POOL_ASSETS = 1;

    struct PendingWithdrawal {
        uint256 lpShares;
        uint256 tokenAmount;
    }

    struct PoolInfo {
        IStrategyAPS strategy;
        uint256 startTime;
        uint256 lpShares;
    }

    uint256 public constant LP_RATIO_MULTIPLIER = 1e18;
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public constant MAX_FEE = 300; // 30%
    uint256 public constant MIN_LOCK_TIME = 1 days;
    uint256 public constant FUNDS_DENOMINATOR = 10_000;

    PoolInfo[] internal _poolInfo;
    uint256 public defaultDepositPid;
    uint256 public defaultWithdrawPid;

    address public token;

    mapping(address => uint256) internal _pendingDeposits;
    mapping(address => PendingWithdrawal) internal _pendingWithdrawals;

    uint256 public totalDeposited = 0;
    uint256 public managementFee = 100; // 10%
    bool public launched = false;

    event ManagementFeeSet(uint256 oldManagementFee, uint256 newManagementFee);

    event CreatedPendingDeposit(address indexed depositor, uint256 amount);
    event CreatedPendingWithdrawal(
        address indexed withdrawer,
        uint256 lpShares,
        uint256 tokenAmount
    );
    event Deposited(address indexed depositor, uint256 amount, uint256 lpShares, uint256 pid);
    event Withdrawn(
        address indexed withdrawer,
        uint256 tokenAmount,
        uint256 lpShares
    );

    event AddedPool(uint256 pid, address strategyAddr, uint256 startTime);
    event FailedDeposit(address indexed depositor, uint256 amounts, uint256 lpShares);
    event FailedWithdrawal(
        address indexed withdrawer,
        uint256 amounts,
        uint256 lpShares
    );
    event SetDefaultDepositPid(uint256 pid);
    event SetDefaultWithdrawPid(uint256 pid);
    event ClaimedAllManagementFee(uint256 feeValue);
    event AutoCompoundAll();

    modifier startedPool() {
        require(_poolInfo.length != 0, 'Zunami: pool not existed!');
        require(
            block.timestamp >= _poolInfo[defaultDepositPid].startTime,
            'Zunami: default deposit pool not started yet!'
        );
        require(
            block.timestamp >= _poolInfo[defaultWithdrawPid].startTime,
            'Zunami: default withdraw pool not started yet!'
        );
        _;
    }

    constructor(address _token) ERC20('ZunamiAPSLP', 'ZAPSLP') {
        token = _token;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    function poolInfo(uint256 pid) external view returns (PoolInfo memory) {
        return _poolInfo[pid];
    }

    function pendingDeposits(address user) external view returns (uint256) {
        return _pendingDeposits[user];
    }

    function pendingWithdrawals(address user) external view returns (PendingWithdrawal memory) {
        return _pendingWithdrawals[user];
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev update managementFee, this is a Zunami commission from protocol profit
     * @param  newManagementFee - minAmount 0, maxAmount FEE_DENOMINATOR - 1
     */
    function setManagementFee(uint256 newManagementFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newManagementFee <= MAX_FEE, 'Zunami: wrong fee');
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
        for (uint256 i = 0; i < _poolInfo.length; i++) {
            PoolInfo memory poolInfo_ = _poolInfo[i];
            if (poolInfo_.lpShares > 0) {
                poolInfo_.strategy.autoCompound();
            }
        }
        emit AutoCompoundAll();
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
            if (poolInfo_.lpShares > 0) {
                totalHold += poolInfo_.strategy.totalHoldings();
            }
        }
        return totalHold;
    }

    /**
     * @dev Returns price depends on the income of users
     * @return Returns currently price of ZLP (1e18 = 1$)
     */
    function lpPrice() external view returns (uint256) {
        return (totalHoldings() * 1e18) / totalSupply();
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
     * @param amount - deposit amount by user
     */
    function delegateDeposit(uint256 amount) external whenNotPaused {
        if (amount > 0) {
            IERC20Metadata(token).safeTransferFrom(_msgSender(), address(this), amount);
            _pendingDeposits[_msgSender()] += amount;
        }

        emit CreatedPendingDeposit(_msgSender(), amount);
    }

    /**
     * @dev in this func user sends pending withdraw to the contract and then waits
     * for the completion of the transaction for all users
     * @param  lpShares - amount of ZLP for withdraw
     * @param tokenAmount - stablecoin amount that user want minimum receive
     */
    function delegateWithdrawal(uint256 lpShares, uint256 tokenAmount)
        external
        whenNotPaused
    {
        require(lpShares > 0, 'Zunami: lpAmount must be higher 0');

        PendingWithdrawal memory withdrawal;
        address userAddr = _msgSender();

        withdrawal.lpShares = lpShares;
        withdrawal.tokenAmount = tokenAmount;

        _pendingWithdrawals[userAddr] = withdrawal;

        emit CreatedPendingWithdrawal(userAddr, lpShares, tokenAmount);
    }

    /**
     * @dev Zunami protocol owner complete all active pending deposits of users
     * @param userList - dev send array of users from pending to complete
     */
    function completeDeposits(address[] memory userList)
        external
        onlyRole(OPERATOR_ROLE)
        startedPool
    {
        IStrategyAPS strategy = _poolInfo[defaultDepositPid].strategy;
        uint256 currentTotalHoldings = totalHoldings();

        uint256 newHoldings = 0;
        uint256 totalAmount;
        uint256[] memory userCompleteHoldings = new uint256[](userList.length);
        for (uint256 i = 0; i < userList.length; i++) {
            newHoldings = 0;

            uint256 userTokenDeposit = _pendingDeposits[userList[i]];
            totalAmount += userTokenDeposit;
            newHoldings += userTokenDeposit;
            userCompleteHoldings[i] = newHoldings;
        }

        newHoldings = 0;
        if (totalAmount > 0) {
            newHoldings += totalAmount;
            IERC20Metadata(token).safeTransfer(address(strategy), totalAmount);
        }
        uint256 totalDepositedNow = strategy.deposit(totalAmount);
        require(totalDepositedNow > 0, 'Zunami: too low deposit!');
        uint256 lpShares = 0;
        uint256 addedHoldings = 0;
        uint256 userDeposited = 0;

        for (uint256 z = 0; z < userList.length; z++) {
            userDeposited = (totalDepositedNow * userCompleteHoldings[z]) / newHoldings;
            address userAddr = userList[z];
            if (totalSupply() == 0) {
                lpShares = userDeposited;
            } else {
                lpShares = (totalSupply() * userDeposited) / (currentTotalHoldings + addedHoldings);
            }
            addedHoldings += userDeposited;
            _mint(userAddr, lpShares);
            _poolInfo[defaultDepositPid].lpShares += lpShares;
            emit Deposited(userAddr, _pendingDeposits[userAddr], lpShares, defaultDepositPid);

            // remove deposit from list
            delete _pendingDeposits[userAddr];
        }
        totalDeposited += addedHoldings;
    }

    /**
     * @dev Zunami protocol owner complete all active pending withdrawals of users
     * @param userList - array of users from pending withdraw to complete
     */
    function completeWithdrawals(address[] memory userList)
        external
        onlyRole(OPERATOR_ROLE)
        startedPool
    {
        require(userList.length > 0, 'Zunami: there are no pending withdrawals requests');

        IStrategyAPS withdrawStrategy = _poolInfo[defaultWithdrawPid].strategy;

        address user;
        PendingWithdrawal memory withdrawal;
        for (uint256 i = 0; i < userList.length; i++) {
            user = userList[i];
            withdrawal = _pendingWithdrawals[user];
            if (balanceOf(user) < withdrawal.lpShares) {
                emit FailedWithdrawal(user, withdrawal.tokenAmount, withdrawal.lpShares);
                delete _pendingWithdrawals[user];
                continue;
            }

            if (
                !(
                    withdrawStrategy.withdraw(
                        user,
                        calcLpRatioSafe(
                            withdrawal.lpShares,
                            _poolInfo[defaultWithdrawPid].lpShares
                        ),
                        withdrawal.tokenAmount
                    )
                )
            ) {
                emit FailedWithdrawal(user, withdrawal.tokenAmount, withdrawal.lpShares);
                delete _pendingWithdrawals[user];
                continue;
            }

            uint256 userDeposit = (totalDeposited * withdrawal.lpShares) / totalSupply();
            _burn(user, withdrawal.lpShares);
            _poolInfo[defaultWithdrawPid].lpShares -= withdrawal.lpShares;
            totalDeposited -= userDeposit;

            emit Withdrawn(
                user,
                withdrawal.tokenAmount,
                withdrawal.lpShares
            );
            delete _pendingWithdrawals[user];
        }
    }

    function calcLpRatioSafe(uint256 outLpShares, uint256 strategyLpShares)
        internal
        pure
        returns (uint256 lpShareRatio)
    {
        lpShareRatio = (outLpShares * LP_RATIO_MULTIPLIER) / strategyLpShares;
        require(
            lpShareRatio > 0 && lpShareRatio <= LP_RATIO_MULTIPLIER,
            'Zunami: Wrong out lp ratio'
        );
    }

    function completeWithdrawalsOptimized(address[] memory userList)
        external
        onlyRole(OPERATOR_ROLE)
        startedPool
    {
        require(userList.length > 0, 'Zunami: there are no pending withdrawals requests');

        IStrategyAPS strategy = _poolInfo[defaultWithdrawPid].strategy;

        uint256 lpSharesTotal;
        uint256 minAmountTotal;

        uint256 i;
        address user;
        PendingWithdrawal memory withdrawal;
        for (i = 0; i < userList.length; i++) {
            user = userList[i];
            withdrawal = _pendingWithdrawals[user];

            if (balanceOf(user) < withdrawal.lpShares) {
                emit FailedWithdrawal(user, withdrawal.tokenAmount, withdrawal.lpShares);
                delete _pendingWithdrawals[user];
                continue;
            }

            lpSharesTotal += withdrawal.lpShares;
            minAmountTotal += withdrawal.tokenAmount;
        }

        require(
            lpSharesTotal <= _poolInfo[defaultWithdrawPid].lpShares,
            'Zunami: Insufficient pool LP shares'
        );

        uint256 prevBalance = IERC20Metadata(token).balanceOf(address(this));

        if (
            !strategy.withdraw(
                address(this),
                calcLpRatioSafe(lpSharesTotal, _poolInfo[defaultWithdrawPid].lpShares),
                minAmountTotal
            )
        ) {
            for (i = 0; i < userList.length; i++) {
                user = userList[i];
                withdrawal = _pendingWithdrawals[user];

                emit FailedWithdrawal(user, withdrawal.tokenAmount, withdrawal.lpShares);
                delete _pendingWithdrawals[user];
            }
            return;
        }

        uint256 diffBalance = IERC20Metadata(token).balanceOf(address(this)) - prevBalance;

        for (i = 0; i < userList.length; i++) {
            user = userList[i];
            withdrawal = _pendingWithdrawals[user];

            uint256 userDeposit = (totalDeposited * withdrawal.lpShares) / totalSupply();
            _burn(user, withdrawal.lpShares);
            _poolInfo[defaultWithdrawPid].lpShares -= withdrawal.lpShares;
            totalDeposited -= userDeposit;

            uint256 transferAmount = (diffBalance * withdrawal.lpShares) / lpSharesTotal;
            if (transferAmount > 0) {
                IERC20Metadata(token).safeTransfer(user, transferAmount);
            }

            emit Withdrawn(
                user,
                withdrawal.tokenAmount,
                withdrawal.lpShares
            );

            delete _pendingWithdrawals[user];
        }
    }

    /**
     * @dev deposit in one tx, without waiting complete by dev
     * @return Returns amount of lpShares minted for user
     * @param amount - user send amount of stablecoin to deposit
     */
    function deposit(uint256 amount)
        external
        whenNotPaused
        startedPool
        returns (uint256)
    {
        IStrategyAPS strategy = _poolInfo[defaultDepositPid].strategy;
        uint256 holdings = totalHoldings();
        if (amount > 0) {
            IERC20Metadata(token).safeTransferFrom(
                _msgSender(),
                address(strategy),
                amount
            );
        }
        uint256 newDeposited = strategy.deposit(amount);
        require(newDeposited > 0, 'Zunami: too low deposit!');

        uint256 lpShares = 0;
        if (totalSupply() == 0) {
            lpShares = newDeposited;
        } else {
            lpShares = (totalSupply() * newDeposited) / holdings;
        }

        _mint(_msgSender(), lpShares);
        _poolInfo[defaultDepositPid].lpShares += lpShares;
        totalDeposited += newDeposited;

        emit Deposited(_msgSender(), amount, lpShares, defaultDepositPid);
        return lpShares;
    }

    /**
     * @dev withdraw in one tx, without waiting complete by dev
     * @param lpShares - amount of ZLP for withdraw
     * @param tokenAmount - stablecoin amount that user want minimum receive
     */
    function withdraw(
        uint256 lpShares,
        uint256 tokenAmount
    ) external whenNotPaused startedPool {
        IStrategyAPS strategy = _poolInfo[defaultWithdrawPid].strategy;
        address userAddr = _msgSender();

        require(balanceOf(userAddr) >= lpShares, 'Zunami: not enough LP balance');
        require(
            strategy.withdraw(
                userAddr,
                calcLpRatioSafe(lpShares, _poolInfo[defaultWithdrawPid].lpShares),
                tokenAmount
            ),
            'Zunami: incorrect withdraw params'
        );

        uint256 userDeposit = (totalDeposited * lpShares) / totalSupply();
        _burn(userAddr, lpShares);
        _poolInfo[defaultWithdrawPid].lpShares -= lpShares;

        totalDeposited -= userDeposit;

        emit Withdrawn(userAddr, tokenAmount, lpShares);
    }

    function calcWithdrawOneCoin(uint256 lpShares)
        external
        view
        returns (uint256 tokenAmount)
    {
        require(lpShares <= balanceOf(_msgSender()), 'Zunami: not enough LP balance');

        uint256 lpShareRatio = calcLpRatioSafe(lpShares, _poolInfo[defaultWithdrawPid].lpShares);
        return _poolInfo[defaultWithdrawPid].strategy.calcWithdrawOneCoin(lpShareRatio);
    }

    function calcSharesAmount(uint256 tokenAmount, bool isDeposit)
        external
        view
        returns (uint256 lpShares)
    {
        return _poolInfo[defaultWithdrawPid].strategy.calcSharesAmount(tokenAmount, isDeposit);
    }

    /**
     * @dev add a new pool, deposits in the new pool are blocked for one day for safety
     * @param _strategyAddr - the new pool strategy address
     */

    function addPool(address _strategyAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_strategyAddr != address(0), 'Zunami: zero strategy addr');
        for(uint256 i = 0; i < _poolInfo.length; i++) {
            require(_strategyAddr != address(_poolInfo[i].strategy), 'Zunami: dublicate strategy addr');
        }

        uint256 startTime = block.timestamp + (launched ? MIN_LOCK_TIME : 0);
        _poolInfo.push(
            PoolInfo({ strategy: IStrategyAPS(_strategyAddr), startTime: startTime, lpShares: 0 })
        );
        emit AddedPool(_poolInfo.length - 1, _strategyAddr, startTime);
    }

    /**
     * @dev set a default pool for deposit funds
     * @param _newPoolId - new pool id
     */
    function setDefaultDepositPid(uint256 _newPoolId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newPoolId < _poolInfo.length, 'Zunami: incorrect default deposit pool id');

        defaultDepositPid = _newPoolId;
        emit SetDefaultDepositPid(_newPoolId);
    }

    /**
     * @dev set a default pool for withdraw funds
     * @param _newPoolId - new pool id
     */
    function setDefaultWithdrawPid(uint256 _newPoolId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newPoolId < _poolInfo.length, 'Zunami: incorrect default withdraw pool id');

        defaultWithdrawPid = _newPoolId;
        emit SetDefaultWithdrawPid(_newPoolId);
    }

    function launch() external onlyRole(DEFAULT_ADMIN_ROLE) {
        launched = true;
    }

    /**
     * @dev dev can transfer funds from few strategy's to one strategy for better APY
     * @param _strategies - array of strategy's, from which funds are withdrawn
     * @param withdrawalsPercents - A percentage of the funds that should be transferred
     * @param _receiverStrategyId - number strategy, to which funds are deposited
     */
    function moveFundsBatch(
        uint256[] memory _strategies,
        uint256[] memory withdrawalsPercents,
        uint256 _receiverStrategyId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _strategies.length == withdrawalsPercents.length,
            'Zunami: incorrect arguments for the moveFundsBatch'
        );
        require(_receiverStrategyId < _poolInfo.length, 'Zunami: incorrect a receiver strategy ID');

        uint256 tokenBalance = IERC20Metadata(token).balanceOf(address(this));

        uint256 pid;
        uint256 zunamiLp;
        for (uint256 i = 0; i < _strategies.length; i++) {
            pid = _strategies[i];
            zunamiLp += _moveFunds(pid, withdrawalsPercents[i]);
        }

        uint256 tokensRemainder = IERC20Metadata(token).balanceOf(address(this)) - tokenBalance;
        if (tokensRemainder > 0) {
            IERC20Metadata(token).safeTransfer(
                address(_poolInfo[_receiverStrategyId].strategy),
                tokensRemainder
            );
        }

        _poolInfo[_receiverStrategyId].lpShares += zunamiLp;

        require(
            _poolInfo[_receiverStrategyId].strategy.deposit(tokensRemainder) > 0,
            'Zunami: Too low amount!'
        );
    }

    function _moveFunds(uint256 pid, uint256 withdrawAmount) private returns (uint256) {
        uint256 currentLpAmount;

        if (withdrawAmount == FUNDS_DENOMINATOR) {
            _poolInfo[pid].strategy.withdrawAll();

            currentLpAmount = _poolInfo[pid].lpShares;
            _poolInfo[pid].lpShares = 0;
        } else {
            currentLpAmount = (_poolInfo[pid].lpShares * withdrawAmount) / FUNDS_DENOMINATOR;

            _poolInfo[pid].strategy.withdraw(
                address(this),
                calcLpRatioSafe(currentLpAmount, _poolInfo[pid].lpShares),
                0
            );
            _poolInfo[pid].lpShares = _poolInfo[pid].lpShares - currentLpAmount;
        }

        return currentLpAmount;
    }

    /**
     * @dev user remove his active pending deposit
     */
    function removePendingDeposit() external {
        uint256 pendingDeposit_ = _pendingDeposits[_msgSender()];
        if (pendingDeposit_ > 0) {
            IERC20Metadata(token).safeTransfer(
                _msgSender(),
                pendingDeposit_
            );
        }
        delete _pendingDeposits[_msgSender()];
    }

    function removePendingWithdrawal() external {
        delete _pendingWithdrawals[_msgSender()];
    }

    /**
     * @dev governance can withdraw all stuck funds in emergency case
     * @param _token - IERC20Metadata token that should be fully withdraw from Zunami
     */
    function withdrawStuckToken(IERC20Metadata _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenBalance = _token.balanceOf(address(this));
        if (tokenBalance > 0) {
            _token.safeTransfer(_msgSender(), tokenBalance);
        }
    }

    /**
     * @dev governance can add new operator for complete pending deposits and withdrawals
     * @param _newOperator - address that governance add in list of operators
     */
    function updateOperator(address _newOperator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(OPERATOR_ROLE, _newOperator);
    }
}