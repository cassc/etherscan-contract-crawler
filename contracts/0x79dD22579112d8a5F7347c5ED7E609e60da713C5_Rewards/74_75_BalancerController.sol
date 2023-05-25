// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/balancer/IBalancerPool.sol";

contract BalancerController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    function deploy(
        address poolAddress,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        require(tokens.length == amounts.length, "TOKEN_AMOUNTS_COUNT_MISMATCH");
        require(tokens.length > 0, "TOKENS_AMOUNTS_NOT_PROVIDED");

        for (uint256 i = 0; i < tokens.length; i++) {
            _approve(tokens[i], poolAddress, amounts[i]);
        }

        //Notes:
        // - If your pool is eligible for weekly BAL rewards, they will be distributed to your LPs automatically
        // - If you contribute significant long-term liquidity to the platform, you can apply to have smart contract deployment gas costs reimbursed from the Balancer Ecosystem fund
        // - The pool is the LP token, All pools in Balancer are also ERC20 tokens known as BPTs \(Balancer Pool Tokens\)
        (uint256 poolAmountOut, uint256[] memory maxAmountsIn) =
            abi.decode(data, (uint256, uint256[]));
        IBalancerPool(poolAddress).joinPool(poolAmountOut, maxAmountsIn);
    }

    function withdraw(address poolAddress, bytes calldata data) external {
        (uint256 poolAmountIn, uint256[] memory minAmountsOut) =
            abi.decode(data, (uint256, uint256[]));
        _approve(IERC20(poolAddress), poolAddress, poolAmountIn);
        IBalancerPool(poolAddress).exitPool(poolAmountIn, minAmountsOut);
    }

    function _approve(
        IERC20 token,
        address poolAddress,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), poolAddress);
        if (currentAllowance < amount) {
            token.safeIncreaseAllowance(poolAddress, type(uint256).max.sub(currentAllowance));
        }
    }
}