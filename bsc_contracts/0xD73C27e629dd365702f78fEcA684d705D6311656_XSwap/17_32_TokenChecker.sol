// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {TokenCheck} from "../swap/Swap.sol";

library TokenChecker {
    function checkMin(TokenCheck calldata check_, uint256 amount_) internal pure returns (uint256) {
        order(check_); min(check_, amount_);
        return capMax(check_, amount_);
    }

    function checkMinMax(TokenCheck calldata check_, uint256 amount_) internal pure {
        order(check_); min(check_, amount_); max(check_, amount_);
    }

    function checkMinMaxToken(TokenCheck calldata check_, uint256 amount_, address token_) internal pure {
        order(check_); min(check_, amount_); max(check_, amount_); token(check_, token_);
    }

    function order(TokenCheck calldata check_) private pure {
        require(check_.minAmount <= check_.maxAmount, "TC: unordered min/max amounts");
    }

    function min(TokenCheck calldata check_, uint256 amount_) private pure {
        require(amount_ >= check_.minAmount, "TC: insufficient token amount");
    }

    function max(TokenCheck calldata check_, uint256 amount_) private pure {
        require(amount_ <= check_.maxAmount, "TC: excessive token amount");
    }

    function token(TokenCheck calldata check_, address token_) private pure {
        require(token_ == check_.token, "TC: wrong token address");
    }

    function capMax(TokenCheck calldata check_, uint256 amount_) private pure returns (uint256) {
        return amount_ < check_.maxAmount ? amount_ : check_.maxAmount;
    }
}