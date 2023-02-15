// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external virtual;
}

contract Token is ERC20 {
    mapping (address => bool) private _contracts;

    constructor() {
        _name = "Eternal Token";
        _symbol = "ETRNL";
        _decimals = 18;
        _limitSupply = 1000000e18;
    }

    function approveAndCall(address spender, uint256 amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);
        return true;
    }

    function transfer(address to, uint256 value) public override virtual returns (bool) {
        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }
        return true;
    }
}