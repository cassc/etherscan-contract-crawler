// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Basic {
    using SafeERC20 for IERC20;
    /**
     * @dev Return ethereum address
     */
    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Return Wrapped ETH address
    address internal constant wethAddr =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function safeTransferETH(address to, uint256 value) internal {
        if (value != 0) {
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(success, "helper::safeTransferETH: ETH transfer failed");
        }
    }
}