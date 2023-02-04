// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import "./Math.sol";

import "./Swap.sol";

library TokenChecker {
    function checkMin(TokenCheck calldata check_, uint256 amount_) internal pure returns (uint256) {
        orderMinMax(check_);
        limitMin(check_, amount_);
        return capByMax(check_, amount_);
    }

    function checkMinMax(TokenCheck calldata check_, uint256 amount_) internal pure {
        orderMinMax(check_);
        limitMin(check_, amount_);
        limitMax(check_, amount_);
    }

    function checkMinMaxToken(TokenCheck calldata check_, uint256 amount_, address token_) internal pure {
        orderMinMax(check_);
        limitMin(check_, amount_);
        limitMax(check_, amount_);
        limitToken(check_, token_);
    }

    function orderMinMax(TokenCheck calldata check_) private pure {
        require(check_.minAmount <= check_.maxAmount, "TC: unordered min/max amounts");
    }

    function limitMin(TokenCheck calldata check_, uint256 amount_) private pure {
        require(amount_ >= check_.minAmount, "TC: insufficient token amount");
    }

    function limitMax(TokenCheck calldata check_, uint256 amount_) private pure {
        require(amount_ <= check_.maxAmount, "TC: excessive token amount");
    }

    function limitToken(TokenCheck calldata check_, address token_) private pure {
        require(token_ == check_.token, "TC: wrong token address");
    }

    function capByMax(TokenCheck calldata check_, uint256 amount_) private pure returns (uint256) {
        return Math.min(amount_, check_.maxAmount);
    }
}