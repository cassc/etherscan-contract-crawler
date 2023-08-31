// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

/// Library to handle basic token functions for ERC20s & ETH (represented by 0x0)
library TokenUtils {
    using SafeTransferLib for address;

    address internal constant ETH_ADDRESS = address(0);

    function _isETH(address token) internal pure returns (bool) {
        return (token == ETH_ADDRESS);
    }

    function _decimals(address token) internal view returns (uint8) {
        return _isETH(token) ? 18 : ERC20(token).decimals();
    }

    function _balanceOf(address token, address addr) internal view returns (uint256) {
        return _isETH(token) ? addr.balance : ERC20(token).balanceOf(addr);
    }

    function _safeTransfer(address token, address addr, uint256 amount) internal {
        if (_isETH(token)) addr.safeTransferETH(amount);
        else token.safeTransfer(addr, amount);
    }
}

interface ERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address addr) external view returns (uint256);
}