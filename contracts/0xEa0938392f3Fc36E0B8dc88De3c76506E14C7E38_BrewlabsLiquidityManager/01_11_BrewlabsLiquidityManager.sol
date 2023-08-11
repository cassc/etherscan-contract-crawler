// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IUniRouter02} from "./libs/IUniRouter02.sol";
import {IWETH} from "./libs/IWETH.sol";

interface IUniV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IUniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function getReserves1()
        external
        view
        returns (uint112 _reserve0, uint112 _reserve1, uint32 feePercent, uint32 _blockTimestampLast);

    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
}

contract BrewlabsLiquidityManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public fee = 100; // 1%
    address public treasury = 0x64961Ffd0d84b2355eC2B5d35B0d8D8825A774dc;
    address public walletA = 0xE1f1dd010BBC2860F81c8F90Ea4E38dB949BB16F;

    uint256 public slippageFactor = 9500; // 5% default slippage tolerance
    uint256 public constant slippageFactorUL = 8000;
    uint256 public constant FEE_DENOMINATOR = 10000;

    uint256 public buyBackLimit = 0.1 ether;

    event WalletAUpdated(address addr);
    event FeeUpdated(uint256 fee);
    event BuyBackLimitUpdated(uint256 limit);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "BrewlabsLiquidityManager: EXPIRED");
        _;
    }

    constructor() {}

    function addLiquidity(
        address router,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 slipPage,
        uint256 deadline
    ) external ensure(deadline) nonReentrant returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(amountADesired > 0 && amountBDesired > 0, "amount is zero");
        require(tokenA != tokenB, "cannot use same token for pair");

        {
            uint256 fee0Amt = amountADesired * fee / FEE_DENOMINATOR;
            uint256 fee1Amt = amountBDesired * fee / FEE_DENOMINATOR;
            IERC20(tokenA).safeTransferFrom(msg.sender, walletA, fee0Amt);
            IERC20(tokenB).safeTransferFrom(msg.sender, walletA, fee1Amt);

            uint256 amountAMin = amountADesired * (FEE_DENOMINATOR - slipPage) / FEE_DENOMINATOR;
            uint256 amountBMin = amountBDesired * (FEE_DENOMINATOR - slipPage) / FEE_DENOMINATOR;
            amountADesired -= fee0Amt;
            amountBDesired -= fee1Amt;
            (amountA, amountB) =
                _addLiquidity(router, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        }
        address pair = getPair(router, tokenA, tokenB);

        IERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);
        liquidity = IUniPair(pair).mint(msg.sender);
    }

    function addLiquidityETH(
        address router,
        address token,
        uint256 amountTokenDesired,
        uint256 slipPage,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        nonReentrant
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        require(amountTokenDesired > 0, "amount is zero");
        require(msg.value > 0, "amount is zero");

        address WETH = IUniRouter02(router).WETH();

        {
            uint256 fee0Amt = amountTokenDesired * fee / FEE_DENOMINATOR;
            uint256 fee1Amt = msg.value * fee / FEE_DENOMINATOR;
            IERC20(token).safeTransferFrom(msg.sender, walletA, fee0Amt);
            payable(treasury).transfer(fee1Amt);
        }
        {
            uint256 amountTokenMin = amountTokenDesired * (FEE_DENOMINATOR - slipPage) / FEE_DENOMINATOR;
            uint256 amountETHMin = msg.value * (FEE_DENOMINATOR - slipPage) / FEE_DENOMINATOR;

            uint256 _amountTokenDesired = amountTokenDesired * (FEE_DENOMINATOR - fee) / FEE_DENOMINATOR;
            uint256 _amountETHDesired = msg.value * (FEE_DENOMINATOR - fee) / FEE_DENOMINATOR;

            (amountToken, amountETH) =
                _addLiquidity(router, token, WETH, _amountTokenDesired, _amountETHDesired, amountTokenMin, amountETHMin);
        }

        address pair = getPair(router, token, WETH);
        IERC20(token).safeTransferFrom(msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniPair(pair).mint(msg.sender);
    }

    function _addLiquidity(
        address router,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        address pair = getPair(router, tokenA, tokenB);
        if (pair == address(0)) {
            pair = _createPair(router, tokenA, tokenB);
        }

        (uint256 reserveA, uint256 reserveB) = _getReserves(pair, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = _quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "BrewlabsLiquidityManager: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = _quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "BrewlabsLiquidityManager: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _getReserves(address pair, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = _sortTokens(tokenA, tokenB);
        try IUniPair(pair).getReserves() returns (uint112 reserve0, uint112 reserve1, uint32) {
            (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        } catch {
            (uint256 reserve0, uint256 reserve1,,) = IUniPair(pair).getReserves1();
            (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        }
    }

    function _quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "BrewlabsLiquidityManager: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "BrewlabsLiquidityManager: INSUFFICIENT_LIQUIDITY");
        amountB = amountA * reserveB / reserveA;
    }

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "BrewlabsLiquidityManager: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "BrewlabsLiquidityManager: ZERO_ADDRESS");
    }

    function removeLiquidity(
        address router,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) nonReentrant returns (uint256 amountA, uint256 amountB) {
        require(liquidity > 0, "amount is zero");

        address pair = getPair(router, tokenA, tokenB);
        require(pair != address(0), "invalid liquidity");

        uint256 _fee = liquidity * fee / FEE_DENOMINATOR;
        IERC20(pair).safeTransferFrom(msg.sender, pair, _fee);
        IUniPair(pair).burn(walletA);

        IERC20(pair).safeTransferFrom(msg.sender, pair, liquidity - _fee); // send liquidity to pair

        (uint256 amount0, uint256 amount1) = IUniPair(pair).burn(to);
        (address token0,) = _sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "BrewlabsLiquidityManager: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "BrewlabsLiquidityManager: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address router,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        require(liquidity > 0, "amount is zero");

        address WETH = IUniRouter02(router).WETH();
        (amountToken, amountETH) =
            removeLiquidity(router, token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);

        IERC20(token).safeTransfer(to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        payable(to).transfer(amountETH);
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address router,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountETH) {
        require(liquidity > 0, "amount is zero");

        address WETH = IUniRouter02(router).WETH();
        (, amountETH) =
            removeLiquidity(router, token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        IERC20(token).safeTransfer(to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        payable(to).transfer(amountETH);
    }

    function buyBack(address router, address[] memory wethToBrewsPath) internal {
        uint256 ethAmt = address(this).balance;

        if (ethAmt > buyBackLimit) {
            _safeSwapWeth(router, ethAmt, wethToBrewsPath, treasury);
        }
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0x0), "Invalid address");
        treasury = _treasury;
    }

    function updateWalletA(address _walletA) external onlyOwner {
        require(_walletA != address(0x0) || _walletA != walletA, "Invalid address");

        walletA = _walletA;
        emit WalletAUpdated(_walletA);
    }

    function updateFee(uint256 _fee) external onlyOwner {
        require(_fee < 2000, "fee cannot exceed 20%");

        fee = _fee;
        emit FeeUpdated(_fee);
    }

    function updateBuyBackLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "Invalid amount");

        buyBackLimit = _limit;
        emit BuyBackLimitUpdated(_limit);
    }

    function _createPair(address router, address token0, address token1) internal returns (address) {
        address factory = IUniRouter02(router).factory();
        return IUniV2Factory(factory).createPair(token0, token1);
    }

    function getPair(address router, address token0, address token1) public view returns (address) {
        address factory = IUniRouter02(router).factory();
        return IUniV2Factory(factory).getPair(token0, token1);
    }

    function _safeSwapWeth(address router, uint256 _amountIn, address[] memory _path, address _to) internal {
        uint256[] memory amounts = IUniRouter02(router).getAmountsOut(_amountIn, _path);
        uint256 amountOut = amounts[amounts.length - 1];

        IUniRouter02(router).swapExactETHForTokens{value: _amountIn}(
            amountOut * slippageFactor / FEE_DENOMINATOR, _path, _to, block.timestamp + 600
        );
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param token: the address of the token to withdraw
     * @param amount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        if (token == address(0x0)) {
            payable(msg.sender).transfer(amount);
        } else {
            IERC20(token).safeTransfer(address(msg.sender), amount);
        }

        emit AdminTokenRecovered(token, amount);
    }

    receive() external payable {}
}