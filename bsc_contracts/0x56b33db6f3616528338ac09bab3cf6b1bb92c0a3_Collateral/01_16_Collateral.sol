pragma solidity =0.5.16;

import "./PoolToken.sol";
import "./CStorage.sol";
import "./CSetter.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IBorrowable.sol";
import "./interfaces/ICollateral.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ITarotSolidlyPriceOracleV2.sol";
import "./interfaces/ITarotCallee.sol";
import "./interfaces/IBaseV1Pair.sol";
import "./interfaces/IVaultToken.sol";
import "./libraries/Math.sol";

contract Collateral is ICollateral, PoolToken, CStorage, CSetter {
    constructor() public {}

    /*** Collateralization Model ***/

    function getPrices() public returns (uint256 price0, uint256 price1) {
        (uint256 reserve0, uint256 reserve1) = getReserves();
        uint256 t = IBaseV1Pair(underlying).totalSupply();
        (uint256 decimals0, uint256 decimals1, , , , , ) = IBaseV1Pair(underlying).metadata();
        
        reserve0 = reserve0.mul(1e18).div(decimals0);
        reserve1 = reserve1.mul(1e18).div(decimals1);
        uint256 f;
        {
            uint256 a = reserve0.mul(reserve0).div(1e18);
            uint256 b = reserve1.mul(reserve1).div(1e18);
            f = a.mul(3).add(b).mul(1e18).div(b.mul(3).add(a));
        }
        price0 = t.mul(f).div(f.add(1e18)).mul(1e18).div(reserve0).mul(1e18).div(decimals0);
        price1 = t.mul(1e18).div(f.add(1e18)).mul(1e18).div(reserve1).mul(1e18).div(decimals1);
    }

    function _k(uint256 x, uint256 y, uint256 d0, uint256 d1) internal pure returns (uint256) {
        uint _x = x.mul(1e18).div(d0);
        uint _y = y.mul(1e18).div(d1);
        uint _a = _x.mul(_y).div(1e18);
        uint _b = _x.mul(_x).div(1e18).add(_y.mul(_y).div(1e18));
        return _a.mul(_b).div(1e18);  // x3y+y3x >= k
    }

    function getReserves() public returns (uint112 reserve0, uint112 reserve1) {
        (uint256 _twapReserve0, uint256 _twapReserve1, ) =
            ITarotSolidlyPriceOracleV2(tarotPriceOracle).getResult(underlying);
        if (isUnderlyingVaultToken()) {
            uint256 scale = IVaultToken(underlying).getScale();
            _twapReserve0 = _twapReserve0.mul(scale).div(1e18);
            _twapReserve1 = _twapReserve1.mul(scale).div(1e18);
        }

        (uint256 decimals0, uint256 decimals1, , , , , ) = IBaseV1Pair(underlying).metadata();
        (uint256 _currReserve0, uint256 _currReserve1, ) = IBaseV1Pair(underlying).getReserves();
        
        uint256 twapK = _k(_twapReserve0, _twapReserve1, decimals0, decimals1);
        uint256 currK = _k(_currReserve0, _currReserve1, decimals0, decimals1);

        uint256 _adjustment = Math.sqrt(Math.sqrt(currK.mul(1e18).div(twapK).mul(1e18)).mul(1e18));
        reserve0 = safe112(_twapReserve0.mul(_adjustment).div(1e18));
        reserve1 = safe112(_twapReserve1.mul(_adjustment).div(1e18));

        require(reserve0 > 100 && reserve1 > 100, "Tarot: INSUFFICIENT_RESERVES");
    }

    function _fm(uint256 p1, uint256 m) internal pure returns (bool) {
        uint256 a = m.mul(m).div(1e18).mul(m).div(1e18).add(m.mul(3));
        uint256 b = p1.mul(3).mul(m).div(1e18).mul(m).div(1e18);
        return a > b && a.sub(b) > p1;
    }

    function _get_m(uint256 p1, uint256 a, uint256 b, uint256 _mTolerance) internal pure returns (uint256 m) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 mid = b.sub(a).div(2);
            m = a.add(mid);
            if (mid <= _mTolerance) {
                return m;
            }
            if (_fm(p1, m)) {
                b = m;
            } else {
                a = m;
            }
        }
    }

    function _reserveRatioSwingGivenPriceSwing(ReserveInfo memory reserveInfo, uint256 _priceSwing, uint256 _mTolerance) internal pure returns (uint256 reserveRatioSwing) {
        if (_priceSwing == 1e18) {
            return 1e18;
        }

        uint256 x = reserveInfo.x;
        uint256 y = reserveInfo.y;

        uint256 a = x.mul(x).div(1e18);
        uint256 b = y.mul(y).div(1e18);
        uint256 c = a.mul(3).add(b);
        uint256 d = b.mul(3).add(a);
        uint256 p1 = y.mul(c).div(x);
        p1 = p1.mul(1e18).div(d);
        p1 = p1.mul(_priceSwing).div(1e18);

        (uint256 lower, uint256 upper) = p1 > 1e18 ? (uint256(1e18), p1.mul(3)) : (p1.div(3), uint256(1e18));
        reserveRatioSwing = _get_m(p1, lower, upper, _mTolerance);
        reserveRatioSwing = reserveRatioSwing.mul(x).div(y);
    }

    function _safetyMarginReserveRatioSwings(ReserveInfo memory reserveInfo, uint256 _safetyMargin, uint256 _mTolerance) internal pure returns (uint256 ratioSwingA, uint256 ratioSwingB) {
        ratioSwingA = _reserveRatioSwingGivenPriceSwing(reserveInfo, _safetyMargin, _mTolerance);
        ratioSwingB = _reserveRatioSwingGivenPriceSwing(reserveInfo, uint256(1e36).div(_safetyMargin), _mTolerance);
    }

    function _reserveDeltas(ReserveInfo memory reserveInfo, uint256 m) internal pure returns (uint256 deltaX, uint256 deltaY, uint256 priceFactor) {
        uint256 x = reserveInfo.x;
        uint256 y = reserveInfo.y;
        uint256 a = x.mul(x).div(1e18);
        uint256 b = y.mul(y).div(1e18);
        uint256 c = b.mul(m).div(1e18).mul(m).div(1e18);
        uint256 d = m.mul(a.add(c)).div(1e18);
        deltaX = Math.sqrt(Math.sqrt(a.add(b).mul(1e18).div(d).mul(1e18)).mul(1e18));
        deltaY = deltaX.mul(m).div(1e18);
        priceFactor = a.mul(3).add(c).mul(1e18).div(c.mul(3).add(a));
    }

    struct ReserveInfo {
        uint256 x;
        uint256 y;
    }

    // returns liquidity in  collateral's underlying
    function _calculateLiquidity(
        uint256 _amountCollateral,
        uint256 _amount0,
        uint256 _amount1
    ) internal returns (uint256 liquidity, uint256 shortfall) {
        ReserveInfo memory reserveInfo;
        (uint256 reserve0, uint256 reserve1) = getReserves();
        {
            (uint256 decimals0, uint256 decimals1, , , , , ) = IBaseV1Pair(underlying).metadata();
            reserveInfo.x = reserve0.mul(1e18).div(decimals0);
            reserveInfo.y = reserve1.mul(1e18).div(decimals1);
        }
        (uint256 ratioSwingA, uint256 ratioSwingB) = _safetyMarginReserveRatioSwings(reserveInfo, safetyMargin, mTolerance);
        uint256 totalUnderlying = IBaseV1Pair(underlying).totalSupply();
        uint256 collateralNeededA;
        uint256 amount0 = _amount0;
        uint256 amount1 = _amount1;
        uint256 amountCollateral = _amountCollateral;
        {
            (uint256 dx1, uint256 dy1, uint256 a1) = _reserveDeltas(reserveInfo, ratioSwingA);
            uint256 price0 = totalUnderlying.mul(1e18).div(reserve0);
            price0 = price0.mul(1e18).div(dx1);
            price0 = price0.mul(a1).div(a1.add(1e18));
            uint256 price1 = totalUnderlying.mul(1e18).div(reserve1);
            price1 = price1.mul(1e18).div(dy1);
            price1 = price1.mul(1e18).div(a1.add(1e18));
            collateralNeededA = amount0.mul(price0).div(1e18);
            collateralNeededA = collateralNeededA.add(amount1.mul(price1).div(1e18));
            collateralNeededA = collateralNeededA.mul(liquidationPenalty()).div(1e18);
        }
        uint256 collateralNeededB;
        {
            (uint256 dx2, uint256 dy2, uint256 a2) = _reserveDeltas(reserveInfo, ratioSwingB);
            uint256 price0 = totalUnderlying.mul(1e18).div(reserve0);
            price0 = price0.mul(1e18).div(dx2);
            price0 = price0.mul(a2).div(a2.add(1e18));
            uint256 price1 = totalUnderlying.mul(1e18).div(reserve1);
            price1 = price1.mul(1e18).div(dy2);
            price1 = price1.mul(1e18).div(a2.add(1e18));
            collateralNeededB = amount0.mul(price0).div(1e18);
            collateralNeededB = collateralNeededB.add(amount1.mul(price1).div(1e18));
            collateralNeededB = collateralNeededB.mul(liquidationPenalty()).div(1e18);
        }        
        uint256 collateralNeeded = (collateralNeededA > collateralNeededB) ? collateralNeededA : collateralNeededB;
        if (amountCollateral >= collateralNeeded) {
            return (amountCollateral - collateralNeeded, 0);
        } else {
            return (0, collateralNeeded - amountCollateral);
        }
    }

    /*** ERC20 ***/

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(tokensUnlocked(from, value), "Tarot: INSUFFICIENT_LIQUIDITY");
        super._transfer(from, to, value);
    }

    function tokensUnlocked(address from, uint256 value) public returns (bool) {
        uint256 _balance = balanceOf[from];
        if (value > _balance) return false;
        uint256 finalBalance = _balance - value;
        uint256 amountCollateral = finalBalance.mul(exchangeRate()).div(1e18);
        uint256 amount0 = IBorrowable(borrowable0).borrowBalance(from);
        uint256 amount1 = IBorrowable(borrowable1).borrowBalance(from);
        (, uint256 shortfall) =
            _calculateLiquidity(amountCollateral, amount0, amount1);
        return shortfall == 0;
    }

    /*** Collateral ***/

    function accountLiquidityAmounts(
        address borrower,
        uint256 amount0,
        uint256 amount1
    ) public returns (uint256 liquidity, uint256 shortfall) {
        if (amount0 == uint256(-1))
            amount0 = IBorrowable(borrowable0).borrowBalance(borrower);
        if (amount1 == uint256(-1))
            amount1 = IBorrowable(borrowable1).borrowBalance(borrower);
        uint256 amountCollateral =
            balanceOf[borrower].mul(exchangeRate()).div(1e18);
        return _calculateLiquidity(amountCollateral, amount0, amount1);
    }

    function accountLiquidity(address borrower)
        public
        returns (uint256 liquidity, uint256 shortfall)
    {
        return accountLiquidityAmounts(borrower, uint256(-1), uint256(-1));
    }

    function canBorrow(
        address borrower,
        address borrowable,
        uint256 accountBorrows
    ) public returns (bool) {
        address _borrowable0 = borrowable0;
        address _borrowable1 = borrowable1;
        require(
            borrowable == _borrowable0 || borrowable == _borrowable1,
            "Tarot: INVALID_BORROWABLE"
        );
        uint256 amount0 =
            borrowable == _borrowable0 ? accountBorrows : uint256(-1);
        uint256 amount1 =
            borrowable == _borrowable1 ? accountBorrows : uint256(-1);
        (, uint256 shortfall) =
            accountLiquidityAmounts(borrower, amount0, amount1);
        return shortfall == 0;
    }

    // this function must be called from borrowable0 or borrowable1
    function seize(
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256 seizeTokens) {
        require(
            msg.sender == borrowable0 || msg.sender == borrowable1,
            "Tarot: UNAUTHORIZED"
        );

        (, uint256 shortfall) = accountLiquidity(borrower);
        require(shortfall > 0, "Tarot: INSUFFICIENT_SHORTFALL");

        uint256 price;
        if (msg.sender == borrowable0) (price, ) = getPrices();
        else (, price) = getPrices();

        uint256 collateralEquivalent = repayAmount.mul(price).div(exchangeRate());

        seizeTokens = collateralEquivalent
            .mul(liquidationIncentive)
            .div(1e18);

        balanceOf[borrower] = balanceOf[borrower].sub(
            seizeTokens,
            "Tarot: LIQUIDATING_TOO_MUCH"
        );
        balanceOf[liquidator] = balanceOf[liquidator].add(seizeTokens);
        emit Transfer(borrower, liquidator, seizeTokens);

        if (liquidationFee > 0) {
            uint256 seizeFee = collateralEquivalent.mul(liquidationFee).div(1e18);
            address reservesManager = IFactory(factory).reservesManager();
            balanceOf[borrower] = balanceOf[borrower].sub(seizeFee, "Tarot: LIQUIDATING_TOO_MUCH");
            balanceOf[reservesManager] = balanceOf[reservesManager].add(seizeFee);
            emit Transfer(borrower, reservesManager, seizeFee);
        }
    }

    // this low-level function should be called from another contract
    function flashRedeem(
        address redeemer,
        uint256 redeemAmount,
        bytes calldata data
    ) external nonReentrant update {
        require(redeemAmount <= totalBalance, "Tarot: INSUFFICIENT_CASH");

        // optimistically transfer funds
        _safeTransfer(redeemer, redeemAmount);
        if (data.length > 0)
            ITarotCallee(redeemer).tarotRedeem(msg.sender, redeemAmount, data);

        uint256 redeemTokens = balanceOf[address(this)];
        uint256 declaredRedeemTokens =
            redeemAmount.mul(1e18).div(exchangeRate()).add(1); // rounded up
        require(
            redeemTokens >= declaredRedeemTokens,
            "Tarot: INSUFFICIENT_REDEEM_TOKENS"
        );

        _burn(address(this), redeemTokens);
        emit Redeem(msg.sender, redeemer, redeemAmount, redeemTokens);
    }

    function isUnderlyingVaultToken()
        public
        view
        returns (bool)
    {
        (bool success, bytes memory returnData) = address(underlying).staticcall(
            abi.encodeWithSelector(IVaultToken(underlying).isVaultToken.selector)
        );
        if (success) {
            return abi.decode(returnData, (bool));
        } else {
            return false;
        }
    }

    function safe112(uint256 n) internal pure returns (uint112) {
        require(n < 2**112, "Tarot: SAFE112");
        return uint112(n);
    }
}