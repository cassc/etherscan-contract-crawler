// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/balancer/IBalancerPool.sol";
import "./BaseController.sol";

contract BalancerController is BaseController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line no-empty-blocks
    constructor(address manager, address _accessControl, address _addressRegistry) public BaseController(manager, _accessControl, _addressRegistry) {}

    /// @notice Used to deploy liquidity to a Balancer pool
    /// @dev Calls into external contract
    /// @param poolAddress Address of pool to have liquidity added
    /// @param tokens Array of ERC20 tokens to be added to pool
    /// @param amounts Corresponding array of amounts of tokens to be added to a pool
    /// @param data Bytes data passed from manager containing information to be passed to the balancer pool
    function deploy(
        address poolAddress,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyManager onlyAddLiquidity {
        require(tokens.length == amounts.length, "TOKEN_AMOUNTS_COUNT_MISMATCH");
        require(tokens.length > 0, "TOKENS_AMOUNTS_NOT_PROVIDED");

        for (uint256 i = 0; i < tokens.length; ++i) {
            require(addressRegistry.checkAddress(address(tokens[i]), 0), "INVALID_TOKEN");
            _approve(tokens[i], poolAddress, amounts[i]);
        }

        IBalancerPool pool = IBalancerPool(poolAddress);
        uint256 balanceBefore = pool.balanceOf(address(this));

        //Notes:
        // - If your pool is eligible for weekly BAL rewards, they will be distributed to your LPs automatically
        // - If you contribute significant long-term liquidity to the platform, you can apply to have smart contract deployment gas costs reimbursed from the Balancer Ecosystem fund
        // - The pool is the LP token, All pools in Balancer are also ERC20 tokens known as BPTs \(Balancer Pool Tokens\)
        (uint256 poolAmountOut, uint256[] memory maxAmountsIn) = abi.decode(
            data,
            (uint256, uint256[])
        );
        pool.joinPool(poolAmountOut, maxAmountsIn);
        
        uint256 balanceAfter = pool.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "MUST_INCREASE");
    }

    /// @notice Used to withdraw liquidity from balancer pools
    /// @dev Calls into external contract
    /// @param poolAddress Address of pool to have liquidity withdrawn
    /// @param data Data to be decoded and passed to pool
    function withdraw(address poolAddress, bytes calldata data) external onlyManager onlyRemoveLiquidity {
        (uint256 poolAmountIn, uint256[] memory minAmountsOut) = abi.decode(
            data,
            (uint256, uint256[])
        );

        IBalancerPool pool = IBalancerPool(poolAddress);
        address[] memory tokens = pool.getFinalTokens();
        uint256[] memory balancesBefore = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            balancesBefore[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        _approve(IERC20(poolAddress), poolAddress, poolAmountIn);
        pool.exitPool(poolAmountIn, minAmountsOut);

        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 balanceAfter = IERC20(tokens[i]).balanceOf(address(this));
            require(balanceAfter > balancesBefore[i], "MUST_INCREASE");
        }
    }

    function _approve(
        IERC20 token,
        address poolAddress,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), poolAddress);
        if (currentAllowance > 0) {
            token.safeDecreaseAllowance(poolAddress, currentAllowance);
        }
        token.safeIncreaseAllowance(poolAddress, amount);
    }
}