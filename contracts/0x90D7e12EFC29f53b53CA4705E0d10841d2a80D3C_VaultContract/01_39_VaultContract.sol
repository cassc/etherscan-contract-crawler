// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IMulticall.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract VaultContract is IERC721Receiver {
    address public Owner;
    address public GasWallet;
    address constant swapRouterAddress = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant nonfungiblePositionManagerAddress = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;


    constructor() {
        Owner = msg.sender;
        GasWallet = msg.sender;
    }

    function _Owner() external view returns(address) {
        return Owner;
    }

    function _GasWallet() external view returns(address) {
        return GasWallet;
    }

    function mintPosition(bytes[] calldata data, uint256 amount) public payable returns (bytes[] memory results) {
        require(
            msg.sender == GasWallet,
            "Gas Wallet Incorrect"
        );
        TransferHelper.safeApprove(
            usdc,
            swapRouterAddress,
            amount
        );
        results = IMulticall(swapRouterAddress).multicall(data);
        return results;
    }

    function swapExactInputSingle(
        address Token_In,
        address Token_Out,
        uint24 Pool_Fee,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external returns (uint256 amountOut) {
        require(
            msg.sender == GasWallet,
            "Gas Wallet Incorrect"
        );

        ISwapRouter swapRouter = ISwapRouter(
            swapRouterAddress
        );

        TransferHelper.safeApprove(
            Token_In,
            swapRouterAddress,
            amountIn
        );
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: Token_In,
                tokenOut: Token_Out,
                fee: Pool_Fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
            
        // The call to `exactInputSingle` executes the swap
        amountOut = swapRouter.exactInputSingle(params);
    }

    function RemoveLiquidity(
        uint256 tokenId, 
        uint128 liquidity
    ) external returns (uint256 amount0, uint256 amount1)
    {
        // amount0Min and amount1Min are price slippage checks
        // if the amount received after burning is not greater than these minimums, transaction will fail
        require(
            msg.sender == GasWallet,
            "Gas Wallet Incorrect"
        );

        INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(
                nonfungiblePositionManagerAddress
            );
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: liquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            params
        );
    }

    /// @notice Collects the fees associated with provided liquidity
    /// @dev The contract must hold the erc721 token before it can collect fees
    function collectAllFees(uint256 tokenId)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        require(
            msg.sender == GasWallet,
            "Gas Wallet Incorrect"
        );
        // Caller must own the ERC721 position, meaning it must be a deposit
        INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(
                nonfungiblePositionManagerAddress
            );
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        // send collected feed back to owner
    }

    function changeGasWallet(address new_gas_wallet) public {
        require(msg.sender == Owner, "Invalid Owner");
        GasWallet = new_gas_wallet;
    }

    function transferOwnership(address new_owner_wallet) public {
        require(msg.sender == Owner, "Invalid Owner");
        Owner = new_owner_wallet;
    }

    function emergencyWithdraw(address token_address) external {
        require(msg.sender == Owner, "Invalid Owner");

        ERC20 token = ERC20(token_address);

        TransferHelper.safeTransfer(
            token_address,
            Owner,
            token.balanceOf(address(this))
        );
    }

    // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}