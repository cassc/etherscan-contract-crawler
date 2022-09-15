// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "solmate/utils/SafeTransferLib.sol";
import "authorised/Authorised.sol";
import "./libraries/UniPoolAddress.sol";
import "./interfaces/IAaveLendingPool.sol";
import "./interfaces/IUniV2Pool.sol";
import "./interfaces/IUniV3Pool.sol";
import "./interfaces/IUniV2Callback.sol";
import "./interfaces/IUniV3Callback.sol";
import "./interfaces/IWETH.sol";

contract AaveStrategy is IUniV3Callback, IUniswapV2Callback, Authorised {

    using SafeTransferLib for ERC20;

    enum Action { LEVERAGE, DELEVERAGE, SWAP_COLLATERAL }

    enum Network { NONE, POS, POW }

    //Uniswap V3 trading pool constant.
    uint160 internal constant MIN_SQRT_RATIO = 4295128739 + 1;
    //Uniswap V3 trading pool constant.
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;
    //Uniswap V3 factory.
    address internal constant uniV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    //Weth address.
    ERC20 internal constant weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    //Aave lending pool.
    ILendingPool internal constant lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    //Verify sender for pool callbacks.
    address internal callbackAddress;

    constructor() Authorised(msg.sender) {}

    modifier enforceNetwork(Network network) {
        if (network == Network.POS) {
            require(block.difficulty > 2 ** 64, "We are not on POS.");
        } else if (network == Network.POW) {
            require(block.difficulty <= 2 ** 64, "We are not on POW.");
        }
        _;
    }

    modifier validCallback() {
        require(msg.sender == callbackAddress, "Invalid call.");
        _;
    }

    receive() external payable {
        _wrapEth(msg.value);
        _deposit(weth, msg.value);
    }

    function uniswapV3SwapCallback(int256 change0, int256 change1, bytes calldata data) external validCallback {
        (Action action, ERC20 tokenIn, ERC20 tokenOut) = abi.decode(data, (Action, ERC20, ERC20));
        if (change0 > change1) {
            closeSwap(tokenIn, tokenOut, uint256(change0), uint256(-change1), action);
        } else {
            closeSwap(tokenIn, tokenOut, uint256(change1), uint256(-change0), action);
        }
    }

    function uniswapV2Call(address, uint amount0Out, uint amount1Out, bytes calldata data) external validCallback {
        (Action action, uint256 amountIn, ERC20 tokenIn, ERC20 tokenOut) = abi.decode(data, (Action, uint256, ERC20, ERC20));
        closeSwap(tokenIn, tokenOut, amountIn, amount1Out + amount0Out, action);
    }

    function closeSwap(ERC20 tokenIn, ERC20 tokenOut, uint256 amountIn, uint256 amountOut, Action action) internal {
        if (action == Action.LEVERAGE) {
            _deposit(tokenOut, amountOut);
            _borrow(tokenIn, amountIn, 2);
            tokenIn.safeTransfer(msg.sender, amountIn);
        } else if (action == Action.DELEVERAGE) {
            _repay(tokenOut, amountOut, 2);
            _withdraw(tokenIn, amountIn, msg.sender);
        } else if (action == Action.SWAP_COLLATERAL) {
            _deposit(tokenOut, amountOut);
            _withdraw(tokenIn, amountIn, msg.sender);
        }
    }

    function withdrawFromAave(address asset, uint256 amount, Network network) external onlyAuthorised enforceNetwork(network) {
        lendingPool.withdraw(asset, amount, address(this));
    }

    function withdrawToken(ERC20 token, address to, uint256 amount, Network network) external onlyAuthorised enforceNetwork(network) {
        token.transfer(to, amount);
    }

    // Buy weth with usdc on a uni v3 pool. usdc is token 0, weth is token 1.
    // exactInput ~ positive number
    // exactOutput ~ negative number
    // Assume we have some borrowing power in aave already.
    /// @param tokenIn Token in for the Uniswap trade.
    /// @param tokenOut Token out for the Uniswap trade.
    /// @param fee Uniswap pool fee tier.
    /// @param amountOut Amount out of the trade that will be sent to aave as collateral.
    /// @param maxAmountIn Slippage protection - max
    function leverageV3(address tokenIn, address tokenOut, uint24 fee, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV3(tokenIn, tokenOut, fee, amountOut, maxAmountIn, Action.LEVERAGE);
    }

    function leverageV2(address factory, address tokenIn, address tokenOut, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV2(factory, tokenIn, tokenOut, amountOut, maxAmountIn, Action.LEVERAGE);
    }

    function repayV3(address tokenIn, address tokenOut, uint24 fee, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV3(tokenIn, tokenOut, fee, amountOut, maxAmountIn, Action.DELEVERAGE);
    }

    function repayV2(address factory, address tokenIn, address tokenOut, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV2(factory, tokenIn, tokenOut, amountOut, maxAmountIn, Action.DELEVERAGE);
    }

    function swapCollateralV3(address tokenIn, address tokenOut, uint24 fee, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV3(tokenIn, tokenOut, fee, amountOut, maxAmountIn, Action.SWAP_COLLATERAL);
    }

    function swapCollateralV2(address factory, address tokenIn, address tokenOut, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV2(factory, tokenIn, tokenOut, amountOut, maxAmountIn, Action.SWAP_COLLATERAL);
    } 

    function getUserAccountData() external view returns (uint256 totalCollateralETH, uint256 totalDebtETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor) {
        return lendingPool.getUserAccountData(address(this));
    }

    function availableEthToWithdraw() external view returns (uint256) {
        (,,uint256 availableBorrowsETH,,,) = lendingPool.getUserAccountData(address(this));
        return availableBorrowsETH * 1000 / 825;
    }

    function getDebt(address asset) external view returns (uint256) {
        ERC20 debtToken = ERC20(lendingPool.getReserveData(asset).variableDebtTokenAddress);
        return debtToken.balanceOf(address(this));
    }


    function getAvailalbeFunds(ERC20[] memory assets) external view returns (uint256[] memory available) {
        uint256 n = assets.length;
        available = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            ERC20 asset = assets[i];
            available[i] = asset.balanceOf(lendingPool.getReserveData(address(asset)).aTokenAddress) / (asset.decimals() - 2);
        }
    }

    function _swapUniV3(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint256 maxAmountIn,
        Action action
    ) internal returns (uint256 amountIn) {
        address pool = UniPoolAddress.computeAddress(uniV3Factory, UniPoolAddress.getPoolKey(tokenIn, tokenOut, fee));
        callbackAddress = pool;
        amountIn = __swapUniV3(IUniV3Pool(pool), tokenIn < tokenOut, amountOut, abi.encode(action, tokenIn, tokenOut));
        require(amountIn <= maxAmountIn, "Slippage.");
        callbackAddress = address(0);
    }

    function __swapUniV3(
        IUniV3Pool pool,
        bool zeroForOne,
        uint256 amountOut,
        bytes memory data
    ) internal returns (uint256 amountIn) {
        (int256 change0, int256 change1) = pool.swap(
            address(this),
            zeroForOne,
            -int256(amountOut),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            data
        );
        amountIn = uint256(zeroForOne ? change0 : change1);
    }

    function _swapUniV2(
        address factory,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        Action action
    ) internal returns (uint256 amountIn) {
        IUniV2Pool pool = IUniV2Pool(UniPoolAddress.pairFor(factory, tokenIn, tokenOut));
        callbackAddress = address(pool);
        (uint256 reserve0, uint256 reserve1,) = pool.getReserves();
        if (tokenIn < tokenOut) { // zeroForOne ~ true
            amountIn = _getAmountIn(amountOut, reserve0, reserve1);
            pool.swap(0, amountOut, address(this), abi.encode(action, amountIn, tokenIn, tokenOut));
        } else {
            amountIn = _getAmountIn(amountOut, reserve1, reserve0);
            pool.swap(amountOut, 0, address(this), abi.encode(action, amountIn, tokenIn, tokenOut));
        }
        require(amountIn <= maxAmountIn, "Slippage.");
        callbackAddress = address(0);
    }

    function _wrapEth(uint256 amount) internal {
        IWETH(address(weth)).deposit{value: amount}();
    }

    function _deposit(ERC20 asset, uint256 amount) internal {
        asset.safeApprove(address(lendingPool), amount);
        lendingPool.deposit(address(asset), amount, address(this), 0);
    }

    function _borrow(ERC20 asset, uint256 amount, uint256 rateMode) internal {
        lendingPool.borrow(address(asset), amount, rateMode, 0, address(this));
    }

    function _repay(ERC20 asset, uint256 amount, uint256 rateMode) internal {
        asset.safeApprove(address(lendingPool), amount);
        lendingPool.repay(address(asset), amount, rateMode, address(this));
    }

    function _withdraw(ERC20 asset, uint256 amount, address to) internal {
        lendingPool.withdraw(address(asset), amount, to);
    }

    function _getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    function executeAnything(address target, uint256 val, bytes memory data) external onlyOwner returns (bytes memory res) {
        bool ok;
        (ok, res) = target.call{value: val}(data);
        require(ok, "failed");
    }

}

// (1120,2493) ~ (-206107, -198107)
// (1300,2493) ~ (-204619, -198107)