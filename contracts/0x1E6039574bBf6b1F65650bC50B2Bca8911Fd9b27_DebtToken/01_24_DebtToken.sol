// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./utils/TokenHolder.sol";
import "./access/Manageable.sol";
import "./storage/DebtTokenStorage.sol";
import "./lib/WadRayMath.sol";

error SyntheticDoesNotExist();
error SyntheticIsInactive();
error DebtTokenInactive();
error NameIsNull();
error SymbolIsNull();
error PoolIsNull();
error SyntheticIsNull();
error AllowanceNotSupported();
error ApprovalNotSupported();
error AmountIsZero();
error NotEnoughCollateral();
error DebtLowerThanTheFloor();
error RemainingDebtIsLowerThanTheFloor();
error TransferNotSupported();
error BurnFromNullAddress();
error BurnAmountExceedsBalance();
error MintToNullAddress();
error SurpassMaxDebtSupply();
error NewValueIsSameAsCurrent();

/**
 * @title Non-transferable token that represents users' debts
 */
contract DebtToken is ReentrancyGuard, TokenHolder, Manageable, DebtTokenStorageV2 {
    using WadRayMath for uint256;

    uint256 public constant SECONDS_PER_YEAR = 365.25 days;
    uint256 private constant HUNDRED_PERCENT = 1e18;

    string public constant VERSION = "1.2.0";

    /// @notice Emitted when synthetic's debt is repaid
    event DebtRepaid(address indexed payer, address indexed account, uint256 amount, uint256 repaid, uint256 fee);

    /// @notice Emitted when active flag is updated
    event DebtTokenActiveUpdated(bool newActive);

    /// @notice Emitted when interest rate is updated
    event InterestRateUpdated(uint256 oldInterestRate, uint256 newInterestRate);

    /// @notice Emitted when max total supply is updated
    event MaxTotalSupplyUpdated(uint256 oldMaxTotalSupply, uint256 newMaxTotalSupply);

    /// @notice Emitted when synthetic token is issued
    event SyntheticTokenIssued(
        address indexed account,
        address indexed to,
        uint256 amount,
        uint256 issued,
        uint256 fee
    );

    /**
     * @dev Throws if sender can't burn
     */
    modifier onlyIfPool() {
        if (msg.sender != address(pool)) revert SenderIsNotPool();
        _;
    }

    /**
     * @dev Throws if synthetic token doesn't exist
     */
    modifier onlyIfSyntheticTokenExists() {
        if (!pool.doesSyntheticTokenExist(syntheticToken)) revert SyntheticDoesNotExist();
        _;
    }

    /**
     * @dev Throws if synthetic token isn't enabled
     */
    modifier onlyIfSyntheticTokenIsActive() {
        if (!syntheticToken.isActive()) revert SyntheticIsInactive();
        if (!isActive) revert DebtTokenInactive();
        _;
    }

    /**
     * @notice Update reward contracts' states
     * @dev Should be called before balance changes (i.e. mint/burn)
     */
    modifier updateRewardsBeforeMintOrBurn(address account_) {
        address[] memory _rewardsDistributors = pool.getRewardsDistributors();
        ISyntheticToken _syntheticToken = syntheticToken;
        uint256 _length = _rewardsDistributors.length;
        for (uint256 i; i < _length; ++i) {
            IRewardsDistributor(_rewardsDistributors[i]).updateBeforeMintOrBurn(_syntheticToken, account_);
        }
        _;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        IPool pool_,
        ISyntheticToken syntheticToken_,
        uint256 interestRate_,
        uint256 maxTotalSupply_
    ) external initializer {
        if (bytes(name_).length == 0) revert NameIsNull();
        if (bytes(symbol_).length == 0) revert SymbolIsNull();
        if (address(pool_) == address(0)) revert PoolIsNull();
        if (address(syntheticToken_) == address(0)) revert SyntheticIsNull();

        __ReentrancyGuard_init();
        __Manageable_init(pool_);

        name = name_;
        symbol = symbol_;
        decimals = syntheticToken_.decimals();
        syntheticToken = syntheticToken_;
        lastTimestampAccrued = block.timestamp;
        debtIndex = 1e18;
        interestRate = interestRate_;
        maxTotalSupply = maxTotalSupply_;
        isActive = true;
    }

    /**
     * @notice Accrue interest over debt supply
     */
    function accrueInterest() public override {
        (
            uint256 _interestAmountAccrued,
            uint256 _debtIndex,
            uint256 _lastTimestampAccrued
        ) = _calculateInterestAccrual();

        if (block.timestamp == _lastTimestampAccrued) {
            return;
        }

        lastTimestampAccrued = block.timestamp;

        if (_interestAmountAccrued > 0) {
            totalSupply_ += _interestAmountAccrued;
            debtIndex = _debtIndex;

            // Note: Address states where minting will fail (e.g. the token is inactive, it reached max supply, etc)
            try syntheticToken.mint(pool.feeCollector(), _interestAmountAccrued + pendingInterestFee) {
                pendingInterestFee = 0;
            } catch {
                pendingInterestFee += _interestAmountAccrued;
            }
        }
    }

    /// @inheritdoc IERC20
    function allowance(address /*owner_*/, address /*spender_*/) external pure override returns (uint256) {
        revert AllowanceNotSupported();
    }

    /// @inheritdoc IERC20
    // solhint-disable-next-line
    function approve(address /*spender_*/, uint256 /*amount_*/) external override returns (bool) {
        revert ApprovalNotSupported();
    }

    /**
     * @notice Get the updated (principal + interest) user's debt
     */
    function balanceOf(address account_) public view override returns (uint256) {
        uint256 _principal = principalOf[account_];
        if (_principal == 0) {
            return 0;
        }

        (, uint256 _debtIndex, ) = _calculateInterestAccrual();

        // Note: The `debtIndex / debtIndexOf` gives the interest to apply to the principal amount
        return (_principal * _debtIndex) / debtIndexOf[account_];
    }

    /**
     * @notice Burn debt token
     * @param from_ The account to burn from
     * @param amount_ The amount to burn
     */
    function burn(address from_, uint256 amount_) external override onlyIfPool {
        _burn(from_, amount_);
    }

    /**
     * @notice Collect pending interest fee if any
     */
    function collectPendingInterestFee() external {
        uint256 _pendingInterestFee = pendingInterestFee;
        if (_pendingInterestFee > 0) {
            syntheticToken.mint(pool.feeCollector(), _pendingInterestFee);
            pendingInterestFee = 0;
        }
    }

    /**
     * @notice Lock collateral and mint synthetic token
     * @param amount_ The amount to mint
     * @param to_ The beneficiary account
     * @return _issued The amount issued after fees
     * @return _fee The fee amount collected
     */
    function issue(
        uint256 amount_,
        address to_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfSyntheticTokenExists
        onlyIfSyntheticTokenIsActive
        returns (uint256 _issued, uint256 _fee)
    {
        if (amount_ == 0) revert AmountIsZero();

        accrueInterest();

        IPool _pool = pool;
        ISyntheticToken _syntheticToken = syntheticToken;

        (, , , , uint256 _issuableInUsd) = _pool.debtPositionOf(msg.sender);

        IMasterOracle _masterOracle = _pool.masterOracle();

        if (amount_ > _masterOracle.quoteUsdToToken(address(_syntheticToken), _issuableInUsd)) {
            revert NotEnoughCollateral();
        }

        return _issue(_pool, _masterOracle, _syntheticToken, msg.sender, amount_, to_);
    }

    /**
     * @notice Issue synth without checking collateral
     * @dev The healthy of outcome position must be done afterhand
     * @param borrower_ The debtor account
     * @param amount_ The amount to mint
     * @return _issued The amount issued after fees
     * @return _fee The fee amount collected
     */
    function flashIssue(
        address borrower_,
        uint256 amount_
    )
        external
        override
        onlyIfPool
        whenNotShutdown
        nonReentrant
        onlyIfSyntheticTokenExists
        onlyIfSyntheticTokenIsActive
        returns (uint256 _issued, uint256 _fee)
    {
        if (amount_ == 0) revert AmountIsZero();

        accrueInterest();

        IPool _pool = pool;

        return _issue(_pool, _pool.masterOracle(), syntheticToken, borrower_, amount_, msg.sender);
    }

    /**
     * @notice Return interest rate (in percent) per second
     */
    function interestRatePerSecond() public view override returns (uint256) {
        return interestRate / SECONDS_PER_YEAR;
    }

    /**
     * @notice Quote gross `_amount` to issue `amountToIssue_` synthetic tokens
     * @param amountToIssue_ Synth to issue
     * @return _amount Gross amount
     * @return _fee The fee amount to collect
     */
    function quoteIssueIn(uint256 amountToIssue_) external view override returns (uint256 _amount, uint256 _fee) {
        uint256 _issueFee = pool.feeProvider().issueFee();
        if (_issueFee == 0) {
            return (amountToIssue_, _fee);
        }

        _amount = amountToIssue_.wadDiv(HUNDRED_PERCENT - _issueFee);
        _fee = _amount - amountToIssue_;
    }

    /**
     * @notice Quote synthetic tokens `_amountToIssue` by using gross `_amount`
     * @param amount_ Gross amount
     * @return _amountToIssue Synth to issue
     * @return _fee The fee amount to collect
     */
    function quoteIssueOut(uint256 amount_) public view override returns (uint256 _amountToIssue, uint256 _fee) {
        uint256 _issueFee = pool.feeProvider().issueFee();
        if (_issueFee == 0) {
            return (amount_, _fee);
        }

        _fee = amount_.wadMul(_issueFee);
        _amountToIssue = amount_ - _fee;
    }

    /**
     * @notice Quote synthetic token `_amount` need to repay `amountToRepay_` debt
     * @param amountToRepay_ Debt amount to repay
     * @return _amount Gross amount
     * @return _fee The fee amount to collect
     */
    function quoteRepayIn(uint256 amountToRepay_) public view override returns (uint256 _amount, uint256 _fee) {
        uint256 _repayFee = pool.feeProvider().repayFee();
        if (_repayFee == 0) {
            return (amountToRepay_, _fee);
        }

        _fee = amountToRepay_.wadMul(_repayFee);
        _amount = amountToRepay_ + _fee;
    }

    /**
     * @notice Quote debt `_amountToRepay` by burning `_amount` synthetic tokens
     * @param amount_ Gross amount
     * @return _amountToRepay Debt amount to repay
     * @return _fee The fee amount to collect
     */
    function quoteRepayOut(uint256 amount_) public view override returns (uint256 _amountToRepay, uint256 _fee) {
        uint256 _repayFee = pool.feeProvider().repayFee();
        if (_repayFee == 0) {
            return (amount_, _fee);
        }

        _amountToRepay = amount_.wadDiv(HUNDRED_PERCENT + _repayFee);
        _fee = amount_ - _amountToRepay;
    }

    /**
     * @notice Send synthetic token to decrease debt
     * @dev The msg.sender is the payer and the account beneficed
     * @param onBehalfOf_ The account that will have debt decreased
     * @param amount_ The amount of synthetic token to burn (this is the gross amount, the repay fee will be subtracted from it)
     * @return _repaid The amount repaid after fees
     */
    function repay(
        address onBehalfOf_,
        uint256 amount_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfSyntheticTokenExists
        returns (uint256 _repaid, uint256 _fee)
    {
        if (amount_ == 0) revert AmountIsZero();

        accrueInterest();

        IPool _pool = pool;
        ISyntheticToken _syntheticToken = syntheticToken;

        (_repaid, _fee) = quoteRepayOut(amount_);
        if (_fee > 0) {
            _syntheticToken.seize(msg.sender, _pool.feeCollector(), _fee);
        }

        uint256 _debtFloorInUsd = _pool.debtFloorInUsd();
        if (_debtFloorInUsd > 0) {
            uint256 _newDebtInUsd = _pool.masterOracle().quoteTokenToUsd(
                address(_syntheticToken),
                balanceOf(onBehalfOf_) - _repaid
            );
            if (_newDebtInUsd > 0 && _newDebtInUsd < _debtFloorInUsd) {
                revert RemainingDebtIsLowerThanTheFloor();
            }
        }

        _syntheticToken.burn(msg.sender, _repaid);
        _burn(onBehalfOf_, _repaid);

        emit DebtRepaid(msg.sender, onBehalfOf_, amount_, _repaid, _fee);
    }

    /**
     * @notice Send synthetic token to decrease debt
     * @dev This function helps users to no leave debt dust behind
     * @param onBehalfOf_ The account that will have debt decreased
     * @return _repaid The amount repaid after fees
     * @return _fee The fee amount collected
     */
    function repayAll(
        address onBehalfOf_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfSyntheticTokenExists
        returns (uint256 _repaid, uint256 _fee)
    {
        accrueInterest();

        _repaid = balanceOf(onBehalfOf_);
        if (_repaid == 0) revert AmountIsZero();

        ISyntheticToken _syntheticToken = syntheticToken;

        uint256 _amount;
        (_amount, _fee) = quoteRepayIn(_repaid);

        if (_fee > 0) {
            _syntheticToken.seize(msg.sender, pool.feeCollector(), _fee);
        }

        _syntheticToken.burn(msg.sender, _repaid);
        _burn(onBehalfOf_, _repaid);

        emit DebtRepaid(msg.sender, onBehalfOf_, _amount, _repaid, _fee);
    }

    /**
     * @notice Return the total supply
     */
    function totalSupply() external view override returns (uint256) {
        (uint256 _interestAmountAccrued, , ) = _calculateInterestAccrual();
        return totalSupply_ + _interestAmountAccrued;
    }

    /// @inheritdoc IERC20
    // solhint-disable-next-line
    function transfer(address /*recipient_*/, uint256 /*amount_*/) external override returns (bool) {
        revert TransferNotSupported();
    }

    /// @inheritdoc IERC20
    // solhint-disable-next-line
    function transferFrom(
        address /*sender_*/,
        address /*recipient_*/,
        uint256 /*amount_*/
    ) external override returns (bool) {
        revert TransferNotSupported();
    }

    /**
     * @notice Destroy `amount` tokens from `account`, reducing the
     * total supply
     */
    function _burn(address account_, uint256 amount_) private updateRewardsBeforeMintOrBurn(account_) {
        if (account_ == address(0)) revert BurnFromNullAddress();

        uint256 _accountBalance = balanceOf(account_);
        if (_accountBalance < amount_) revert BurnAmountExceedsBalance();

        unchecked {
            principalOf[account_] = _accountBalance - amount_;
            debtIndexOf[account_] = debtIndex;
            totalSupply_ -= amount_;
        }

        emit Transfer(account_, address(0), amount_);

        // Remove this token from the debt tokens list if the sender's balance goes to zero
        if (amount_ > 0 && balanceOf(account_) == 0) {
            pool.removeFromDebtTokensOfAccount(account_);
        }
    }

    /**
     * @notice Calculate interest to accrue
     * @dev This util function avoids code duplication across `balanceOf` and `accrueInterest`
     * @return _interestAmountAccrued The total amount of debt tokens accrued
     * @return _debtIndex The new `debtIndex` value
     */
    function _calculateInterestAccrual()
        private
        view
        returns (uint256 _interestAmountAccrued, uint256 _debtIndex, uint256 _lastTimestampAccrued)
    {
        _lastTimestampAccrued = lastTimestampAccrued;
        _debtIndex = debtIndex;

        if (block.timestamp > _lastTimestampAccrued) {
            uint256 _interestRateToAccrue = interestRatePerSecond() * (block.timestamp - _lastTimestampAccrued);
            if (_interestRateToAccrue > 0) {
                _interestAmountAccrued = _interestRateToAccrue.wadMul(totalSupply_);
                _debtIndex += _interestRateToAccrue.wadMul(debtIndex);
            }
        }
    }

    /**
     * @notice Internal function for mint synthetic token
     * @dev Not getting contracts from storage in order to save gas
     * @param pool_ The pool
     * @param masterOracle_  The oracle
     * @param syntheticToken_ The synthetic token
     * @param borrower_ The debtor account
     * @param amount_ The amount to mint
     * @param to_ The beneficiary account
     * @return _issued The amount issued after fees
     * @return _fee The fee amount collected
     */
    function _issue(
        IPool pool_,
        IMasterOracle masterOracle_,
        ISyntheticToken syntheticToken_,
        address borrower_,
        uint256 amount_,
        address to_
    ) private returns (uint256 _issued, uint256 _fee) {
        uint256 _debtFloorInUsd = pool_.debtFloorInUsd();

        if (
            _debtFloorInUsd > 0 &&
            masterOracle_.quoteTokenToUsd(address(syntheticToken), balanceOf(borrower_) + amount_) < _debtFloorInUsd
        ) {
            revert DebtLowerThanTheFloor();
        }

        (_issued, _fee) = quoteIssueOut(amount_);
        if (_fee > 0) {
            syntheticToken_.mint(pool_.feeCollector(), _fee);
        }

        syntheticToken_.mint(to_, _issued);
        _mint(borrower_, amount_);

        emit SyntheticTokenIssued(borrower_, to_, amount_, _issued, _fee);
    }

    /**
     * @notice Create `amount` tokens and assigns them to `account`, increasing
     * the total supply
     */
    function _mint(address account_, uint256 amount_) private updateRewardsBeforeMintOrBurn(account_) {
        if (account_ == address(0)) revert MintToNullAddress();

        uint256 _balanceBefore = balanceOf(account_);

        totalSupply_ += amount_;
        if (totalSupply_ > maxTotalSupply) revert SurpassMaxDebtSupply();

        principalOf[account_] = _balanceBefore + amount_;
        debtIndexOf[account_] = debtIndex;
        emit Transfer(address(0), account_, amount_);

        //  Add this token to the debt tokens list if the recipient is receiving it for the 1st time
        if (_balanceBefore == 0 && amount_ > 0) {
            pool.addToDebtTokensOfAccount(account_);
        }
    }

    /// @inheritdoc TokenHolder
    // solhint-disable-next-line no-empty-blocks
    function _requireCanSweep() internal view override onlyGovernor {}

    /**
     * @notice Update max total supply
     */
    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external override onlyGovernor {
        uint256 _currentMaxTotalSupply = maxTotalSupply;
        if (newMaxTotalSupply_ == _currentMaxTotalSupply) revert NewValueIsSameAsCurrent();
        emit MaxTotalSupplyUpdated(_currentMaxTotalSupply, newMaxTotalSupply_);
        maxTotalSupply = newMaxTotalSupply_;
    }

    /**
     * @notice Update interest rate (APR)
     */
    function updateInterestRate(uint256 newInterestRate_) external override onlyGovernor {
        accrueInterest();
        uint256 _currentInterestRate = interestRate;
        if (newInterestRate_ == _currentInterestRate) revert NewValueIsSameAsCurrent();
        emit InterestRateUpdated(_currentInterestRate, newInterestRate_);
        interestRate = newInterestRate_;
    }

    /**
     * @notice Enable/Disable the Debt Token
     */
    function toggleIsActive() external override onlyGovernor {
        bool _newIsActive = !isActive;
        emit DebtTokenActiveUpdated(_newIsActive);
        isActive = _newIsActive;
    }
}