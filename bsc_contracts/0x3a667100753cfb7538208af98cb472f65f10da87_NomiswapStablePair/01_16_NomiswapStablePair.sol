// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.15;

import "./interfaces/INomiswapStablePair.sol";
import "./interfaces/INomiswapCallee.sol";
import "./interfaces/INomiswapFactory.sol";
import "./NomiswapStableERC20.sol";
import "./libraries/MathUtils.sol";
import "./libraries/UQ112x112.sol";
import "./util/FactoryGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NomiswapStablePair is INomiswapStablePair, NomiswapStableERC20, ReentrancyGuard, FactoryGuard {
    using MathUtils for uint256;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    uint256 internal constant MAX_FEE = 100000; // @dev 100%.
    uint256 internal constant A_PRECISION = 100;

    uint256 internal constant MAX_A = 10 ** 6;
    uint256 internal constant MAX_A_CHANGE = 100;
    uint256 internal constant MIN_RAMP_TIME = 86400;

    uint256 private constant Q112 = 2**112;
    uint256 private constant MAX_LOOP_LIMIT = 256;

    address public immutable token0;
    address public immutable token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint128 public adminFee = 1;
    uint128 public devFee = uint128(Q112*(10-7)/uint(7)); // 70% (1/0.7-1)

    uint128 public immutable token0PrecisionMultiplier; // uses single storage slot
    uint128 public immutable token1PrecisionMultiplier; // uses single storage slot

    uint32 initialA = uint32(85 * A_PRECISION); // uses single storage slot
    uint32 futureA = uint32(85 * A_PRECISION); // uses single storage slot
    uint40 initialATime; // uses single storage slot
    uint40 futureATime; // uses single storage slot
    uint32 public swapFee = 100; // uses 0.1% default

    constructor(address _token0, address _token1) FactoryGuard(msg.sender) {
        futureATime = uint40(block.timestamp);
        token0 = _token0;
        token1 = _token1;
        uint8 decimals0 = IERC20Metadata(_token0).decimals();
        require(decimals0 <= 18, 'NomiswapStablePair: unsupported token');
        token0PrecisionMultiplier = uint128(10)**(18 - decimals0);
        uint8 decimals1 = IERC20Metadata(_token1).decimals();
        require(decimals1 <= 18, 'NomiswapStablePair: unsupported token');
        token1PrecisionMultiplier = uint128(10)**(18 - decimals1);
    }

    function symbol() external view returns (string memory) {
        return string.concat(
            symbolPrefix,
            "-",
            IERC20Metadata(token0).symbol(),
            "-",
            IERC20Metadata(token1).symbol()
        );
    }

    function setSwapFee(uint32 _swapFee) override external onlyFactory {
        require(_swapFee <= MAX_FEE, 'NomiswapStablePair: FORBIDDEN_FEE');
        swapFee = _swapFee;
    }

    function setDevFee(uint128 _devFee) override external onlyFactory {
        require(_devFee != 0, "NomiswapStablePair: dev fee 0");
        devFee = _devFee;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) override external nonReentrant returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));

        _mintFee();
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        if (_totalSupply == 0) {
            uint A = getA();
            uint dBalance = _computeLiquidity(balance0, balance1, A);
            liquidity = dBalance - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = MathUtils.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }

        require(liquidity > 0, 'Nomiswap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) override external nonReentrant returns (uint amount0, uint amount1) {
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        _mintFee();
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Nomiswap: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        SafeERC20.safeTransfer(IERC20(_token0), to, amount0);
        SafeERC20.safeTransfer(IERC20(_token1), to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) override external nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, 'Nomiswap: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint _reserve0, uint _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Nomiswap: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'Nomiswap: INVALID_TO');
            if (amount0Out > 0) SafeERC20.safeTransfer(IERC20(_token0), to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) SafeERC20.safeTransfer(IERC20(_token1), to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) INomiswapCallee(to).nomiswapCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Nomiswap: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors

            uint256 A = getA();
            uint _swapFee = swapFee;
            uint _token0PrecisionMultiplier = token0PrecisionMultiplier;
            uint _token1PrecisionMultiplier = token1PrecisionMultiplier;
            uint balance0Adjusted = (balance0 * MAX_FEE - amount0In * _swapFee) * _token0PrecisionMultiplier / MAX_FEE;
            uint balance1Adjusted = (balance1 * MAX_FEE - amount1In * _swapFee) * _token1PrecisionMultiplier / MAX_FEE;
            uint256 dBalance = _computeLiquidityFromAdjustedBalances(balance0Adjusted, balance1Adjusted, A);

            uint256 adjustedReserve0 = _reserve0 * _token0PrecisionMultiplier;
            uint256 adjustedReserve1 = _reserve1 * _token1PrecisionMultiplier;
            uint256 dReserves = _computeLiquidityFromAdjustedBalances(adjustedReserve0, adjustedReserve1, A);

            require(dBalance >= dReserves, 'Nomiswap: D');

            uint256 dTotal = _computeLiquidity(balance0, balance1, A);
            uint numerator = totalSupply * (dTotal - dReserves);
            uint denominator = (dTotal * devFee/Q112) + dReserves;
            adminFee += uint128(numerator / denominator);
        }

        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) override external nonReentrant {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        SafeERC20.safeTransfer(IERC20(_token0), to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        SafeERC20.safeTransfer(IERC20(_token1), to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    // force reserves to match balances
    function sync() override external nonReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }

    function rampA(uint32 _futureA, uint40 _futureTime) override external nonReentrant onlyFactory {
        require(block.timestamp >= initialATime + MIN_RAMP_TIME, 'NomiswapStablePair: INVALID_TIME');
        require(_futureTime >= block.timestamp + MIN_RAMP_TIME, 'NomiswapStablePair: INVALID_FUTURE_TIME');

        uint32 _initialA = uint32(getA());
        uint32 _futureAP = uint32(_futureA * A_PRECISION);

        require(_futureA > 0 && _futureA < MAX_A);

        if (_futureAP < _initialA) {
            require(_futureAP * MAX_A_CHANGE >= _initialA);
        } else {
            require(_futureAP <= _initialA * MAX_A_CHANGE);
        }

        initialA = _initialA;
        futureA = _futureAP;
        initialATime = uint40(block.timestamp);
        futureATime = _futureTime;

        emit RampA(_initialA, _futureAP, block.timestamp, _futureTime);
    }

    function stopRampA() override external nonReentrant onlyFactory {
        uint32 currentA = uint32(getA());

        initialA = currentA;
        futureA = currentA;
        initialATime = uint40(block.timestamp);
        futureATime = uint40(block.timestamp);

        emit StopRampA(currentA, block.timestamp);
    }

    function getAmountIn(address tokenIn, uint256 amountOut) external view override returns (uint256 finalAmountIn) {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves();

        unchecked {
            uint256 _token0PrecisionMultiplier = token0PrecisionMultiplier;
            uint256 _token1PrecisionMultiplier = token1PrecisionMultiplier;
            uint256 adjustedReserve0 = _reserve0 * _token0PrecisionMultiplier;
            uint256 adjustedReserve1 = _reserve1 * _token1PrecisionMultiplier;
            uint256 A = getA();
            uint256 d = _computeLiquidityFromAdjustedBalances(adjustedReserve0, adjustedReserve1, A);

            if (tokenIn == token0) {
                uint256 x = adjustedReserve1 - amountOut * _token1PrecisionMultiplier;
                uint256 y = _getY(x, d, A);
                uint256 dy = (y - adjustedReserve0).divRoundUp(_token0PrecisionMultiplier);
                finalAmountIn = (dy * MAX_FEE).divRoundUp(MAX_FEE - swapFee);
            } else {
                require(tokenIn == token1, "INVALID_INPUT_TOKEN");
                uint256 x = adjustedReserve0 - amountOut * _token0PrecisionMultiplier;
                uint256 y = _getY(x, d, A);
                uint256 dy = (y - adjustedReserve1).divRoundUp(_token1PrecisionMultiplier);
                finalAmountIn = (dy * MAX_FEE).divRoundUp(MAX_FEE - swapFee);
            }
        }
    }

    function getAmountOut(address tokenIn, uint256 amountIn) external view override returns (uint256 finalAmountOut) {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves();

        unchecked {
            uint256 _token0PrecisionMultiplier = token0PrecisionMultiplier;
            uint256 _token1PrecisionMultiplier = token1PrecisionMultiplier;
            uint256 feeDeductedAmountIn = (amountIn * MAX_FEE - amountIn * swapFee) / MAX_FEE;
            uint256 adjustedReserve0 = _reserve0 * _token0PrecisionMultiplier;
            uint256 adjustedReserve1 = _reserve1 * _token1PrecisionMultiplier;
            uint256 A = getA();
            uint256 d = _computeLiquidityFromAdjustedBalances(adjustedReserve0, adjustedReserve1, A);

            if (tokenIn == token0) {
                uint256 x = adjustedReserve0 + feeDeductedAmountIn * _token0PrecisionMultiplier;
                uint256 y = _getY(x, d, A);
                finalAmountOut = (adjustedReserve1 - y) / _token1PrecisionMultiplier;
            } else {
                require(tokenIn == token1, "INVALID_INPUT_TOKEN");
                uint256 x = adjustedReserve1 + feeDeductedAmountIn * _token1PrecisionMultiplier;
                uint256 y = _getY(x, d, A);
                finalAmountOut = (adjustedReserve0 - y) / _token0PrecisionMultiplier;
            }
        }
    }

    function getReserves() override public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function factory() override public view returns (address) {
        return _factory;
    }

    function getA() override public view returns (uint256) {
        uint256 t1  = futureATime;
        uint256 A1  = futureA;

        if (block.timestamp < t1) {
            uint256 A0 = initialA;
            uint256 t0 = initialATime;
            // Expressions in uint32 cannot have negative numbers, thus "if"
            if (A1 > A0) {
                return A0 + (block.timestamp - t0) * (A1 - A0) / (t1 - t0);
            } else {
                return A0 - (block.timestamp - t0) * (A0 - A1) / (t1 - t0);
            }
        } else {
            // when t1 == 0 or block.timestamp >= t1
            return A1;
        }
    }

    function _computeLiquidity(uint256 _reserve0, uint256 _reserve1, uint256 A) private view returns (uint256 liquidity) {
        unchecked {
            uint256 adjustedReserve0 = _reserve0 * token0PrecisionMultiplier;
            uint256 adjustedReserve1 = _reserve1 * token1PrecisionMultiplier;
            liquidity = _computeLiquidityFromAdjustedBalances(adjustedReserve0, adjustedReserve1, A);
        }
    }

    function _update(uint balance0, uint balance1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'Nomiswap: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee() private {
        address feeTo = INomiswapFactory(factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint _adminFee = adminFee; // gas savings
        if (feeOn) {
            if (_adminFee > 1) {
                _mint(feeTo, _adminFee - 1);
                adminFee = 1;
            }
        } else if (_adminFee > 1) {
            adminFee = 1;
        }
    }

    function _computeLiquidityFromAdjustedBalances(uint256 xp0, uint256 xp1, uint256 A) private pure returns (uint256 computed) {
        uint256 s = xp0 + xp1;

        uint256 N_A = A * 4;
        if (s == 0) {
            return 0;
        }
        uint256 prevD;
        uint256 D = s;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = (((D * D) / xp0) * D) / xp1 / 4;
            prevD = D;
            D = (((N_A * s) / A_PRECISION + 2 * dP) * D) / ((N_A / A_PRECISION - 1) * D + 3 * dP);
            if (D.within1(prevD)) {
                break;
            }
        }
        computed = D;
    }

    function _getY(uint256 x, uint256 D, uint256 A) private pure returns (uint256 y) {
        uint256 N_A = A * 4;
        uint256 c = (D * D) / (x * 2);
        c = (c * D) / ((N_A * 2) / A_PRECISION);
        uint256 b = x + ((D * A_PRECISION) / N_A);
        uint256 yPrev;
        y = D;
        // @dev Iterative approximation.
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            uint numerator = y * y + c;
            uint denominator = y * 2 + b - D;
            y = numerator.divRoundUp(denominator);
            if (y.within1(yPrev)) {
                break;
            }
        }
    }

}