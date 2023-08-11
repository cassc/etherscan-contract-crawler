// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library Utils {
    function scaleDecimals(
        uint _amount,
        ERC20 _fromToken,
        ERC20 _toToken
    ) internal view returns (uint _scaled) {
        uint decFrom = _fromToken.decimals();
        uint decTo = _toToken.decimals();

        if (decTo > decFrom) {
            return _amount * (10 ** (decTo - decFrom));
        } else {
            return _amount / (10 ** (decFrom - decTo));
        }
    }
}