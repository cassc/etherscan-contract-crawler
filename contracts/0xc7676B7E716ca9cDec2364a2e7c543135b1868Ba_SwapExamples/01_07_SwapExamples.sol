// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IWETH} from "./WETH9.sol";

import "hardhat/console.sol";

contract SwapExamples {
    event Mint(address to, uint256 amount);

    // For the scope of these swap examples,
    // we will detail the design considerations when using `exactInput`, `exactInputSingle`, `exactOutput`, and  `exactOutputSingle`.
    // It should be noted that for the sake of these examples we pass in the swap router as a constructor argument instead of inheriting it.
    // More advanced example contracts will detail how to inherit the swap router safely.
    // This example swaps DAI/WETH9 for single path swaps and DAI/USDC/WETH9 for multi path swaps.

    ISwapRouter public constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Same on all Nets SwapRouter address
    // Mainnet DAI Contract Address: 0x6B175474E89094C44Da98b954EedeAC495271d0F // Rinkeby: 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa
    address public DAI =
        block.chainid == 1
            ? 0x6B175474E89094C44Da98b954EedeAC495271d0F
            : 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
    // Mainnet WETH Contract Address: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 // Rinkeby: 0xc778417E063141139Fce010982780140Aa0cD5Ab
    address public WETH9 =
        block.chainid == 1
            ? 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            : 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // Mainnet USDC Contract Address: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 // Rinkeby: 0xeb8f08a975ab53e34d8a0330e0d34de942c95926
    address public USDC =
        block.chainid == 1
            ? 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
            : 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    constructor() {}

    function mint() public payable {
        console.log("Minting");
        console.log("Payed in %s", msg.value);

        emit Mint(msg.sender, msg.value);
    }

    function wrap() public {
        IWETH(WETH9).deposit{value: address(this).balance}();
    }

    function transferTest() public {
        uint256 currentBlance = IWETH(WETH9).balanceOf(address(this));

        TransferHelper.safeTransferFrom(
            WETH9,
            address(this),
            address(this),
            currentBlance
        );

        TransferHelper.safeApprove(WETH9, address(swapRouter), currentBlance);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: USDC,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: currentBlance,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        swapRouter.exactInputSingle(params);
    }

    /// @notice swapExactInputSingle swaps a fixed amount of WETH0 for a maximum possible amount of USDC
    /// using the WETH9/USDC 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its WETH9 for this function to succeed.
    /// @param amountIn The exact amount of WETH9 that will be swapped for USDC.
    /// @return amountOut The amount of USDC received.
    function swapExactInputSingle(uint256 amountIn)
        external
        returns (uint256 amountOut)
    {
        // msg.sender must approve this contract
        console.log("1");
        // Transfer the specified amount of WETH9 to this contract.
        TransferHelper.safeTransferFrom(
            WETH9,
            address(this),
            address(this),
            amountIn
        );
        console.log("2");
        // Approve the router to spend WETH9.
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);
        console.log("3");
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: USDC,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        console.log("4");
        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
        console.log("5");
        console.log("Swapped %s WETH9 for %s USDC", amountIn, amountOut);
    }

    /// @notice swapExactOutputSingle swaps a minimum possible amount of DAI for a fixed amount of WETH.
    /// @dev The calling address must approve this contract to spend its DAI for this function to succeed. As the amount of input DAI is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The exact amount of WETH9 to receive from the swap.
    /// @param amountInMaximum The amount of DAI we are willing to spend to receive the specified amount of WETH9.
    /// @return amountIn The amount of DAI actually spent in the swap.
    function swapExactOutputSingle(uint256 amountOut, uint256 amountInMaximum)
        external
        returns (uint256 amountIn)
    {
        // Transfer the specified amount of DAI to this contract.
        TransferHelper.safeTransferFrom(
            DAI,
            msg.sender,
            address(this),
            amountInMaximum
        );

        // Approve the router to spend the specified `amountInMaximum` of DAI.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to achieve a better swap.
        TransferHelper.safeApprove(DAI, address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH9,
                tokenOut: USDC,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(DAI, address(swapRouter), 0);
            TransferHelper.safeTransfer(
                DAI,
                msg.sender,
                amountInMaximum - amountIn
            );
        }
    }
}