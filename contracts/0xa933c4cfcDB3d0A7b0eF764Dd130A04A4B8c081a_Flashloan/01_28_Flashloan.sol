pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import './sushiswap/IUniswapV2Pair.sol';
import './sushiswap/IUniswapV2Router02.sol';
import "./aave/FlashLoanReceiverBase.sol";
import "./aave/ILendingPoolAddressesProvider.sol";
import "./aave/ILendingPool.sol";

contract Flashloan is FlashLoanReceiverBase {
    enum Swap { UNISWAP, SUSHISWAP }

    using SafeMath for uint256;

    ISwapRouter public immutable uniswapRouter;
    IUniswapV2Router02 public immutable sushiswapRouter;

    event FlashLoanCompleted(address asset, uint256 profit);

    constructor(address _addressProvider, ISwapRouter _uniswapRouter, IUniswapV2Router02 _sushiswapRouter) FlashLoanReceiverBase(_addressProvider) {
        uniswapRouter = _uniswapRouter;
        sushiswapRouter = _sushiswapRouter;
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
        override
    {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");

        address asset = _execute(_amount, _params);
        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
        //

        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
        uint256 profit = IERC20(asset).balanceOf(address(this));
        TransferHelper.safeTransfer(asset, owner(), profit);
        emit FlashLoanCompleted(asset, profit);
    }

    /**
        Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
     */
    function flashloan(
        address _uniswapPool,
        address _sushiswapPool,
        address _flashAsset,
        uint _flashAmount,
        Swap _firstSwap,
        address _asset
    ) public onlyOwner {
        bytes memory data = abi.encode(_uniswapPool,_sushiswapPool, _flashAsset, _flashAmount, _asset, _firstSwap);

        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), _flashAsset, _flashAmount, data);
    }

    function _execute(uint256 _amount, bytes calldata _params) internal returns(address flashAsset) {
        (address _uniswapPool, address _sushiswapPool, address _flashAsset, uint _flashAmount, address _asset, Swap _firstSwap) = abi.decode(_params, (address, address, address, uint, address, Swap));
        require(_flashAmount == _amount, 'Requested flashloan not equal to what we got');

        uint24 uniswapPoolFee = IUniswapV3Pool(_uniswapPool).fee();

        if (_firstSwap == Swap.UNISWAP) {
            uint256 _amountOut = uniswapSwap(_amount, _flashAsset, _asset, uniswapPoolFee);

            sushiswapSwap(_amountOut, _asset, _flashAsset);
        } else {
           uint256 _amountOut=  sushiswapSwap(_amount, _flashAsset, _asset);

           uniswapSwap(_amountOut, _asset, _flashAsset, uniswapPoolFee);
        }

        flashAsset = _flashAsset;
    }

    /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
    /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
    /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
    /// @return amountOut The amount of WETH9 received.
    function uniswapSwap(uint256 amountIn, address inAsset, address outAsset, uint24 poolFee) internal returns (uint256 amountOut) {
        TransferHelper.safeApprove(inAsset, address(uniswapRouter), amountIn);
                // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: inAsset,
                tokenOut: outAsset,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = uniswapRouter.exactInputSingle(params);
    }

    function sushiswapSwap(uint256 amountIn, address inAsset, address outAsset) internal returns (uint256 amountOut) {
        TransferHelper.safeApprove(inAsset, address(sushiswapRouter), amountIn);

        address[] memory path = new address[](2);
        path[0] = inAsset;
        path[1] = outAsset;

        amountOut = sushiswapRouter.swapExactTokensForTokens(amountIn, sushiswapGetAmountsOut(amountIn, path)[0], path, address(this), block.timestamp)[0];
    }

    function sushiswapGetAmountsOut(uint tokenAmount, address[] memory path) internal view returns (uint[] memory) {
        return sushiswapRouter.getAmountsOut(tokenAmount, path);
    }
}