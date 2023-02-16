// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../owner/Operator.sol";

contract CanPause is Operator {
    bool public isPause = false;

    modifier onlyOpen() {
        require(isPause == false, "RebateToken: in pause state");
        _;
    }
    // set pause state
    function setPause(bool _isPause) external onlyOperator {
        isPause = _isPause;
    }
}