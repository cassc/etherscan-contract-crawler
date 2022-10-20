// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/utils/math/Math.sol";
import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./lib/WadRayMath.sol";
import "./access/Manageable.sol";
import "./storage/DepositTokenStorage.sol";

/**
 * @title Represents the users' deposits
 */
contract DepositToken is ReentrancyGuard, Manageable, DepositTokenStorageV1 {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    string public constant VERSION = "1.0.0";

    /// @notice Emitted when collateral is deposited
    event CollateralDeposited(address indexed from, address indexed account, uint256 amount, uint256 fee);

    /// @notice Emitted when CR is updated
    event CollateralizationRatioUpdated(uint256 oldCollateralizationRatio, uint256 newCollateralizationRatio);

    /// @notice Emitted when collateral is withdrawn
    event CollateralWithdrawn(address indexed account, address indexed to, uint256 amount, uint256 fee);

    /// @notice Emitted when active flag is updated
    event DepositTokenActiveUpdated(bool newActive);

    /// @notice Emitted when max total supply is updated
    event MaxTotalSupplyUpdated(uint256 oldMaxTotalSupply, uint256 newMaxTotalSupply);

    /**
     * @dev Throws if sender can't seize
     */
    modifier onlyIfCanSeize() {
        require(msg.sender == address(pool), "not-pool");
        _;
    }

    /**
     * @dev Throws if deposit token doesn't exist
     */
    modifier onlyIfDepositTokenExists() {
        require(pool.isDepositTokenExists(this), "collateral-inexistent");
        _;
    }

    /**
     * @dev Throws if deposit token isn't enabled
     */
    modifier onlyIfDepositTokenIsActive() {
        require(isActive, "deposit-token-inactive");
        _;
    }

    /**
     * @notice Requires that amount is lower than the account's unlocked balance
     */
    modifier onlyIfUnlocked(address account_, uint256 amount_) {
        require(unlockedBalanceOf(account_) >= amount_, "not-enough-free-balance");
        _;
    }

    /**
     * @notice Update reward contracts' states
     * @dev Should be called before balance changes (i.e. mint/burn)
     */
    modifier updateRewardsBeforeMintOrBurn(address account_) {
        IRewardsDistributor[] memory _rewardsDistributors = pool.getRewardsDistributors();
        uint256 _length = _rewardsDistributors.length;
        for (uint256 i; i < _length; ++i) {
            _rewardsDistributors[i].updateBeforeMintOrBurn(this, account_);
        }
        _;
    }

    /**
     * @notice Update reward contracts' states
     * @dev Should be called before balance changes (i.e. transfer)
     */
    modifier updateRewardsBeforeTransfer(address sender_, address recipient_) {
        IRewardsDistributor[] memory _rewardsDistributors = pool.getRewardsDistributors();
        uint256 _length = _rewardsDistributors.length;
        for (uint256 i; i < _length; ++i) {
            _rewardsDistributors[i].updateBeforeTransfer(this, sender_, recipient_);
        }
        _;
    }

    function initialize(
        IERC20 underlying_,
        IPool pool_,
        string calldata symbol_,
        uint8 decimals_,
        uint128 collateralizationRatio_,
        uint256 maxTotalSupply_
    ) external initializer {
        require(address(underlying_) != address(0), "underlying-is-null");
        require(collateralizationRatio_ <= 1e18, "collateralization-ratio-gt-100%");

        __ReentrancyGuard_init();
        __Manageable_init(pool_);

        name = "Tokenized deposit position";
        symbol = symbol_;
        underlying = underlying_;
        isActive = true;
        decimals = decimals_;
        collateralizationRatio = collateralizationRatio_;
        maxTotalSupply = maxTotalSupply_;
    }

    /**
     * @notice Set `amount` as the allowance of `spender` over the caller's tokens
     */
    function approve(address spender_, uint256 amount_) external override returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    /**
     * @notice Atomically decrease the allowance granted to `spender` by the caller
     */
    function decreaseAllowance(address spender_, uint256 subtractedValue_) external returns (bool) {
        uint256 _currentAllowance = allowance[msg.sender][spender_];
        require(_currentAllowance >= subtractedValue_, "decreased-allowance-below-zero");
        unchecked {
            _approve(msg.sender, spender_, _currentAllowance - subtractedValue_);
        }
        return true;
    }

    /**
     * @notice Deposit collateral and mint msdTOKEN (tokenized deposit position)
     * @param amount_ The amount of collateral tokens to deposit
     * @param onBehalfOf_ The account to deposit to
     */
    function deposit(uint256 amount_, address onBehalfOf_)
        external
        override
        whenNotPaused
        nonReentrant
        onlyIfDepositTokenIsActive
        onlyIfDepositTokenExists
    {
        require(amount_ > 0, "amount-is-zero");

        address _treasury = address(pool.treasury());

        uint256 _balanceBefore = underlying.balanceOf(_treasury);
        underlying.safeTransferFrom(msg.sender, _treasury, amount_);
        amount_ = underlying.balanceOf(_treasury) - _balanceBefore;

        uint256 _depositFee = pool.depositFee();
        uint256 _amountToDeposit = amount_;
        uint256 _feeAmount;
        if (_depositFee > 0) {
            _feeAmount = amount_.wadMul(_depositFee);
            _mint(pool.feeCollector(), _feeAmount);
            _amountToDeposit -= _feeAmount;
        }

        _mint(onBehalfOf_, _amountToDeposit);

        emit CollateralDeposited(msg.sender, onBehalfOf_, amount_, _feeAmount);
    }

    /**
     * @notice Atomically increase the allowance granted to `spender` by the caller
     */
    function increaseAllowance(address spender_, uint256 addedValue_) external returns (bool) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] + addedValue_);
        return true;
    }

    /**
     * @notice Get the locked balance
     * @param account_ The account to check
     * @return _lockedBalance The locked amount
     */
    function lockedBalanceOf(address account_) external view override returns (uint256 _lockedBalance) {
        unchecked {
            return balanceOf[account_] - unlockedBalanceOf(account_);
        }
    }

    /**
     * @notice Seize tokens
     * @dev Same as _transfer
     * @param from_ The account to seize from
     * @param to_ The beneficiary account
     * @param amount_ The amount to seize
     */
    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external override onlyIfCanSeize {
        _transfer(from_, to_, amount_);
    }

    /**
     * @notice Move `amount` tokens from the caller's account to `recipient`
     */
    function transfer(address to_, uint256 amount_)
        external
        override
        onlyIfUnlocked(msg.sender, amount_)
        returns (bool)
    {
        _transfer(msg.sender, to_, amount_);
        return true;
    }

    /**
     * @notice Move `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance
     */
    function transferFrom(
        address sender_,
        address recipient_,
        uint256 amount_
    ) external override nonReentrant onlyIfUnlocked(sender_, amount_) returns (bool) {
        _transfer(sender_, recipient_, amount_);

        uint256 _currentAllowance = allowance[sender_][msg.sender];
        if (_currentAllowance != type(uint256).max) {
            require(_currentAllowance >= amount_, "amount-exceeds-allowance");
            unchecked {
                _approve(sender_, msg.sender, _currentAllowance - amount_);
            }
        }

        return true;
    }

    /**
     * @notice Get the unlocked balance (i.e. transferable, withdrawable)
     * @param account_ The account to check
     * @return _unlockedBalance The amount that user can transfer or withdraw
     */
    function unlockedBalanceOf(address account_) public view override returns (uint256 _unlockedBalance) {
        (, , , , uint256 _issuableInUsd) = pool.debtPositionOf(account_);

        if (_issuableInUsd > 0) {
            _unlockedBalance = Math.min(
                balanceOf[account_],
                pool.masterOracle().quoteUsdToToken(address(underlying), _issuableInUsd.wadDiv(collateralizationRatio))
            );
        }
    }

    /**
     * @notice Burn msdTOKEN and withdraw collateral
     * @param amount_ The amount of collateral to withdraw
     * @param to_ The account that will receive withdrawn collateral
     */
    function withdraw(uint256 amount_, address to_)
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfDepositTokenExists
    {
        require(amount_ > 0 && amount_ <= unlockedBalanceOf(msg.sender), "amount-is-invalid");

        uint256 _withdrawFee = pool.withdrawFee();
        uint256 _amountToWithdraw = amount_;
        uint256 _feeAmount;
        if (_withdrawFee > 0) {
            _feeAmount = amount_.wadMul(_withdrawFee);
            _transfer(msg.sender, pool.feeCollector(), _feeAmount);
            _amountToWithdraw -= _feeAmount;
        }

        _burn(msg.sender, _amountToWithdraw);
        pool.treasury().pull(to_, _amountToWithdraw);

        emit CollateralWithdrawn(msg.sender, to_, amount_, _feeAmount);
    }

    /**
     * @notice Add this token to the deposit tokens list if the recipient is receiving it for the 1st time
     */
    function _addToDepositTokensOfRecipientIfNeeded(address recipient_, uint256 recipientBalanceBefore_) private {
        if (recipientBalanceBefore_ == 0) {
            pool.addToDepositTokensOfAccount(recipient_);
        }
    }

    /**
     * @notice Set `amount` as the allowance of `spender` over the caller's tokens
     */
    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) private {
        require(owner_ != address(0), "approve-from-the-zero-address");
        require(spender_ != address(0), "approve-to-the-zero-address");

        allowance[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    /**
     * @notice Destroy `amount` tokens from `account`, reducing the
     * total supply
     */
    function _burn(address _account, uint256 _amount) private updateRewardsBeforeMintOrBurn(_account) {
        require(_account != address(0), "burn-from-the-zero-address");

        uint256 _balanceBefore = balanceOf[_account];
        require(_balanceBefore >= _amount, "burn-amount-exceeds-balance");
        uint256 _balanceAfter;
        unchecked {
            _balanceAfter = _balanceBefore - _amount;
            totalSupply -= _amount;
        }

        balanceOf[_account] = _balanceAfter;

        emit Transfer(_account, address(0), _amount);

        _removeFromDepositTokensOfSenderIfNeeded(_account, _balanceAfter);
    }

    /**
     * @notice Create `amount` tokens and assigns them to `account`, increasing
     * the total supply
     */
    function _mint(address account_, uint256 amount_)
        private
        onlyIfDepositTokenIsActive
        updateRewardsBeforeMintOrBurn(account_)
    {
        require(account_ != address(0), "mint-to-the-zero-address");

        totalSupply += amount_;
        require(totalSupply <= maxTotalSupply, "surpass-max-deposit-supply");

        uint256 _balanceBefore = balanceOf[account_];
        unchecked {
            balanceOf[account_] = _balanceBefore + amount_;
        }

        emit Transfer(address(0), account_, amount_);

        _addToDepositTokensOfRecipientIfNeeded(account_, _balanceBefore);
    }

    /**
     * @notice Remove this token to the deposit tokens list if the sender's balance goes to zero
     */
    function _removeFromDepositTokensOfSenderIfNeeded(address sender_, uint256 senderBalanceAfter_) private {
        if (senderBalanceAfter_ == 0) {
            pool.removeFromDepositTokensOfAccount(sender_);
        }
    }

    /**
     * @notice Move `amount` of tokens from `sender` to `recipient`
     */
    function _transfer(
        address sender_,
        address recipient_,
        uint256 amount_
    ) private updateRewardsBeforeTransfer(sender_, recipient_) {
        require(sender_ != address(0), "transfer-from-the-zero-address");
        require(recipient_ != address(0), "transfer-to-the-zero-address");

        uint256 _senderBalanceBefore = balanceOf[sender_];
        require(_senderBalanceBefore >= amount_, "transfer-amount-exceeds-balance");
        uint256 _recipientBalanceBefore = balanceOf[recipient_];
        uint256 _senderBalanceAfter;

        unchecked {
            _senderBalanceAfter = _senderBalanceBefore - amount_;
            balanceOf[recipient_] = _recipientBalanceBefore + amount_;
        }

        balanceOf[sender_] = _senderBalanceAfter;

        emit Transfer(sender_, recipient_, amount_);

        _addToDepositTokensOfRecipientIfNeeded(recipient_, _recipientBalanceBefore);
        _removeFromDepositTokensOfSenderIfNeeded(sender_, _senderBalanceAfter);
    }

    /**
     * @notice Enable/Disable the Deposit Token
     */
    function toggleIsActive() external override onlyGovernor {
        bool _newIsActive = !isActive;
        emit DepositTokenActiveUpdated(_newIsActive);
        isActive = _newIsActive;
    }

    /**
     * @notice Update collateralization ratio
     * @param newCollateralizationRatio_ The new CR value
     */
    function updateCollateralizationRatio(uint128 newCollateralizationRatio_) external override onlyGovernor {
        require(newCollateralizationRatio_ <= 1e18, "collateralization-ratio-gt-100%");
        uint256 _currentCollateralizationRatio = collateralizationRatio;
        require(newCollateralizationRatio_ != _currentCollateralizationRatio, "new-same-as-current");
        emit CollateralizationRatioUpdated(_currentCollateralizationRatio, newCollateralizationRatio_);
        collateralizationRatio = newCollateralizationRatio_;
    }

    /**
     * @notice Update max total supply
     * @param newMaxTotalSupply_ The new max total supply
     */
    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external override onlyGovernor {
        uint256 _currentMaxTotalSupply = maxTotalSupply;
        require(newMaxTotalSupply_ != _currentMaxTotalSupply, "new-same-as-current");
        emit MaxTotalSupplyUpdated(_currentMaxTotalSupply, newMaxTotalSupply_);
        maxTotalSupply = newMaxTotalSupply_;
    }
}