// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import {NATIVE_TOKEN} from "../constants/Tokens.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library TokenUtils {
    using SafeERC20 for IERC20;

    modifier onlyERC20(address _token) {
        require(_token != NATIVE_TOKEN, "TokenUtils.onlyERC20");
        _;
    }

    function transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        _token == NATIVE_TOKEN
            ? Address.sendValue(payable(_to), _amount)
            : IERC20(_token).safeTransfer(_to, _amount);
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal onlyERC20(_token) {
        if (_amount == 0) return;
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
    }

    function getBalance(address token, address user)
        internal
        view
        returns (uint256)
    {
        return
            token == NATIVE_TOKEN
                ? user.balance
                : IERC20(token).balanceOf(user);
    }
}