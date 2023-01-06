// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniSafeERC20 {
    using SafeERC20 for IERC20;

    address public constant NATIVE_TOKEN = address(0);

    function uniSafeTransferFrom(
        IERC20 asset,
        address from,
        uint256 value
    ) internal {
        if (address(asset) == NATIVE_TOKEN) {
            require(value == msg.value, "INVALID_MSG_VALUE");
        } else {
            asset.safeTransferFrom(from, address(this), value);
        }
    }

    function uniSafeTransfer(
        IERC20 asset,
        address to,
        uint256 value
    ) internal {
        if (address(asset) == NATIVE_TOKEN) {
            (bool sent, ) = payable(to).call{value: value}("");
            require(sent, "NATIVE_TOKEN_TRANSFER_FAILED");
        } else {
            asset.safeTransfer(to, value);
        }
    }
}