// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {TokenHelper} from "../asset/TokenHelper.sol";

struct Withdraw {
    address token;
    uint256 amount;
    address to;
}

abstract contract Withdrawable {
    event Withdrawn(address token, uint256 amount, address to);

    function withdraw(Withdraw[] calldata withdraws_) external virtual {
        _checkWithdraw();
        for (uint256 i = 0; i < withdraws_.length; i++) {
            Withdraw calldata w = withdraws_[i];
            TokenHelper.transferFromThis(w.token, w.to, w.amount);
            emit Withdrawn(w.token, w.amount, w.to);
        }
    }

    function _checkWithdraw() internal view virtual;
}