// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {IVPool, IERC20} from "../interfaces/external/vesper/IVPool.sol";
import {Adapter} from "./Adapter.sol";

contract VesperAdapter is Adapter {
    function deposit(IVPool vPool_) external payable {
        IERC20 _token = IERC20(vPool_.token());
        uint256 _amount = _token.balanceOf(address(this));
        _approveIfNeeded(_token, address(vPool_), _amount);
        vPool_.deposit(_amount);
    }

    function withdraw(IVPool vPool_) external payable {
        vPool_.withdraw(vPool_.balanceOf(address(this)));
    }
}