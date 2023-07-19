// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./LPToken.sol";
import "../libs/MathUtils.sol";
import "../access/Ownable.sol";
import "./interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Pool is IPool, Ownable {
    using SafeERC20 for IERC20;
    using MathUtils for uint256;


    uint256 public initialA;
    uint256 public futureA;
    uint256 public initialATime;
    uint256 public futureATime;

    uint256 public swapFee;
    uint256 public adminFee;

    LPToken public lpToken;

    IERC20[] public coins;
    mapping(address => uint8) private coinIndexes;
    uint256[] tokenPrecisionMultipliers;

    uint256[] public balances;


    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );

    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    event RemoveLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );

    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );

    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    event NewSwapFee(uint256 newSwapFee);
    event NewAdminFee(uint256 newAdminFee);

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
    event StopRampA(uint256 currentA, uint256 time);


    struct CalculateWithdrawOneTokenDYInfo {
        uint256 d0;
        uint256 d1;
        uint256 newY;
        uint256 feePerToken;
        uint256 preciseA;
    }

    struct AddLiquidityInfo {
        uint256 d0;
        uint256 d1;
        uint256 d2;
        uint256 preciseA;
    }

    struct RemoveLiquidityImbalanceInfo {
        uint256 d0;
        uint256 d1;
        uint256 d2;
        uint256 preciseA;
    }

    uint256 private constant FEE_DENOMINATOR = 10**10;

    // feeAmount = amount * fee / FEE_DENOMINATOR, 1% max.
    uint256 private constant MAX_SWAP_FEE = 10**8;

    // Percentage of swap fee. E.g. 5*1e9 = 50%
    uint256 public constant MAX_ADMIN_FEE = 10**10;

    uint256 private constant MAX_LOOP_LIMIT = 256;

    uint256 public constant A_PRECISION = 100;
    uint256 public constant MAX_A = 10**6;
    uint256 private constant MAX_A_CHANGE = 10;
    uint256 private constant MIN_RAMP_TIME = 1 days;

    constructor(
        IERC20[] memory _coins,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _swapFee,
        uint256 _adminFee
    ) {
        require(_coins.length >= 2, "O3SwapPool: coins.length out of range(<2)");
        require(_coins.length <= 8, "O3SwapPool: coins.length out of range(>8");
        require(_coins.length == decimals.length, "O3SwapPool: invalid decimals length");

        uint256[] memory precisionMultipliers = new uint256[](decimals.length);

        for (uint8 i = 0; i < _coins.length; i++) {
            require(address(_coins[i]) != address(0), "O3SwapPool: token address cannot be zero");
            require(decimals[i] <= 18, "O3SwapPool: token decimal exceeds maximum");

            if (i > 0) {
                require(coinIndexes[address(_coins[i])] == 0 && _coins[0] != _coins[i], "O3SwapPool: duplicated token pooled");
            }

            precisionMultipliers[i] = 10 ** (18 - uint256(decimals[i]));
            coinIndexes[address(_coins[i])] = i;
        }

        require(_a < MAX_A, "O3SwapPool: _a exceeds maximum");
        require(_swapFee <= MAX_SWAP_FEE, "O3SwapPool: _swapFee exceeds maximum");
        require(_adminFee <= MAX_ADMIN_FEE, "O3SwapPool: _adminFee exceeds maximum");

        coins = _coins;
        lpToken = new LPToken(lpTokenName, lpTokenSymbol);
        tokenPrecisionMultipliers = precisionMultipliers;
        balances = new uint256[](_coins.length);
        initialA = _a * A_PRECISION;
        futureA = _a * A_PRECISION;
        initialATime = 0;
        futureATime = 0;
        swapFee = _swapFee;
        adminFee = _adminFee;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'O3SwapPool: EXPIRED');
        _;
    }

    function getTokenIndex(address token) external view returns (uint8) {
        uint8 index = coinIndexes[token];
        require(address(coins[index]) == token, "O3SwapPool: TOKEN_NOT_POOLED");
        return index;
    }

    function getA() external view returns (uint256) {
        return _getA();
    }

    function _getA() internal view returns (uint256) {
        return _getAPrecise() / A_PRECISION;
    }

    function _getAPrecise() internal view returns (uint256) {
        uint256 t1 = futureATime;
        uint256 a1 = futureA;

        if (block.timestamp < t1) {
            uint256 a0 = initialA;
            uint256 t0 = initialATime;
            if (a1 > a0) {
                return a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0);
            } else {
                return a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0);
            }
        } else {
            return a1;
        }
    }

    function getVirtualPrice() external view returns (uint256) {
        uint256 d = _getD(_xp(), _getAPrecise());
        uint256 totalSupply = lpToken.totalSupply();

        if (totalSupply == 0) {
            return 0;
        }

        return d * 10**18 / totalSupply;
    }

    function calculateWithdrawOneToken(uint256 tokenAmount, uint8 tokenIndex) external view returns (uint256 amount) {
        (amount, ) = _calculateWithdrawOneToken(tokenAmount, tokenIndex);
    }

    function _calculateWithdrawOneToken(uint256 tokenAmount, uint8 tokenIndex) internal view returns (uint256, uint256) {
        uint256 dy;
        uint256 newY;

        (dy, newY) = _calculateWithdrawOneTokenDY(tokenIndex, tokenAmount);
        uint256 dySwapFee = (_xp()[tokenIndex] - newY) / tokenPrecisionMultipliers[tokenIndex] - dy;

        return (dy, dySwapFee);
    }

    function _calculateWithdrawOneTokenDY(uint8 tokenIndex, uint256 tokenAmount) internal view returns (uint256, uint256) {
        require(tokenIndex < coins.length, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");

        CalculateWithdrawOneTokenDYInfo memory v = CalculateWithdrawOneTokenDYInfo(0, 0, 0, 0, 0);
        v.preciseA = _getAPrecise();
        v.feePerToken = _feePerToken();
        uint256[] memory xp = _xp();
        v.d0 = _getD(xp, v.preciseA);
        v.d1 = v.d0 - tokenAmount * v.d0 / lpToken.totalSupply();

        require(tokenAmount <= xp[tokenIndex], "O3SwapPool: WITHDRAW_AMOUNT_EXCEEDS_AVAILABLE");

        v.newY = _getYD(v.preciseA, tokenIndex, xp, v.d1);

        uint256[] memory xpReduced = new uint256[](xp.length);

        for (uint256 i = 0; i < coins.length; i++) {
            uint256 xpi = xp[i];

            xpReduced[i] = xpi - (
                ((i == tokenIndex) ? xpi * v.d1 / v.d0 - v.newY : xpi - xpi * v.d1 / v.d0)
                * v.feePerToken / FEE_DENOMINATOR
            );
        }

        uint256 dy = xpReduced[tokenIndex] - _getYD(v.preciseA, tokenIndex, xpReduced, v.d1);
        dy = (dy - 1) / tokenPrecisionMultipliers[tokenIndex];

        return (dy, v.newY);
    }

    function _getYD(uint256 a, uint8 tokenIndex, uint256[] memory xp, uint256 d) internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        require(tokenIndex < numTokens, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");

        uint256 c = d;
        uint256 s;
        uint256 nA = a * numTokens;

        for (uint256 i = 0; i < numTokens; i++) {
            if (i != tokenIndex) {
                s = s + xp[i];
                c = c * d / (xp[i] * numTokens);
            }
        }

        c = c * d * A_PRECISION / (nA * numTokens);

        uint256 b = s + d * A_PRECISION / nA;
        uint256 yPrev;
        uint256 y = d;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = (y*y + c) / (2 * y + b - d);
            if (y.within1(yPrev)) {
                return y;
            }
        }

        revert("Approximation did not converge");
    }

    function _getD(uint256[] memory xp, uint256 a) internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        uint256 s;

        for (uint256 i = 0; i < numTokens; i++) {
            s = s + xp[i];
        }

        if (s == 0) {
            return 0;
        }

        uint256 prevD;
        uint256 d = s;
        uint256 nA = a * numTokens;

        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = d;
            for (uint256 j = 0; j < numTokens; j++) {
                dP = dP * d / (xp[j] * numTokens);
            }
            prevD = d;
            d = (nA * s / A_PRECISION + dP * numTokens) * d / ((nA - A_PRECISION) * d / A_PRECISION + (numTokens + 1) * dP);
            if (d.within1(prevD)) {
                return d;
            }
        }

        revert("D did not converge");
    }

    function _getD() internal view returns (uint256) {
        return _getD(_xp(), _getAPrecise());
    }

    function _xp(uint256[] memory _balances, uint256[] memory _precisionMultipliers) internal pure returns (uint256[] memory) {
        uint256 numTokens = _balances.length;
        require(numTokens == _precisionMultipliers.length, "O3SwapPool: BALANCES_MULTIPLIERS_LENGTH_MISMATCH");

        uint256[] memory xp = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            xp[i] = _balances[i] * _precisionMultipliers[i];
        }

        return xp;
    }

    function _xp(uint256[] memory _balances) internal view returns (uint256[] memory) {
        return _xp(_balances, tokenPrecisionMultipliers);
    }

    function _xp() internal view returns (uint256[] memory) {
        return _xp(balances, tokenPrecisionMultipliers);
    }

    function _getY(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 x, uint256[] memory xp) internal view returns (uint256) {
        uint256 numTokens = coins.length;

        require(tokenIndexFrom != tokenIndexTo, "O3SwapPool: DUPLICATED_TOKEN_INDEX");
        require(tokenIndexFrom < numTokens && tokenIndexTo < numTokens, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");

        uint256 a = _getAPrecise();
        uint256 d = _getD(xp, a);
        uint256 nA = numTokens * a;
        uint256 c = d;
        uint256 s;
        uint256 _x;

        for (uint256 i = 0; i < numTokens; i++) {
            if (i == tokenIndexFrom) {
                _x = x;
            } else if (i != tokenIndexTo) {
                _x = xp[i];
            } else {
                continue;
            }
            s += _x;
            c = c * d  / (_x * numTokens);
        }

        c = c * d * A_PRECISION / (nA * numTokens);
        uint256 b = s + d * A_PRECISION / nA;
        uint256 yPrev;
        uint256 y = d;

        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = (y * y + c) / (2 * y + b - d);
            if (y.within1(yPrev)) {
                return y;
            }
        }

        revert("Approximation did not converge");
    }

    function calculateSwap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx) external view returns (uint256 dy) {
        (dy, ) = _calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
    }

    function _calculateSwap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx) internal view returns (uint256 dy, uint256 dyFee) {
        uint256[] memory xp = _xp();
        require(tokenIndexFrom < xp.length && tokenIndexTo < xp.length, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");

        uint256 x = xp[tokenIndexFrom] + dx * tokenPrecisionMultipliers[tokenIndexFrom];
        uint256 y = _getY(tokenIndexFrom, tokenIndexTo, x, xp);
        dy = xp[tokenIndexTo] - y - 1;
        dyFee = dy * swapFee / FEE_DENOMINATOR;
        dy = (dy - dyFee) / tokenPrecisionMultipliers[tokenIndexTo];
    }

    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory) {
        return _calculateRemoveLiquidity(amount);
    }

    function _calculateRemoveLiquidity(uint256 amount) internal view returns (uint256[] memory) {
        uint256 totalSupply = lpToken.totalSupply();
        require(amount <= totalSupply, "O3SwapPool: WITHDRAW_AMOUNT_EXCEEDS_AVAILABLE");

        uint256 numTokens = coins.length;
        uint256[] memory amounts = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            amounts[i] = balances[i] * amount / totalSupply;
        }

        return amounts;
    }

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256) {
        uint256 numTokens = coins.length;
        uint256 a = _getAPrecise();
        uint256[] memory _balances = balances;
        uint256 d0 = _getD(_xp(balances), a);

        for (uint256 i = 0; i < numTokens; i++) {
            if (deposit) {
                _balances[i] += amounts[i];
            } else {
                _balances[i] -= amounts[i];
            }
        }

        uint256 d1 = _getD(_xp(_balances), a);
        uint256 totalSupply = lpToken.totalSupply();

        if (deposit) {
            return (d1 - d0) * totalSupply / d0;
        } else {
            return (d0 - d1) * totalSupply / d0;
        }
    }

    function getAdminBalance(uint256 index) external view returns (uint256) {
        require(index < coins.length, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");
        return coins[index].balanceOf(address(this)) - balances[index];
    }

    function _feePerToken() internal view returns (uint256) {
        return swapFee * coins.length / (4 * (coins.length - 1));
    }

    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline) external ensure(deadline) returns (uint256) {
        require(dx <= coins[tokenIndexFrom].balanceOf(msg.sender), "O3SwapPool: INSUFFICIENT_BALANCE");

        uint256 balanceBefore = coins[tokenIndexFrom].balanceOf(address(this));
        coins[tokenIndexFrom].safeTransferFrom(msg.sender, address(this), dx);
        uint256 transferredDx = coins[tokenIndexFrom].balanceOf(address(this)) - balanceBefore;

        (uint256 dy, uint256 dyFee) = _calculateSwap(tokenIndexFrom, tokenIndexTo, transferredDx);
        require(dy >= minDy, "O3SwapPool: INSUFFICIENT_OUTPUT_AMOUNT");

        uint256 dyAdminFee = dyFee * adminFee / FEE_DENOMINATOR / tokenPrecisionMultipliers[tokenIndexTo];

        balances[tokenIndexFrom] += transferredDx;
        balances[tokenIndexTo] -= dy + dyAdminFee;

        coins[tokenIndexTo].safeTransfer(msg.sender, dy);

        emit TokenSwap(msg.sender, transferredDx, dy, tokenIndexFrom, tokenIndexTo);

        return dy;
    }

    function addLiquidity(uint256[] memory amounts, uint256 minToMint, uint256 deadline) external ensure(deadline) returns (uint256) {
        require(amounts.length == coins.length, "O3SwapPool: AMOUNTS_COINS_LENGTH_MISMATCH");

        uint256[] memory fees = new uint256[](coins.length);

        AddLiquidityInfo memory v = AddLiquidityInfo(0, 0, 0, 0);
        uint256 totalSupply = lpToken.totalSupply();

        if (totalSupply != 0) {
            v.d0 = _getD();
        }
        uint256[] memory newBalances = balances;

        for (uint256 i = 0; i < coins.length; i++) {
            // Initial deposit requires all coins
            require(totalSupply != 0 || amounts[i] > 0, "O3SwapPool: ALL_TOKENS_REQUIRED_IN_INITIAL_DEPOSIT");

            // Transfer tokens first to see if a fee was charged on transfer
            if (amounts[i] != 0) {
                uint256 beforeBalance = coins[i].balanceOf(address(this));
                coins[i].safeTransferFrom(msg.sender, address(this), amounts[i]);
                amounts[i] = coins[i].balanceOf(address(this)) - beforeBalance;
            }

            newBalances[i] = balances[i] + amounts[i];
        }

        v.preciseA = _getAPrecise();
        v.d1 = _getD(_xp(newBalances), v.preciseA);
        require(v.d1 > v.d0, "O3SwapPool: INVALID_OPERATION_D_MUST_INCREASE");

        // updated to reflect fees and calculate the user's LP tokens
        v.d2 = v.d1;
        if (totalSupply != 0) {
            uint256 feePerToken = _feePerToken();
            for (uint256 i = 0; i < coins.length; i++) {
                uint256 idealBalance = v.d1 * balances[i] / v.d0;
                fees[i] = feePerToken * idealBalance.difference(newBalances[i]) / FEE_DENOMINATOR;
                balances[i] = newBalances[i] - (fees[i] * adminFee / FEE_DENOMINATOR);
                newBalances[i] -= fees[i];
            }
            v.d2 = _getD(_xp(newBalances), v.preciseA);
        } else {
            balances = newBalances;
        }

        uint256 toMint;
        if (totalSupply == 0) {
            toMint = v.d1;
        } else {
            toMint = (v.d2 - v.d0) * totalSupply / v.d0;
        }

        require(toMint >= minToMint, "O3SwapPool: INSUFFICIENT_MINT_AMOUNT");

        lpToken.mint(msg.sender, toMint);

        emit AddLiquidity(msg.sender, amounts, fees, v.d1, totalSupply + toMint);

        return toMint;
    }

    function removeLiquidity(uint256 amount, uint256[] calldata minAmounts, uint256 deadline) external ensure(deadline) returns (uint256[] memory) {
        require(amount <= lpToken.balanceOf(msg.sender), "O3SwapPool: INSUFFICIENT_LP_AMOUNT");
        require(minAmounts.length == coins.length, "O3SwapPool: AMOUNTS_COINS_LENGTH_MISMATCH");

        uint256[] memory amounts = _calculateRemoveLiquidity(amount);

        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] >= minAmounts[i], "O3SwapPool: INSUFFICIENT_OUTPUT_AMOUNT");
            balances[i] -= amounts[i];
            coins[i].safeTransfer(msg.sender, amounts[i]);
        }

        lpToken.burnFrom(msg.sender, amount);

        emit RemoveLiquidity(msg.sender, amounts, lpToken.totalSupply());

        return amounts;
    }

    function removeLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex, uint256 minAmount, uint256 deadline) external ensure(deadline) returns (uint256) {
        uint256 numTokens = coins.length;

        require(tokenAmount <= lpToken.balanceOf(msg.sender), "O3SwapPool: INSUFFICIENT_LP_AMOUNT");
        require(tokenIndex < numTokens, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");

        uint256 dyFee;
        uint256 dy;

        (dy, dyFee) = _calculateWithdrawOneToken(tokenAmount, tokenIndex);

        require(dy >= minAmount, "O3SwapPool: INSUFFICIENT_OUTPUT_AMOUNT");

        balances[tokenIndex] -= dy + dyFee * adminFee / FEE_DENOMINATOR;
        lpToken.burnFrom(msg.sender, tokenAmount);
        coins[tokenIndex].safeTransfer(msg.sender, dy);

        emit RemoveLiquidityOne(msg.sender, tokenAmount, lpToken.totalSupply(), tokenIndex, dy);

        return dy;
    }

    function removeLiquidityImbalance(uint256[] calldata amounts, uint256 maxBurnAmount, uint256 deadline) external ensure(deadline) returns (uint256) {
        require(amounts.length == coins.length, "O3SwapPool: AMOUNTS_COINS_LENGTH_MISMATCH");
        require(maxBurnAmount <= lpToken.balanceOf(msg.sender) && maxBurnAmount != 0, "O3SwapPool: INSUFFICIENT_LP_AMOUNT");

        RemoveLiquidityImbalanceInfo memory v = RemoveLiquidityImbalanceInfo(0, 0, 0, 0);

        uint256 tokenSupply = lpToken.totalSupply();
        uint256 feePerToken = _feePerToken();
        v.preciseA = _getAPrecise();
        v.d0 = _getD(_xp(), v.preciseA);

        uint256[] memory newBalances = balances;

        for (uint256 i = 0; i < coins.length; i++) {
            newBalances[i] -= amounts[i];
        }

        v.d1 = _getD(_xp(newBalances), v.preciseA);

        uint256[] memory fees = new uint256[](coins.length);

        for (uint256 i = 0; i < coins.length; i++) {
            uint256 idealBalance = v.d1 * balances[i] / v.d0;
            uint256 difference = idealBalance.difference(newBalances[i]);
            fees[i] = feePerToken * difference / FEE_DENOMINATOR;
            balances[i] = newBalances[i] - (fees[i] * adminFee / FEE_DENOMINATOR);
            newBalances[i] -= fees[i];
        }

        v.d2 = _getD(_xp(newBalances), v.preciseA);

        uint256 tokenAmount = (v.d0 - v.d2) * tokenSupply / v.d0;
        require(tokenAmount != 0, "O3SwapPool: BURNT_LP_AMOUNT_CANNOT_BE_ZERO");
        tokenAmount += 1;

        require(tokenAmount <= maxBurnAmount, "O3SwapPool: BURNT_LP_AMOUNT_EXCEEDS_LIMITATION");

        lpToken.burnFrom(msg.sender, tokenAmount);

        for (uint256 i = 0; i < coins.length; i++) {
            coins[i].safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidityImbalance(msg.sender, amounts, fees, v.d1, tokenSupply - tokenAmount);

        return tokenAmount;
    }

    function applySwapFee(uint256 newSwapFee) external onlyOwner {
        require(newSwapFee <= MAX_SWAP_FEE, "O3SwapPool: swap fee exceeds maximum");
        swapFee = newSwapFee;

        emit NewSwapFee(newSwapFee);
    }

    function applyAdminFee(uint256 newAdminFee) external onlyOwner {
        require(newAdminFee <= MAX_ADMIN_FEE, "O3SwapPool: admin fee exceeds maximum");
        adminFee = newAdminFee;

        emit NewAdminFee(newAdminFee);
    }

    function withdrawAdminFee(address receiver) external onlyOwner {
        for (uint256 i = 0; i < coins.length; i++) {
            IERC20 token = coins[i];
            uint256 balance = token.balanceOf(address(this)) - balances[i];
            if (balance > 0) {
                token.safeTransfer(receiver, balance);
            }
        }
    }

    function rampA(uint256 _futureA, uint256 _futureTime) external onlyOwner {
        require(block.timestamp >= initialATime + MIN_RAMP_TIME, "O3SwapPool: at least 1 day before new ramp");
        require(_futureTime >= block.timestamp + MIN_RAMP_TIME, "O3SwapPool: insufficient ramp time");
        require(_futureA > 0 && _futureA < MAX_A, "O3SwapPool: futureA must in range (0, MAX_A)");

        uint256 initialAPrecise = _getAPrecise();
        uint256 futureAPrecise = _futureA * A_PRECISION;

        if (futureAPrecise < initialAPrecise) {
            require(futureAPrecise * MAX_A_CHANGE >= initialAPrecise, "O3SwapPool: futureA too small");
        } else {
            require(futureAPrecise <= initialAPrecise * MAX_A_CHANGE, "O3SwapPool: futureA too large");
        }

        initialA = initialAPrecise;
        futureA = futureAPrecise;
        initialATime = block.timestamp;
        futureATime = _futureTime;

        emit RampA(initialAPrecise, futureAPrecise, block.timestamp, _futureTime);
    }

    function stopRampA() external onlyOwner {
        require(futureATime > block.timestamp, "O3SwapPool: ramp already stopped");

        uint256 currentA = _getAPrecise();

        initialA = currentA;
        futureA = currentA;
        initialATime = block.timestamp;
        futureATime = block.timestamp;

        emit StopRampA(currentA, block.timestamp);
    }
}