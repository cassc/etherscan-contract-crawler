// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IWETH} from "../interfaces/external/IWETH.sol";

contract WETHAdapter {
    IWETH public immutable wethLike;

    constructor(address wethLike_) {
        wethLike = IWETH(wethLike_);
    }

    function wrap() external payable {
        wethLike.deposit{value: address(this).balance}();
    }

    function unwrap() external payable {
        wethLike.withdraw(wethLike.balanceOf(address(this)));
    }
}