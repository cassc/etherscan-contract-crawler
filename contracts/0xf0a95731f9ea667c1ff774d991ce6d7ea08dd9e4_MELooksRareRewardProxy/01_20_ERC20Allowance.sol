// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ERC20Allowance {
    address public constant UNISWAP =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 constant MAX_INT = 2**256 - 1;

    function approveAllowance(address token) external {
        bytes memory data = abi.encodeWithSelector(
            IERC20.approve.selector,
            UNISWAP,
            MAX_INT
        );

        (bool success, ) = token.call(data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}