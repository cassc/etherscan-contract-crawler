// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "solowei/contracts/AttoDecimal.sol";
import "solowei/contracts/TwoStageOwnable.sol";

contract FixedSwap is ReentrancyGuard, TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AttoDecimal for AttoDecimal.Instance;

    enum Type {SIMPLE, INTERVAL, LINEAR}

    struct Props {
        uint256 issuanceLimit;
        uint256 startsAt;
        uint256 endsAt;
        IERC20 paymentToken;
        IERC20 issuanceToken;
        AttoDecimal.Instance fee;
        AttoDecimal.Instance rate;
    }

    struct AccountState {
        uint256 limitIndex;
        uint256 paymentSum;
    }

    struct ComplexAccountState {
        uint256 issuanceAmount;
        uint256 withdrawnIssuanceAmount;
    }

    struct Account {
        AccountState state;
        ComplexAccountState complex;
        uint256 immediatelyUnlockedAmount; // linear
        uint256 unlockedIntervalsCount; // interval
    }

    struct State {
        uint256 available;
        uint256 issuance;
        uint256 lockedPayments;
        uint256 unlockedPayments;
        address nominatedOwner;
        address owner;
        uint256[] paymentLimits;
    }

    struct Interval {
        uint256 startsAt;
        AttoDecimal.Instance unlockingPart;
    }

    struct LinearProps {
        uint256 endsAt;
        uint256 duration;
    }

    struct Pool {
        Type type_;
        uint256 index;
        AttoDecimal.Instance immediatelyUnlockingPart;
        Props props;
        LinearProps linear;
        State state;
        Interval[] intervals;
        mapping(address => Account) accounts;
    }

    Pool[] private _pools;
    mapping(IERC20 => uint256) private _collectedFees;

    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function poolsCount() public view returns (uint256) {
        return _pools.length;
    }

    function poolProps(uint256 poolIndex) public view returns (Type type_, Props memory props) {
        Pool storage pool = _getPool(poolIndex);
        return (pool.type_, pool.props);
    }

    function intervalPoolProps(uint256 poolIndex)
        public
        view
        returns (
            Props memory props,
            AttoDecimal.Instance memory immediatelyUnlockingPart,
            Interval[] memory intervals
        )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsInterval(pool);
        return (pool.props, pool.immediatelyUnlockingPart, pool.intervals);
    }

    function linearPoolProps(uint256 poolIndex)
        public
        view
        returns (
            Props memory props,
            AttoDecimal.Instance memory immediatelyUnlockingPart,
            LinearProps memory linear
        )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsLinear(pool);
        return (pool.props, pool.immediatelyUnlockingPart, pool.linear);
    }

    function poolState(uint256 poolIndex) public view returns (State memory state) {
        return _getPool(poolIndex).state;
    }

    function poolAccount(uint256 poolIndex, address address_)
        public
        view
        returns (Type type_, AccountState memory state)
    {
        Pool storage pool = _getPool(poolIndex);
        return (pool.type_, pool.accounts[address_].state);
    }

    function intervalPoolAccount(uint256 poolIndex, address address_)
        public
        view
        returns (
            AccountState memory state,
            ComplexAccountState memory complex,
            uint256 unlockedIntervalsCount
        )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsInterval(pool);
        Account storage account = pool.accounts[address_];
        return (account.state, account.complex, account.unlockedIntervalsCount);
    }

    function linearPoolAccount(uint256 poolIndex, address address_)
        public
        view
        returns (
            AccountState memory state,
            ComplexAccountState memory complex,
            uint256 immediatelyUnlockedAmount
        )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsLinear(pool);
        Account storage account = pool.accounts[address_];
        return (account.state, account.complex, account.immediatelyUnlockedAmount);
    }

    function collectedFees(IERC20 token) public view returns (uint256) {
        return _collectedFees[token];
    }

    event AccountLimitChanged(uint256 indexed poolIndex, address indexed address_, uint256 indexed limitIndex);
    event FeeWithdrawn(address indexed token, uint256 amount);
    event ImmediatelyUnlockingPartUpdated(uint256 indexed poolIndex, uint256 mantissa);
    event IntervalCreated(uint256 indexed poolIndex, uint256 startsAt, uint256 unlockingPart);
    event IssuanceIncreased(uint256 indexed poolIndex, uint256 amount);
    event LinearUnlockingEndingTimestampUpdated(uint256 indexed poolIndex, uint256 timestamp);
    event LinearPoolUnlocking(uint256 indexed poolIndex, address indexed account, uint256 amount);
    event PaymentLimitCreated(uint256 indexed poolIndex, uint256 indexed limitIndex, uint256 limit);
    event PaymentLimitChanged(uint256 indexed poolIndex, uint256 indexed limitIndex, uint256 newLimit);
    event PaymentUnlocked(uint256 indexed poolIndex, uint256 unlockedAmount, uint256 collectedFee);
    event PaymentsWithdrawn(uint256 indexed poolIndex, uint256 amount);
    event PoolOwnerChanged(uint256 indexed poolIndex, address indexed newOwner);
    event PoolOwnerNominated(uint256 indexed poolIndex, address indexed nominatedOwner);
    event UnsoldWithdrawn(uint256 indexed poolIndex, uint256 amount);

    event PoolCreated(
        Type type_,
        IERC20 indexed paymentToken,
        IERC20 indexed issuanceToken,
        uint256 poolIndex,
        uint256 issuanceLimit,
        uint256 startsAt,
        uint256 endsAt,
        uint256 fee,
        uint256 rate,
        uint256 paymentLimit
    );

    event Swap(
        uint256 indexed poolIndex,
        address indexed caller,
        uint256 requestedPaymentAmount,
        uint256 paymentAmount,
        uint256 issuanceAmount
    );

    constructor(address owner_) public TwoStageOwnable(owner_) {
        return;
    }

    function createSimplePool(
        Props memory props,
        uint256 paymentLimit,
        address owner_
    ) external onlyOwner returns (bool success, uint256 poolIndex) {
        return (true, _createSimplePool(props, paymentLimit, owner_, Type.SIMPLE).index);
    }

    function createIntervalPool(
        Props memory props,
        uint256 paymentLimit,
        address owner_,
        AttoDecimal.Instance memory immediatelyUnlockingPart,
        Interval[] memory intervals
    ) external onlyOwner returns (bool success, uint256 poolIndex) {
        Pool storage pool = _createSimplePool(props, paymentLimit, owner_, Type.INTERVAL);
        _setImmediatelyUnlockingPart(pool, immediatelyUnlockingPart);
        uint256 intervalsCount = intervals.length;
        AttoDecimal.Instance memory lastUnlockingPart = immediatelyUnlockingPart;
        uint256 lastIntervalStartingTimestamp = props.endsAt - 1;
        for (uint256 i = 0; i < intervalsCount; i++) {
            Interval memory interval = intervals[i];
            require(interval.unlockingPart.gt(lastUnlockingPart), "Invalid interval unlocking part");
            lastUnlockingPart = interval.unlockingPart;
            uint256 startingTimestamp = interval.startsAt;
            require(startingTimestamp > lastIntervalStartingTimestamp, "Invalid interval starting timestamp");
            lastIntervalStartingTimestamp = startingTimestamp;
            pool.intervals.push(interval);
            emit IntervalCreated(poolIndex, interval.startsAt, interval.unlockingPart.mantissa);
        }
        require(lastUnlockingPart.eq(1), "Unlocking part not equal to one");
        return (true, pool.index);
    }

    function createLinearPool(
        Props memory props,
        uint256 paymentLimit,
        address owner_,
        AttoDecimal.Instance memory immediatelyUnlockingPart,
        uint256 linearUnlockingEndsAt
    ) external onlyOwner returns (bool success, uint256 poolIndex) {
        require(linearUnlockingEndsAt > props.endsAt, "Linear unlocking less than or equal to pool ending timestamp");
        Pool storage pool = _createSimplePool(props, paymentLimit, owner_, Type.LINEAR);
        _setImmediatelyUnlockingPart(pool, immediatelyUnlockingPart);
        pool.linear.endsAt = linearUnlockingEndsAt;
        pool.linear.duration = linearUnlockingEndsAt - props.endsAt;
        emit LinearUnlockingEndingTimestampUpdated(pool.index, linearUnlockingEndsAt);
        return (true, pool.index);
    }

    function increaseIssuance(uint256 poolIndex, uint256 amount) external returns (bool success) {
        require(amount > 0, "Amount is zero");
        Pool storage pool = _getPool(poolIndex);
        require(getTimestamp() < pool.props.endsAt, "Pool ended");
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        pool.state.issuance = pool.state.issuance.add(amount);
        require(pool.state.issuance <= pool.props.issuanceLimit, "Issuance limit exceeded");
        pool.state.available = pool.state.available.add(amount);
        emit IssuanceIncreased(poolIndex, amount);
        pool.props.issuanceToken.safeTransferFrom(caller, address(this), amount);
        return true;
    }

    function swap(uint256 poolIndex, uint256 requestedPaymentAmount)
        external
        nonReentrant
        returns (uint256 paymentAmount, uint256 issuanceAmount)
    {
        require(requestedPaymentAmount > 0, "Requested payment amount is zero");
        address caller = msg.sender;
        Pool storage pool = _getPool(poolIndex);
        uint256 timestamp = getTimestamp();
        require(timestamp >= pool.props.startsAt, "Pool not started");
        require(timestamp < pool.props.endsAt, "Pool ended");
        require(pool.state.available > 0, "No available issuance");
        (paymentAmount, issuanceAmount) = _calculateSwapAmounts(pool, requestedPaymentAmount, caller);
        Account storage account = pool.accounts[caller];
        if (paymentAmount > 0) {
            pool.state.lockedPayments = pool.state.lockedPayments.add(paymentAmount);
            account.state.paymentSum = account.state.paymentSum.add(paymentAmount);
            pool.props.paymentToken.safeTransferFrom(caller, address(this), paymentAmount);
        }
        if (issuanceAmount > 0) {
            if (pool.type_ == Type.SIMPLE) pool.props.issuanceToken.safeTransfer(caller, issuanceAmount);
            else {
                uint256 totalIssuanceAmount = account.complex.issuanceAmount.add(issuanceAmount);
                account.complex.issuanceAmount = totalIssuanceAmount;
                uint256 newWithdrawnIssuanceAmount = pool.immediatelyUnlockingPart.mul(totalIssuanceAmount).floor();
                uint256 issuanceToWithdraw = newWithdrawnIssuanceAmount - account.complex.withdrawnIssuanceAmount;
                account.complex.withdrawnIssuanceAmount = newWithdrawnIssuanceAmount;
                if (pool.type_ == Type.LINEAR) account.immediatelyUnlockedAmount = newWithdrawnIssuanceAmount;
                if (issuanceToWithdraw > 0) pool.props.issuanceToken.safeTransfer(caller, issuanceToWithdraw);
            }
            pool.state.available = pool.state.available.sub(issuanceAmount);
        }
        emit Swap(poolIndex, caller, requestedPaymentAmount, paymentAmount, issuanceAmount);
    }

    function unlockInterval(uint256 poolIndex, uint256 intervalIndex)
        external
        returns (uint256 withdrawnIssuanceAmount)
    {
        address caller = msg.sender;
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsInterval(pool);
        require(intervalIndex < pool.intervals.length, "Invalid interval index");
        Interval storage interval = pool.intervals[intervalIndex];
        require(interval.startsAt <= getTimestamp(), "Interval not started");
        Account storage account = pool.accounts[caller];
        require(intervalIndex >= account.unlockedIntervalsCount, "Already unlocked");
        uint256 newWithdrawnIssuanceAmount = interval.unlockingPart.mul(account.complex.issuanceAmount).floor();
        uint256 issuanceToWithdraw = newWithdrawnIssuanceAmount - account.complex.withdrawnIssuanceAmount;
        account.complex.withdrawnIssuanceAmount = newWithdrawnIssuanceAmount;
        if (issuanceToWithdraw > 0) pool.props.issuanceToken.safeTransfer(caller, issuanceToWithdraw);
        account.unlockedIntervalsCount = intervalIndex.add(1);
        return issuanceToWithdraw;
    }

    function unlockLinear(uint256 poolIndex) external returns (uint256 withdrawalAmount) {
        address caller = msg.sender;
        uint256 timestamp = getTimestamp();
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsLinear(pool);
        require(pool.props.endsAt < timestamp, "Pool not ended");
        Account storage account = pool.accounts[caller];
        uint256 issuanceAmount = account.complex.issuanceAmount;
        require(account.complex.withdrawnIssuanceAmount < issuanceAmount, "All funds already unlocked");
        uint256 passedTime = timestamp - pool.props.endsAt;
        uint256 freezedAmount = issuanceAmount.sub(account.immediatelyUnlockedAmount);
        uint256 unfreezedAmount = passedTime.mul(freezedAmount).div(pool.linear.duration);
        uint256 newWithdrawnIssuanceAmount = timestamp >= pool.linear.endsAt
            ? issuanceAmount
            : Math.min(account.immediatelyUnlockedAmount.add(unfreezedAmount), issuanceAmount);
        withdrawalAmount = newWithdrawnIssuanceAmount.sub(account.complex.withdrawnIssuanceAmount);
        if (withdrawalAmount > 0) {
            account.complex.withdrawnIssuanceAmount = newWithdrawnIssuanceAmount;
            emit LinearPoolUnlocking(pool.index, caller, withdrawalAmount);
            pool.props.issuanceToken.safeTransfer(caller, withdrawalAmount);
        }
    }

    function createPaymentLimit(uint256 poolIndex, uint256 limit) external returns (uint256 limitIndex) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        limitIndex = pool.state.paymentLimits.length;
        pool.state.paymentLimits.push(limit);
        emit PaymentLimitCreated(poolIndex, limitIndex, limit);
    }

    function changeLimit(
        uint256 poolIndex,
        uint256 limitIndex,
        uint256 newLimit
    ) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        _validateLimitIndex(pool, limitIndex);
        pool.state.paymentLimits[limitIndex] = newLimit;
        emit PaymentLimitChanged(poolIndex, limitIndex, newLimit);
        return true;
    }

    function setAccountsLimit(
        uint256 poolIndex,
        uint256 limitIndex,
        address[] memory accounts
    ) external returns (bool succcess) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        _validateLimitIndex(pool, limitIndex);
        uint256 accountsCount = accounts.length;
        require(accountsCount > 0, "No accounts provided");
        for (uint256 i = 0; i < accountsCount; i++) {
            address account = accounts[i];
            Account storage poolAccount_ = pool.accounts[account];
            if (poolAccount_.state.limitIndex == limitIndex) continue;
            poolAccount_.state.limitIndex = limitIndex;
            emit AccountLimitChanged(poolIndex, account, limitIndex);
        }
        return true;
    }

    function withdrawPayments(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        _unlockPayments(pool);
        uint256 collectedPayments = pool.state.unlockedPayments;
        require(collectedPayments > 0, "No collected payments");
        pool.state.unlockedPayments = 0;
        emit PaymentsWithdrawn(poolIndex, collectedPayments);
        pool.props.paymentToken.safeTransfer(caller, collectedPayments);
        return true;
    }

    function withdrawUnsold(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        require(getTimestamp() >= pool.props.endsAt, "Not ended");
        uint256 amount = pool.state.available;
        require(amount > 0, "No unsold");
        pool.state.available = 0;
        emit UnsoldWithdrawn(poolIndex, amount);
        pool.props.issuanceToken.safeTransfer(caller, amount);
        return true;
    }

    function collectFee(uint256 poolIndex) external onlyOwner returns (bool success) {
        _unlockPayments(_getPool(poolIndex));
        return true;
    }

    function withdrawFee(IERC20 token) external onlyOwner returns (bool success) {
        uint256 collectedFee = _collectedFees[token];
        require(collectedFee > 0, "No collected fees");
        _collectedFees[token] = 0;
        emit FeeWithdrawn(address(token), collectedFee);
        token.safeTransfer(owner(), collectedFee);
        return true;
    }

    function nominateNewPoolOwner(uint256 poolIndex, address nominatedOwner_) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        require(nominatedOwner_ != pool.state.owner, "Already owner");
        if (pool.state.nominatedOwner == nominatedOwner_) return true;
        pool.state.nominatedOwner = nominatedOwner_;
        emit PoolOwnerNominated(poolIndex, nominatedOwner_);
        return true;
    }

    function acceptPoolOwnership(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        require(pool.state.nominatedOwner == caller, "Not nominated to pool ownership");
        pool.state.owner = caller;
        pool.state.nominatedOwner = address(0);
        emit PoolOwnerChanged(poolIndex, caller);
        return true;
    }

    function _assertPoolIsInterval(Pool storage pool) private view {
        require(pool.type_ == Type.INTERVAL, "Not interval pool");
    }

    function _assertPoolIsLinear(Pool storage pool) private view {
        require(pool.type_ == Type.LINEAR, "Not linear pool");
    }

    function _assertPoolOwnership(Pool storage pool, address account) private view {
        require(account == pool.state.owner, "Permission denied");
    }

    function _calculateSwapAmounts(
        Pool storage pool,
        uint256 requestedPaymentAmount,
        address account
    ) private view returns (uint256 paymentAmount, uint256 issuanceAmount) {
        paymentAmount = requestedPaymentAmount;
        Account storage poolAccount_ = pool.accounts[account];
        uint256 paymentLimit = pool.state.paymentLimits[poolAccount_.state.limitIndex];
        require(poolAccount_.state.paymentSum < paymentLimit, "Account payment limit exceeded");
        if (poolAccount_.state.paymentSum.add(paymentAmount) > paymentLimit) {
            paymentAmount = paymentLimit.sub(poolAccount_.state.paymentSum);
        }
        issuanceAmount = pool.props.rate.mul(paymentAmount).floor();
        if (issuanceAmount > pool.state.available) {
            issuanceAmount = pool.state.available;
            paymentAmount = AttoDecimal.div(issuanceAmount, pool.props.rate).ceil();
        }
    }

    function _getPool(uint256 index) private view returns (Pool storage) {
        require(index < _pools.length, "Pool not found");
        return _pools[index];
    }

    function _validateLimitIndex(Pool storage pool, uint256 limitIndex) private view {
        require(limitIndex < pool.state.paymentLimits.length, "Limit not found");
    }

    function _createSimplePool(
        Props memory props,
        uint256 paymentLimit,
        address owner_,
        Type type_
    ) private returns (Pool storage) {
        {
            uint256 timestamp = getTimestamp();
            if (props.startsAt < timestamp) props.startsAt = timestamp;
            require(props.fee.lt(100), "Fee gte 100%");
            require(props.startsAt < props.endsAt, "Invalid ending timestamp");
        }
        uint256 poolIndex = _pools.length;
        _pools.push();
        Pool storage pool = _pools[poolIndex];
        pool.index = poolIndex;
        pool.type_ = type_;
        pool.props = props;
        pool.state.paymentLimits = new uint256[](1);
        pool.state.paymentLimits[0] = paymentLimit;
        pool.state.owner = owner_;
        emit PoolCreated(
            type_,
            props.paymentToken,
            props.issuanceToken,
            poolIndex,
            props.issuanceLimit,
            props.startsAt,
            props.endsAt,
            props.fee.mantissa,
            props.rate.mantissa,
            paymentLimit
        );
        emit PoolOwnerChanged(poolIndex, owner_);
        return pool;
    }

    function _setImmediatelyUnlockingPart(Pool storage pool, AttoDecimal.Instance memory immediatelyUnlockingPart)
        private
    {
        require(immediatelyUnlockingPart.lt(1), "Invalid immediately unlocking part value");
        pool.immediatelyUnlockingPart = immediatelyUnlockingPart;
        emit ImmediatelyUnlockingPartUpdated(pool.index, immediatelyUnlockingPart.mantissa);
    }

    function _unlockPayments(Pool storage pool) private {
        if (pool.state.lockedPayments == 0) return;
        uint256 fee = pool.props.fee.mul(pool.state.lockedPayments).ceil();
        _collectedFees[pool.props.paymentToken] = _collectedFees[pool.props.paymentToken].add(fee);
        uint256 unlockedAmount = pool.state.lockedPayments.sub(fee);
        pool.state.unlockedPayments = pool.state.unlockedPayments.add(unlockedAmount);
        pool.state.lockedPayments = 0;
        emit PaymentUnlocked(pool.index, unlockedAmount, fee);
    }
}