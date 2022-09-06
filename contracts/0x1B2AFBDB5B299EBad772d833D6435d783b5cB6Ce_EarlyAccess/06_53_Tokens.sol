// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Tokens {
    using SafeERC20 for IERC20;

    function transfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "LEVX: FAILED_TO_TRANSFER_ETH");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}