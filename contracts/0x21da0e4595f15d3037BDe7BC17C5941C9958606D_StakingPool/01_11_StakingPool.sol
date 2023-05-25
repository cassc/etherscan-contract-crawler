// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "solowei/contracts/AttoDecimal.sol";
import "solowei/contracts/TwoStageOwnable.sol";

contract StakingPool is ERC20, ReentrancyGuard, TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AttoDecimal for AttoDecimal.Instance;

    struct Strategy {
        uint256 endsAt;
        uint256 perSecondReward;
        uint256 startsAt;
    }

    struct Unstake {
        uint256 amount;
        uint256 applicableAt;
    }

    uint256 public constant MIN_STAKE_BALANCE = 10**18;

    uint256 public claimingFeePercent;
    uint256 public lastUpdatedAt;

    uint256 private _feePool;
    uint256 private _lockedRewards;
    uint256 private _totalStaked;
    uint256 private _totalUnstaked;
    uint256 private _unstakingTime;
    IERC20 private _stakingToken;

    AttoDecimal.Instance private _defaultPrice;
    AttoDecimal.Instance private _price;
    Strategy private _currentStrategy;
    Strategy private _nextStrategy;

    mapping(address => Unstake) private _unstakes;

    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function feePool() public view returns (uint256) {
        return _feePool;
    }

    function lockedRewards() public view returns (uint256) {
        return _lockedRewards;
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function totalUnstaked() public view returns (uint256) {
        return _totalUnstaked;
    }

    function stakingToken() public view returns (IERC20) {
        return _stakingToken;
    }

    function unstakingTime() public view returns (uint256) {
        return _unstakingTime;
    }

    function currentStrategy() public view returns (Strategy memory) {
        return _currentStrategy;
    }

    function nextStrategy() public view returns (Strategy memory) {
        return _nextStrategy;
    }

    function getUnstake(address account) public view returns (Unstake memory result) {
        result = _unstakes[account];
    }

    function defaultPrice()
        external
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return _defaultPrice.toTuple();
    }

    function getCurrentStrategyUnlockedRewards() public view returns (uint256 unlocked) {
        unlocked = _getStrategyUnlockedRewards(_currentStrategy);
    }

    function getUnlockedRewards() public view returns (uint256 unlocked, bool currentStrategyEnded) {
        unlocked = _getStrategyUnlockedRewards(_currentStrategy);
        if (getTimestamp() >= _currentStrategy.endsAt) {
            currentStrategyEnded = true;
            if (_nextStrategy.endsAt != 0) unlocked = unlocked.add(_getStrategyUnlockedRewards(_nextStrategy));
        }
    }

    /// @notice Calculates price of synthetic token for current block
    function price()
        public
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        (uint256 unlocked, ) = getUnlockedRewards();
        uint256 totalStaked_ = _totalStaked;
        uint256 totalSupply_ = totalSupply();
        AttoDecimal.Instance memory result = _defaultPrice;
        if (totalSupply_ > 0) result = AttoDecimal.div(totalStaked_.add(unlocked), totalSupply_);
        return result.toTuple();
    }

    /// @notice Returns last updated price of synthetic token
    function priceStored()
        public
        view
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return _price.toTuple();
    }

    /// @notice Calculates expected result of swapping synthetic tokens for staking tokens
    /// @param account Account that wants to swap
    /// @param amount Minimum amount of staking tokens that should be received at swapping process
    /// @return unstakedAmount Amount of staking tokens that should be received at swapping process
    /// @return burnedAmount Amount of synthetic tokens that should be burned at swapping process
    function calculateUnstake(address account, uint256 amount)
        public
        view
        returns (uint256 unstakedAmount, uint256 burnedAmount)
    {
        (uint256 mantissa_, , ) = price();
        return _calculateUnstake(account, amount, AttoDecimal.Instance(mantissa_));
    }

    event Claimed(
        address indexed account,
        uint256 requestedAmount,
        uint256 claimedAmount,
        uint256 feeAmount,
        uint256 burnedAmount
    );

    event ClaimingFeePercentUpdated(uint256 feePercent);
    event CurrentStrategyUpdated(uint256 perSecondReward, uint256 startsAt, uint256 endsAt);
    event FeeClaimed(address indexed receiver, uint256 amount);
    event NextStrategyUpdated(uint256 perSecondReward, uint256 startsAt, uint256 endsAt);
    event UnstakingTimeUpdated(uint256 unstakingTime);
    event NextStrategyRemoved();
    event PoolDecreased(uint256 amount);
    event PoolIncreased(address indexed payer, uint256 amount);
    event PriceUpdated(uint256 mantissa, uint256 base, uint256 exponentiation);
    event RewardsUnlocked(uint256 amount);
    event Staked(address indexed account, address indexed payer, uint256 stakedAmount, uint256 mintedAmount);
    event Unstaked(address indexed account, uint256 requestedAmount, uint256 unstakedAmount, uint256 burnedAmount);
    event UnstakingCanceled(address indexed account, uint256 amount);
    event Withdrawed(address indexed account, uint256 amount);

    constructor(
        string memory syntheticTokenName,
        string memory syntheticTokenSymbol,
        IERC20 stakingToken_,
        address owner_,
        uint256 claimingFeePercent_,
        uint256 perSecondReward_,
        uint256 startsAt_,
        uint256 duration_,
        uint256 unstakingTime_,
        uint256 defaultPriceMantissa
    ) public TwoStageOwnable(owner_) ERC20(syntheticTokenName, syntheticTokenSymbol) {
        _defaultPrice = AttoDecimal.Instance(defaultPriceMantissa);
        _stakingToken = stakingToken_;
        _setClaimingFeePercent(claimingFeePercent_);
        _validateStrategyParameters(perSecondReward_, startsAt_, duration_);
        _setUnstakingTime(unstakingTime_);
        _setCurrentStrategy(perSecondReward_, startsAt_, startsAt_.add(duration_));
        lastUpdatedAt = getTimestamp();
        _price = _defaultPrice;
    }

    /// @notice Cancels unstaking by staking locked for withdrawals tokens
    /// @param amount Amount of locked for withdrawals tokens
    function cancelUnstaking(uint256 amount) external onlyPositiveAmount(amount) returns (bool success) {
        _update();
        address caller = msg.sender;
        Unstake storage unstake_ = _unstakes[caller];
        uint256 unstakingAmount = unstake_.amount;
        require(unstakingAmount >= amount, "Not enough unstaked balance");
        uint256 stakedAmount = _price.mul(balanceOf(caller)).floor();
        require(stakedAmount.add(amount) >= MIN_STAKE_BALANCE, "Stake balance lt min stake");
        uint256 synthAmount = AttoDecimal.div(amount, _price).floor();
        _mint(caller, synthAmount);
        _totalStaked = _totalStaked.add(amount);
        _totalUnstaked = _totalUnstaked.sub(amount);
        unstake_.amount = unstakingAmount.sub(amount);
        emit Staked(caller, address(0), amount, synthAmount);
        emit UnstakingCanceled(caller, amount);
        return true;
    }

    /// @notice Swaps synthetic tokens for staking tokens and immediately sends them to the caller but takes some fee
    /// @param amount Staking tokens amount to swap for. Fee will be taked from this amount
    /// @return claimedAmount Amount of staking tokens that was been sended to caller
    /// @return burnedAmount Amount of synthetic tokens that was burned while swapping
    function claim(uint256 amount)
        external
        onlyPositiveAmount(amount)
        returns (uint256 claimedAmount, uint256 burnedAmount)
    {
        _update();
        address caller = msg.sender;
        (claimedAmount, burnedAmount) = _calculateUnstake(caller, amount, _price);
        uint256 fee = claimedAmount.mul(claimingFeePercent).div(100);
        _burn(caller, burnedAmount);
        _totalStaked = _totalStaked.sub(claimedAmount);
        claimedAmount = claimedAmount.sub(fee);
        _feePool = _feePool.add(fee);
        emit Claimed(caller, amount, claimedAmount, fee, burnedAmount);
        _stakingToken.safeTransfer(caller, claimedAmount);
    }

    /// @notice Withdraws all staking tokens, that have been accumulated in imidiatly claiming process.
    ///     Allowed to be called only by the owner
    /// @return amount Amount of accumulated and withdrawed tokens
    function claimFees() external onlyOwner returns (uint256 amount) {
        require(_feePool > 0, "No fees");
        amount = _feePool;
        _feePool = 0;
        emit FeeClaimed(owner(), amount);
        _stakingToken.safeTransfer(owner(), amount);
    }

    /// @notice Creates new strategy. Allowed to be called only by the owner
    /// @param perSecondReward_ Reward that should be added to common staking tokens pool every second
    /// @param startsAt_ Timestamp from which strategy should starts
    /// @param duration_ Seconds count for which new strategy should be applied
    function createNewStrategy(
        uint256 perSecondReward_,
        uint256 startsAt_,
        uint256 duration_
    ) public onlyOwner returns (bool success) {
        _update();
        _validateStrategyParameters(perSecondReward_, startsAt_, duration_);
        uint256 endsAt = startsAt_.add(duration_);
        Strategy memory strategy = Strategy({perSecondReward: perSecondReward_, startsAt: startsAt_, endsAt: endsAt});
        if (_currentStrategy.startsAt > getTimestamp()) {
            delete _nextStrategy;
            emit NextStrategyRemoved();
            _currentStrategy = strategy;
            emit CurrentStrategyUpdated(perSecondReward_, startsAt_, endsAt);
        } else {
            emit NextStrategyUpdated(perSecondReward_, startsAt_, endsAt);
            _nextStrategy = strategy;
            if (_currentStrategy.endsAt > startsAt_) {
                _currentStrategy.endsAt = startsAt_;
                emit CurrentStrategyUpdated(_currentStrategy.perSecondReward, _currentStrategy.startsAt, startsAt_);
            }
        }
        return true;
    }

    function decreasePool(uint256 amount) external onlyPositiveAmount(amount) onlyOwner returns (bool success) {
        _update();
        _lockedRewards = _lockedRewards.sub(amount, "Not enough locked rewards");
        emit PoolDecreased(amount);
        _stakingToken.safeTransfer(owner(), amount);
        return true;
    }

    /// @notice Increases pool of rewards
    /// @param amount Amount of staking tokens (in wei) that should be added to rewards pool
    function increasePool(uint256 amount) external onlyPositiveAmount(amount) returns (bool success) {
        _update();
        address payer = msg.sender;
        _lockedRewards = _lockedRewards.add(amount);
        emit PoolIncreased(payer, amount);
        _stakingToken.safeTransferFrom(payer, address(this), amount);
        return true;
    }

    /// @notice Change claiming fee percent. Can be called only by the owner
    /// @param feePercent New claiming fee percent
    function setClaimingFeePercent(uint256 feePercent) external onlyOwner returns (bool success) {
        _setClaimingFeePercent(feePercent);
        return true;
    }

    /// @notice Converts staking tokens to synthetic tokens
    /// @param amount Amount of staking tokens to be swapped
    /// @return mintedAmount Amount of synthetic tokens that was received at swapping process
    function stake(uint256 amount) external onlyPositiveAmount(amount) returns (uint256 mintedAmount) {
        address staker = msg.sender;
        return _stake(staker, staker, amount);
    }

    /// @notice Converts staking tokens to synthetic tokens and sends them to specific account
    /// @param account Receiver of synthetic tokens
    /// @param amount Amount of staking tokens to be swapped
    /// @return mintedAmount Amount of synthetic tokens that was received by specified account at swapping process
    function stakeForUser(address account, uint256 amount)
        external
        onlyPositiveAmount(amount)
        returns (uint256 mintedAmount)
    {
        return _stake(account, msg.sender, amount);
    }

    /// @notice Swapes synthetic tokens for staking tokens and locks them for some period
    /// @param amount Minimum amount of staking tokens that should be locked after swapping process
    /// @return unstakedAmount Amount of staking tokens that was locked
    /// @return burnedAmount Amount of synthetic tokens that was burned
    function unstake(uint256 amount)
        external
        onlyPositiveAmount(amount)
        returns (uint256 unstakedAmount, uint256 burnedAmount)
    {
        _update();
        address caller = msg.sender;
        (unstakedAmount, burnedAmount) = _calculateUnstake(caller, amount, _price);
        _burn(caller, burnedAmount);
        _totalStaked = _totalStaked.sub(unstakedAmount);
        _totalUnstaked = _totalUnstaked.add(unstakedAmount);
        Unstake storage unstake_ = _unstakes[caller];
        unstake_.amount = unstake_.amount.add(unstakedAmount);
        unstake_.applicableAt = getTimestamp().add(_unstakingTime);
        emit Unstaked(caller, amount, unstakedAmount, burnedAmount);
    }

    /// @notice Updates price of synthetic token
    /// @dev Automatically has been called on every contract action, that uses or can affect price
    function update() external returns (bool success) {
        _update();
        return true;
    }

    /// @notice Withdraws unstaked staking tokens
    function withdraw() external returns (bool success) {
        address caller = msg.sender;
        Unstake storage unstake_ = _unstakes[caller];
        uint256 amount = unstake_.amount;
        require(amount > 0, "Not unstaked");
        require(unstake_.applicableAt <= getTimestamp(), "Not released at");
        delete _unstakes[caller];
        _totalUnstaked = _totalUnstaked.sub(amount);
        emit Withdrawed(caller, amount);
        _stakingToken.safeTransfer(caller, amount);
        return true;
    }

    /// @notice Change unstaking time. Can be called only by the owner
    /// @param unstakingTime_ New unstaking process duration in seconds
    function setUnstakingTime(uint256 unstakingTime_) external onlyOwner returns (bool success) {
        _setUnstakingTime(unstakingTime_);
        return true;
    }

    function _getStrategyUnlockedRewards(Strategy memory strategy_) internal view returns (uint256 unlocked) {
        uint256 timestamp = getTimestamp();
        if (timestamp < strategy_.startsAt || timestamp == lastUpdatedAt) {
            return unlocked;
        }
        uint256 lastRewardedSecond = Math.max(lastUpdatedAt, strategy_.startsAt);
        uint256 lastRewardableTimestamp = Math.min(timestamp, strategy_.endsAt);
        if (lastRewardedSecond < lastRewardableTimestamp) {
            uint256 timeDiff = lastRewardableTimestamp.sub(lastRewardedSecond);
            unlocked = unlocked.add(timeDiff.mul(strategy_.perSecondReward));
        }
    }

    function _calculateUnstake(
        address account,
        uint256 amount,
        AttoDecimal.Instance memory price_
    ) internal view returns (uint256 unstakedAmount, uint256 burnedAmount) {
        unstakedAmount = amount;
        burnedAmount = AttoDecimal.div(amount, price_).ceil();
        uint256 balance = balanceOf(account);
        require(burnedAmount > 0, "Too small unstaking amount");
        require(balance >= burnedAmount, "Not enough synthetic tokens");
        uint256 remainingSyntheticBalance = balance.sub(burnedAmount);
        uint256 remainingStake = _price.mul(remainingSyntheticBalance).floor();
        if (remainingStake < 10**18) {
            burnedAmount = balance;
            unstakedAmount = unstakedAmount.add(remainingStake);
        }
    }

    function _unlockRewardsAndStake() internal {
        (uint256 unlocked, bool currentStrategyEnded) = getUnlockedRewards();
        if (currentStrategyEnded) {
            _currentStrategy = _nextStrategy;
            emit NextStrategyRemoved();
            if (_currentStrategy.endsAt != 0) {
                emit CurrentStrategyUpdated(
                    _currentStrategy.perSecondReward,
                    _currentStrategy.startsAt,
                    _currentStrategy.endsAt
                );
            }
            delete _nextStrategy;
        }
        unlocked = Math.min(unlocked, _lockedRewards);
        if (unlocked > 0) {
            emit RewardsUnlocked(unlocked);
            _lockedRewards = _lockedRewards.sub(unlocked);
            _totalStaked = _totalStaked.add(unlocked);
        }
        lastUpdatedAt = getTimestamp();
    }

    function _update() internal {
        if (getTimestamp() <= lastUpdatedAt) return;
        _unlockRewardsAndStake();
        _updatePrice();
    }

    function _updatePrice() internal {
        uint256 totalStaked_ = _totalStaked;
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) _price = _defaultPrice;
        else _price = AttoDecimal.div(totalStaked_, totalSupply_);
        emit PriceUpdated(_price.mantissa, AttoDecimal.BASE, AttoDecimal.EXPONENTIATION);
    }

    function _validateStrategyParameters(
        uint256 perSecondReward,
        uint256 startsAt,
        uint256 duration
    ) internal view {
        require(duration > 0, "Duration is zero");
        require(startsAt >= getTimestamp(), "Starting timestamp lt current");
        require(perSecondReward <= 188 * 10**18, "Per second reward overflow");
    }

    function _setClaimingFeePercent(uint256 feePercent) internal {
        require(feePercent >= 0 && feePercent <= 100, "Invalid fee percent");
        claimingFeePercent = feePercent;
        emit ClaimingFeePercentUpdated(feePercent);
    }

    function _setUnstakingTime(uint256 unstakingTime_) internal {
        _unstakingTime = unstakingTime_;
        emit UnstakingTimeUpdated(unstakingTime_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _update();
        string memory errorText = "Minimal stake balance should be more or equal to 1 token";
        if (from != address(0)) {
            uint256 fromNewBalance = _price.mul(balanceOf(from).sub(amount)).floor();
            require(fromNewBalance >= MIN_STAKE_BALANCE || fromNewBalance == 0, errorText);
        }
        if (to != address(0)) {
            require(_price.mul(balanceOf(to).add(amount)).floor() >= MIN_STAKE_BALANCE, errorText);
        }
    }

    function _setCurrentStrategy(
        uint256 perSecondReward_,
        uint256 startsAt_,
        uint256 endsAt_
    ) private {
        _currentStrategy = Strategy({perSecondReward: perSecondReward_, startsAt: startsAt_, endsAt: endsAt_});
        emit CurrentStrategyUpdated(perSecondReward_, startsAt_, endsAt_);
    }

    function _stake(
        address staker,
        address payer,
        uint256 amount
    ) private returns (uint256 mintedAmount) {
        _update();
        mintedAmount = AttoDecimal.div(amount, _price).floor();
        require(mintedAmount > 0, "Too small staking amount");
        _mint(staker, mintedAmount);
        _totalStaked = _totalStaked.add(amount);
        emit Staked(staker, payer, amount, mintedAmount);
        _stakingToken.safeTransferFrom(payer, address(this), amount);
    }

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Amount is not positive");
        _;
    }
}