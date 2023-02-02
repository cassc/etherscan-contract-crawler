pragma solidity =0.5.16;

import "./PoolToken.sol";
import "./BAllowance.sol";
import "./BInterestRateModel.sol";
import "./BSetter.sol";
import "./BStorage.sol";
import "./interfaces/IBorrowable.sol";
import "./interfaces/ICollateral.sol";
import "./interfaces/ITarotCallee.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IBorrowTracker.sol";
import "./libraries/Math.sol";

contract Borrowable is
    IBorrowable,
    PoolToken,
    BStorage,
    BSetter,
    BInterestRateModel,
    BAllowance
{
    uint256 public constant BORROW_FEE = 0.0001e18; //0.01%

    event Borrow(
        address indexed sender,
        address indexed borrower,
        address indexed receiver,
        uint256 borrowAmount,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrows
    );
    event Liquidate(
        address indexed sender,
        address indexed borrower,
        address indexed liquidator,
        uint256 seizeTokens,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    constructor() public {}

    /*** PoolToken ***/

    function _update() internal {
        super._update();
        _calculateBorrowRate();
    }

    function _mintReserves(uint256 _exchangeRate, uint256 _totalSupply)
        internal
        returns (uint256)
    {
        uint256 _exchangeRateLast = exchangeRateLast;
        if (_exchangeRate > _exchangeRateLast) {
            uint256 _exchangeRateNew =
                _exchangeRate.sub(
                    _exchangeRate.sub(_exchangeRateLast).mul(reserveFactor).div(
                        1e18
                    )
                );
            uint256 liquidity =
                _totalSupply.mul(_exchangeRate).div(_exchangeRateNew).sub(
                    _totalSupply
                );
            if (liquidity > 0) {
                address reservesManager = IFactory(factory).reservesManager();
                _mint(reservesManager, liquidity);
            }
            exchangeRateLast = _exchangeRateNew;
            return _exchangeRateNew;
        } else return _exchangeRate;
    }

    function exchangeRate() public accrue returns (uint256) {
        uint256 _totalSupply = totalSupply;
        uint256 _actualBalance = totalBalance.add(totalBorrows);
        if (_totalSupply == 0 || _actualBalance == 0)
            return initialExchangeRate;
        uint256 _exchangeRate = _actualBalance.mul(1e18).div(_totalSupply);
        return _mintReserves(_exchangeRate, _totalSupply);
    }

    // force totalBalance to match real balance
    function sync() external nonReentrant update accrue {}

    /*** Borrowable ***/

    // this is the stored borrow balance; the current borrow balance may be slightly higher
    function borrowBalance(address borrower) public view returns (uint256) {
        BorrowSnapshot memory borrowSnapshot = borrowBalances[borrower];
        if (borrowSnapshot.interestIndex == 0) return 0; // not initialized
        return
            uint256(borrowSnapshot.principal).mul(borrowIndex).div(
                borrowSnapshot.interestIndex
            );
    }

    function _trackBorrow(
        address borrower,
        uint256 accountBorrows,
        uint256 _borrowIndex
    ) internal {
        address _borrowTracker = borrowTracker;
        if (_borrowTracker == address(0)) return;
        IBorrowTracker(_borrowTracker).trackBorrow(
            borrower,
            accountBorrows,
            _borrowIndex
        );
    }

    function _updateBorrow(
        address borrower,
        uint256 borrowAmount,
        uint256 repayAmount
    )
        private
        returns (
            uint256 accountBorrowsPrior,
            uint256 accountBorrows,
            uint256 _totalBorrows
        )
    {
        accountBorrowsPrior = borrowBalance(borrower);
        if (borrowAmount == repayAmount)
            return (accountBorrowsPrior, accountBorrowsPrior, totalBorrows);
        uint112 _borrowIndex = borrowIndex;
        if (borrowAmount > repayAmount) {
            BorrowSnapshot storage borrowSnapshot = borrowBalances[borrower];
            uint256 increaseAmount = borrowAmount - repayAmount;
            accountBorrows = accountBorrowsPrior.add(increaseAmount);
            borrowSnapshot.principal = safe112(accountBorrows);
            borrowSnapshot.interestIndex = _borrowIndex;
            _totalBorrows = uint256(totalBorrows).add(increaseAmount);
            totalBorrows = safe112(_totalBorrows);
        } else {
            BorrowSnapshot storage borrowSnapshot = borrowBalances[borrower];
            uint256 decreaseAmount = repayAmount - borrowAmount;
            accountBorrows = accountBorrowsPrior > decreaseAmount
                ? accountBorrowsPrior - decreaseAmount
                : 0;
            borrowSnapshot.principal = safe112(accountBorrows);
            if (accountBorrows == 0) {
                borrowSnapshot.interestIndex = 0;
            } else {
                borrowSnapshot.interestIndex = _borrowIndex;
            }
            uint256 actualDecreaseAmount =
                accountBorrowsPrior.sub(accountBorrows);
            _totalBorrows = totalBorrows; // gas savings
            _totalBorrows = _totalBorrows > actualDecreaseAmount
                ? _totalBorrows - actualDecreaseAmount
                : 0;
            totalBorrows = safe112(_totalBorrows);
        }
        _trackBorrow(borrower, accountBorrows, _borrowIndex);
    }

    // this low-level function should be called from another contract
    function borrow(
        address borrower,
        address receiver,
        uint256 borrowAmount,
        bytes calldata data
    ) external nonReentrant update accrue {
        uint256 _totalBalance = totalBalance;
        require(borrowAmount <= _totalBalance, "Tarot: INSUFFICIENT_CASH");
        _checkBorrowAllowance(borrower, msg.sender, borrowAmount);

        // optimistically transfer funds
        if (borrowAmount > 0) _safeTransfer(receiver, borrowAmount);
        if (data.length > 0)
            ITarotCallee(receiver).tarotBorrow(
                msg.sender,
                borrower,
                borrowAmount,
                data
            );
        uint256 balance = IERC20(underlying).balanceOf(address(this));

        uint256 borrowFee = borrowAmount.mul(BORROW_FEE).div(1e18);
        uint256 adjustedBorrowAmount = borrowAmount.add(borrowFee);
        uint256 repayAmount = balance.add(borrowAmount).sub(_totalBalance);
        (
            uint256 accountBorrowsPrior,
            uint256 accountBorrows,
            uint256 _totalBorrows
        ) = _updateBorrow(borrower, adjustedBorrowAmount, repayAmount);

        if (adjustedBorrowAmount > repayAmount)
            require(
                ICollateral(collateral).canBorrow(
                    borrower,
                    address(this),
                    accountBorrows
                ),
                "Tarot: INSUFFICIENT_LIQUIDITY"
            );

        emit Borrow(
            msg.sender,
            borrower,
            receiver,
            borrowAmount,
            repayAmount,
            accountBorrowsPrior,
            accountBorrows,
            _totalBorrows
        );
    }

    // this low-level function should be called from another contract
    function liquidate(address borrower, address liquidator)
        external
        nonReentrant
        update
        accrue
        returns (uint256 seizeTokens)
    {
        uint256 balance = IERC20(underlying).balanceOf(address(this));
        uint256 repayAmount = balance.sub(totalBalance);

        uint256 actualRepayAmount =
            Math.min(borrowBalance(borrower), repayAmount);
        seizeTokens = ICollateral(collateral).seize(
            liquidator,
            borrower,
            actualRepayAmount
        );
        (
            uint256 accountBorrowsPrior,
            uint256 accountBorrows,
            uint256 _totalBorrows
        ) = _updateBorrow(borrower, 0, repayAmount);

        emit Liquidate(
            msg.sender,
            borrower,
            liquidator,
            seizeTokens,
            repayAmount,
            accountBorrowsPrior,
            accountBorrows,
            _totalBorrows
        );
    }

    function trackBorrow(address borrower) external {
        _trackBorrow(borrower, borrowBalance(borrower), borrowIndex);
    }

    modifier accrue() {
        accrueInterest();
        _;
    }
}