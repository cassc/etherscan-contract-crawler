// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "./PoolBaseInfo.sol";
import "../libraries/Decimal.sol";
import "../interfaces/IAuction.sol";

/// @notice This contract describes basic logic of the Pool - everything related to borrowing
abstract contract PoolBase is PoolBaseInfo {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Decimal for uint256;

    // PUBLIC FUNCTIONS

    /// @notice Function is used to provide liquidity for Pool in exchange for rTokens
    /// @dev Approval for desired amount of currency token should be given in prior
    /// @param currencyAmount Amount of currency token that user want to provide
    /// @param referral Optional referral address
    function provide(uint256 currencyAmount, address referral) external {
        _provide(currencyAmount, referral, msg.sender);
    }

    /// @notice Function is used to provide liquidity for Pool in exchange for rTokens sent to a specified recipient
    /// @dev Approval for desired amount of currency token should be given in prior
    /// @param currencyAmount Amount of currency token that user want to provide
    /// @param referral Optional referral address
    /// @param recipient Address that will receive the rTokens
    function provideFor(uint256 currencyAmount, address referral, address recipient) external {
        _provide(currencyAmount, referral, recipient);
    }

    /// @notice Function is used to provide liquidity for Pool in exchange for rTokens, using EIP2612 off-chain signed permit for currency
    /// @param currencyAmount Amount of currency token that user want to provide
    /// @param referral Optional referral address
    /// @param deadline Deadline for EIP2612 approval
    /// @param v V component of permit signature
    /// @param r R component of permit signature
    /// @param s S component of permit signature
    function provideWithPermit(
        uint256 currencyAmount,
        address referral,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20PermitUpgradeable(address(currency)).permit(
            msg.sender,
            address(this),
            currencyAmount,
            deadline,
            v,
            r,
            s
        );
        _provide(currencyAmount, referral, msg.sender);
    }

    /// @notice Function is used to redeem previously provided liquidity with interest, burning rTokens
    /// @param tokens Amount of rTokens to burn (MaxUint256 to burn maximal possible)
    function redeem(uint256 tokens) external {
        _accrueInterest();

        uint256 exchangeRate = _storedExchangeRate();
        uint256 currencyAmount;
        if (tokens == type(uint256).max) {
            (tokens, currencyAmount) = _maxWithdrawable(exchangeRate);
        } else {
            currencyAmount = tokens.mulDecimal(exchangeRate);
        }
        _redeem(tokens, currencyAmount);
    }

    /// @notice Function is used to redeem previously provided liquidity with interest, burning rTokens
    /// @param currencyAmount Amount of currency to redeem (MaxUint256 to redeem maximal possible)
    function redeemCurrency(uint256 currencyAmount) external {
        _accrueInterest();

        uint256 exchangeRate = _storedExchangeRate();
        uint256 tokens;
        if (currencyAmount == type(uint256).max) {
            (tokens, currencyAmount) = _maxWithdrawable(exchangeRate);
        } else {
            tokens = currencyAmount.divDecimal(exchangeRate);
        }
        _redeem(tokens, currencyAmount);
    }

    /// @notice Function is used to borrow from the pool
    /// @param amount Amount of currency to borrow (MaxUint256 to borrow everything available)
    /// @param receiver Address where to transfer currency
    function borrow(uint256 amount, address receiver)
        external
        onlyManager
        onlyActiveAccrual
    {
        require(canManagerBorrow == true, "MCB");

        _borrow(amount, receiver);

        emit Borrowed(amount, receiver);
    }

    /// @notice Function is used to borrow from the pool on behalf of the manager
    /// @param amount Amount of currency to borrow (restricted to utilization rate remaining lower than kink)
    function borrowOnBehalf(uint256 amount)
        external
        onlyKeeper
        onlyActiveAccrual
    {
        require(
            (_info.borrows + amount).divDecimal(_poolSize(_info)) <
                interestRateModel.kink(),
            "UHO"
        );

        _borrow(amount, manager);

        emit Borrowed(amount, manager);
    }

    /// @notice Function is used to repay borrowed funds
    /// @param amount Amount to repay (MaxUint256 to repay all debt)
    /// @param closeNow True to close pool immedeately
    function repay(uint256 amount, bool closeNow)
        external
        onlyManager
        onlyActiveAccrual
    {
        if (amount == type(uint256).max) {
            amount = _info.borrows;
        } else {
            require(amount <= _info.borrows, "MTB");
        }

        _transferIn(msg.sender, amount);

        if (amount > _info.borrows - _info.principal) {
            _info.principal -= amount - (_info.borrows - _info.principal);
        }
        _info.borrows -= amount;

        _checkUtilization();

        emit Repaid(amount);

        if (closeNow) {
            require(_info.borrows == 0, "BNZ");
            _close();
        }
    }

    /// @notice Function is used to close pool
    function close() external {
        _accrueInterest();

        address governor = factory.owner();
        address debtOwner = ownerOfDebt();

        bool managerClosing = _info.borrows == 0 && msg.sender == manager;
        bool inactiveOverMax = _info.enteredZeroUtilization != 0 &&
            block.timestamp > _info.enteredZeroUtilization + maxInactivePeriod;
        bool governorClosing = msg.sender == governor &&
            (inactiveOverMax || debtOwner != address(0));
        bool ownerOfDebtClosing = msg.sender == debtOwner;

        require(managerClosing || governorClosing || ownerOfDebtClosing, "SCC");
        _close();
    }

    /// @notice Function is used to distribute insurance and close pool after period to start auction passed
    function allowWithdrawalAfterNoAuction() external {
        _accrueInterest();

        bool isDefaulting = _state(_info) == State.Default;
        bool auctionNotStarted = IAuction(factory.auction()).state(
            address(this)
        ) == IAuction.State.NotStarted;
        bool periodToStartPassed = block.timestamp >=
            _info.lastAccrual + periodToStartAuction;
        require(
            isDefaulting && auctionNotStarted && periodToStartPassed,
            "CDC"
        );
        _info.insurance = 0;
        debtClaimed = true;
        _close();
    }

    /// @notice Function is called by governor to transfer reserves to the treasury
    function transferReserves() external onlyGovernor {
        _accrueInterest();
        _transferReserves();
    }

    /// @notice Function is called by governor to force pool default (in case of default in other chain)
    function forceDefault() external onlyGovernor onlyActiveAccrual {
        _info.state = State.Default;
    }

    /// @notice Function is called by Auction contract when auction is started
    function processAuctionStart() external onlyAuction {
        _accrueInterest();
        _transferReserves();
        factory.burnStake();
    }

    /// @notice Function is called by Auction contract to process pool debt claim
    function processDebtClaim() external onlyAuction {
        _accrueInterest();
        _info.state = State.Default;

        address debtOwner = ownerOfDebt();
        if (_info.insurance > 0) {
            _transferOut(debtOwner, _info.insurance);
            _info.insurance = 0;
        }
        debtClaimed = true;
    }

    // INTERNAL FUNCTIONS

    /// @notice Function is used to borrow from the pool
    /// @param amount Amount of currency to borrow (MaxUint256 to borrow everything available)
    /// @param receiver Address where to transfer currency
    function _borrow(uint256 amount, address receiver) internal {
        if (amount == type(uint256).max) {
            amount = _availableToBorrow(_info);
        } else {
            require(amount <= _availableToBorrow(_info), "NEL");
        }
        require(amount > 0, "CBZ");

        _info.principal += amount;
        _info.borrows += amount;
        _transferOut(receiver, amount);

        _checkUtilization();
    }

    /// @notice Internal function that processes providing liquidity for Pool in exchange for rTokens
    /// @param currencyAmount Amount of currency token that user want to provide
    /// @param referral Optional referral address
    /// @param recipient Address that will receive the rTokens
    function _provide(uint256 currencyAmount, address referral, address recipient)
        internal
        onlyActiveAccrual
    {
        uint256 exchangeRate = _storedExchangeRate();
        _transferIn(msg.sender, currencyAmount);
        uint256 tokens = currencyAmount.divDecimal(exchangeRate);
        _mint(recipient, tokens);
        _checkUtilization();

        emit Provided(msg.sender, referral, currencyAmount, tokens);
    }

    /// @notice Internal function that processes token redemption
    /// @param tokensAmount Amount of tokens being redeemed
    /// @param currencyAmount Equivalent amount of currency
    function _redeem(uint256 tokensAmount, uint256 currencyAmount) internal {
        if (debtClaimed) {
            require(currencyAmount <= cash(), "NEC");
        } else {
            require(
                currencyAmount <= _availableToProviders(_info) &&
                    currencyAmount <= _availableProvisionalDefault(_info),
                "NEC"
            );
        }

        _burn(msg.sender, tokensAmount);
        _transferOut(msg.sender, currencyAmount);
        if (!debtClaimed) {
            _checkUtilization();
        }

        emit Redeemed(msg.sender, currencyAmount, tokensAmount);
    }

    /// @notice Internal function to transfer reserves to the treasury
    function _transferReserves() internal {
        _transferOut(factory.treasury(), _info.reserves);
        _info.reserves = 0;
    }

    /// @notice Internal function for closing pool
    function _close() internal {
        require(_info.state != State.Closed, "PIC");
        
        _info.state = State.Closed;
        _transferReserves();
        if (_info.insurance > 0) {
            _transferOut(factory.treasury(), _info.insurance);
            _info.insurance = 0;
        }
        factory.closePool();
        emit Closed();
    }

    /// @notice Internal function to accrue interest
    function _accrueInterest() internal {
        _info = _accrueInterestVirtual();
    }

    /// @notice Internal function that is called at each action to check for zero/warning/default utilization
    function _checkUtilization() internal {
        if (_info.borrows == 0) {
            _info.enteredProvisionalDefault = 0;
            if (_info.enteredZeroUtilization == 0) {
                _info.enteredZeroUtilization = block.timestamp;
            }
            return;
        }

        _info.enteredZeroUtilization = 0;

        if (_info.borrows >= _poolSize(_info).mulDecimal(warningUtilization)) {
            if (
                _info.enteredProvisionalDefault == 0 &&
                _info.borrows >=
                _poolSize(_info).mulDecimal(provisionalDefaultUtilization)
            ) {
                _info.enteredProvisionalDefault = block.timestamp;
            }
        } else {
            _info.enteredProvisionalDefault = 0;
        }
    }

    function _transferIn(address from, uint256 amount) internal virtual {
        currency.safeTransferFrom(from, address(this), amount);
    }

    function _transferOut(address to, uint256 amount) internal virtual {
        currency.safeTransfer(to, amount);
    }

    // PUBLIC VIEW

    /// @notice Function to get owner of the pool's debt
    /// @return Pool's debt owner
    function ownerOfDebt() public view returns (address) {
        return IAuction(factory.auction()).ownerOfDebt(address(this));
    }

    /// @notice Function returns cash amount (balance of currency in the pool)
    /// @return Cash amount
    function cash() public view virtual returns (uint256) {
        return currency.balanceOf(address(this));
    }

    // INTERNAL VIEW

    /// @notice Function to get current pool state
    /// @return Pool state as State enumerable
    function _state(BorrowInfo memory info) internal view returns (State) {
        if (info.state == State.Closed || info.state == State.Default) {
            return info.state;
        }
        if (info.enteredProvisionalDefault != 0) {
            if (
                block.timestamp >=
                info.enteredProvisionalDefault + warningGracePeriod
            ) {
                return State.Default;
            } else {
                return State.ProvisionalDefault;
            }
        }
        if (
            info.borrows > 0 &&
            info.borrows >= _poolSize(info).mulDecimal(warningUtilization)
        ) {
            return State.Warning;
        }
        return info.state;
    }

    /// @notice Function returns interest value for given borrow info
    /// @param info Borrow info struct
    /// @return Interest for given info
    function _interest(BorrowInfo memory info) internal pure returns (uint256) {
        return info.borrows - info.principal;
    }

    /// @notice Function returns amount of funds generally available for providers value for given borrow info
    /// @param info Borrow info struct
    /// @return Available to providers for given info
    function _availableToProviders(BorrowInfo memory info)
        internal
        view
        returns (uint256)
    {
        return cash() - info.reserves - info.insurance;
    }

    /// @notice Function returns available to borrow value for given borrow info
    /// @param info Borrow info struct
    /// @return Available to borrow for given info
    function _availableToBorrow(BorrowInfo memory info)
        internal
        view
        returns (uint256)
    {
        uint256 basicAvailable = _availableToProviders(info) - _interest(info);
        uint256 borrowsForWarning = _poolSize(info).mulDecimal(
            warningUtilization
        );
        if (borrowsForWarning > info.borrows) {
            return
                MathUpgradeable.min(
                    borrowsForWarning - info.borrows,
                    basicAvailable
                );
        } else {
            return 0;
        }
    }

    /// @notice Function returns pool size for given borrow info
    /// @param info Borrow info struct
    /// @return Pool size for given info
    function _poolSize(BorrowInfo memory info) internal view returns (uint256) {
        return _availableToProviders(info) + info.principal;
    }

    /// @notice Function returns funds available to be taken from pool before provisional default will be reached
    /// @param info Borrow info struct
    /// @return Pool size for given info
    function _availableProvisionalDefault(BorrowInfo memory info)
        internal
        view
        returns (uint256)
    {
        if (provisionalDefaultUtilization == 0) {
            return 0;
        }
        uint256 poolSizeForProvisionalDefault = info.borrows.divDecimal(
            provisionalDefaultUtilization
        );
        uint256 currentPoolSize = _poolSize(info);
        return
            currentPoolSize > poolSizeForProvisionalDefault
                ? currentPoolSize - poolSizeForProvisionalDefault
                : 0;
    }

    /// @notice Function returns maximal redeemable amount for given exchange rate
    /// @param exchangeRate Exchange rate of r-tokens to currency
    /// @return tokensAmount Maximal redeemable amount of tokens
    /// @return currencyAmount Maximal redeemable amount of currency
    function _maxWithdrawable(uint256 exchangeRate)
        internal
        view
        returns (uint256 tokensAmount, uint256 currencyAmount)
    {
        currencyAmount = _availableToProviders(_info);
        if (!debtClaimed) {
            uint256 availableProvisionalDefault = _availableProvisionalDefault(
                _info
            );
            if (availableProvisionalDefault < currencyAmount) {
                currencyAmount = availableProvisionalDefault;
            }
        }
        tokensAmount = currencyAmount.divDecimal(exchangeRate);

        if (balanceOf(msg.sender) < tokensAmount) {
            tokensAmount = balanceOf(msg.sender);
            currencyAmount = tokensAmount.mulDecimal(exchangeRate);
        }
    }

    /// @notice Function returns stored (without accruing) exchange rate of rTokens for currency tokens
    /// @return Stored exchange rate as 10-digits decimal
    function _storedExchangeRate() internal view returns (uint256) {
        if (totalSupply() == 0) {
            return Decimal.ONE;
        } else if (debtClaimed) {
            return cash().divDecimal(totalSupply());
        } else {
            return
                (_availableToProviders(_info) + _info.borrows).divDecimal(
                    totalSupply()
                );
        }
    }

    /// @notice Function returns timestamp when pool entered or will enter provisional default at given interest rate
    /// @param interestRate Borrows interest rate at current period
    /// @return Timestamp of entering provisional default (0 if won't ever enter)
    function _entranceOfProvisionalDefault(uint256 interestRate)
        internal
        view
        returns (uint256)
    {
        if (_info.enteredProvisionalDefault != 0) {
            return _info.enteredProvisionalDefault;
        }
        if (_info.borrows == 0 || interestRate == 0) {
            return 0;
        }

        // Consider:
        // IFPD - Interest for provisional default
        // PSPD = Pool size at provisional default
        // IRPD = Reserves & insurance at provisional default
        // IR = Current reserves and insurance
        // PDU = Provisional default utilization
        // We have: Borrows + IFPD = PDU * PSPD
        // => Borrows + IFPD = PDU * (Principal + Cash + IRPD)
        // => Borrows + IFPD = PDU * (Principal + Cash + IR + IFPD * (insuranceFactor + reserveFactor))
        // => IFPD * (1 + PDU * (reserveFactor + insuranceFactor)) = PDU * PoolSize - Borrows
        // => IFPD = (PDU * PoolSize - Borrows) / (1 + PDU * (reserveFactor + insuranceFactor))
        uint256 numerator = _poolSize(_info).mulDecimal(
            provisionalDefaultUtilization
        ) - _info.borrows;
        uint256 denominator = Decimal.ONE +
            provisionalDefaultUtilization.mulDecimal(
                reserveFactor + insuranceFactor
            );
        uint256 interestForProvisionalDefault = numerator.divDecimal(
            denominator
        );

        uint256 interestPerSec = _info.borrows * interestRate;
        // Time delta is calculated as interest for provisional default divided by interest per sec (rounded up)
        uint256 timeDelta = (interestForProvisionalDefault *
            Decimal.ONE +
            interestPerSec -
            1) / interestPerSec;
        uint256 entrance = _info.lastAccrual + timeDelta;
        return entrance <= block.timestamp ? entrance : 0;
    }

    /// @notice Function virtually accrues interest and returns updated borrow info struct
    /// @return Borrow info struct after accrual
    function _accrueInterestVirtual()
        internal
        view
        returns (BorrowInfo memory)
    {
        BorrowInfo memory newInfo = _info;

        if (
            block.timestamp == newInfo.lastAccrual ||
            newInfo.state == State.Default ||
            newInfo.state == State.Closed
        ) {
            return newInfo;
        }

        uint256 interestRate = interestRateModel.getBorrowRate(
            cash(),
            newInfo.borrows,
            newInfo.reserves + newInfo.insurance + _interest(newInfo)
        );

        newInfo.lastAccrual = block.timestamp;
        newInfo.enteredProvisionalDefault = _entranceOfProvisionalDefault(
            interestRate
        );
        if (
            newInfo.enteredProvisionalDefault != 0 &&
            newInfo.enteredProvisionalDefault + warningGracePeriod <
            newInfo.lastAccrual
        ) {
            newInfo.lastAccrual =
                newInfo.enteredProvisionalDefault +
                warningGracePeriod;
        }

        uint256 interestDelta = newInfo.borrows.mulDecimal(
            interestRate * (newInfo.lastAccrual - _info.lastAccrual)
        );
        uint256 reservesDelta = interestDelta.mulDecimal(reserveFactor);
        uint256 insuranceDelta = interestDelta.mulDecimal(insuranceFactor);
        if (
            newInfo.borrows + interestDelta + reservesDelta + insuranceDelta >
            _poolSize(newInfo)
        ) {
            interestDelta = (_poolSize(newInfo) - newInfo.borrows).divDecimal(
                Decimal.ONE + reserveFactor + insuranceFactor
            );
            uint256 interestPerSec = newInfo.borrows.mulDecimal(interestRate);
            if (interestPerSec > 0) {
                // Previous last accrual plus interest divided by interest speed (rounded up)
                newInfo.lastAccrual =
                    _info.lastAccrual +
                    (interestDelta + interestPerSec - 1) /
                    interestPerSec;
            }

            reservesDelta = interestDelta.mulDecimal(reserveFactor);
            insuranceDelta = interestDelta.mulDecimal(insuranceFactor);
            newInfo.state = State.Default;
        }

        newInfo.borrows += interestDelta;
        newInfo.reserves += reservesDelta;
        newInfo.insurance += insuranceDelta;

        return newInfo;
    }

    // MODIFIERS

    /// @notice Modifier to accrue interest and check that pool is currently active (possibly in warning)
    modifier onlyActiveAccrual() {
        _accrueInterest();
        State currentState = _state(_info);
        require(
            currentState == State.Active ||
                currentState == State.Warning ||
                currentState == State.ProvisionalDefault,
            "PIA"
        );
        _;
    }

    /// @notice Modifier for functions restricted to manager
    modifier onlyManager() {
        require(msg.sender == manager, "OM");
        _;
    }

    /// @notice Modifier for functions restricted to protocol governor
    modifier onlyGovernor() {
        require(msg.sender == factory.owner(), "OG");
        _;
    }

    /// @notice Modifier for functions restricted to keeper
    modifier onlyKeeper() {
        require(msg.sender == factory.keeper(), "OK");
        _;
    }

    /// @notice Modifier for functions restricted to auction contract
    modifier onlyAuction() {
        require(msg.sender == factory.auction(), "OA");
        _;
    }

    /// @notice Modifier for the functions restricted to factory
    modifier onlyFactory() {
        require(msg.sender == address(factory), "OF");
        _;
    }
}