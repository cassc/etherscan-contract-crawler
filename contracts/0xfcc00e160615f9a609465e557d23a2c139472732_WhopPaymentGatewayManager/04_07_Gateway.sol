// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {WhopWithdrawable} from "./Withdrawable.sol";

contract WhopPaymentGateway is WhopWithdrawable {
    error AlreadyInititalized();
    error NotOwner();

    address private _owner;
    address private _manager;

    uint256 private _fees;

    constructor() {
        init(msg.sender, 100);
    }

    function init(address owner_, uint256 fees_) public {
        if (_owner != address(0)) revert AlreadyInititalized();
        _owner = owner_;
        _manager = msg.sender;
        _fees = fees_;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function _beforeWithdraw(
        address withdrawer,
        address receiver,
        address token,
        uint256 amount
    ) internal override returns (uint256) {
        if (withdrawer != _owner && receiver != _owner) revert NotOwner();
        uint256 fees = (amount * _fees) / 10000;
        if (token == address(0)) {
            (bool success, ) = _manager.call{value: fees}("");
            if (!success) revert TransferFailed();
        } else {
            bool success = IERC20(token).transfer(_manager, fees);
            if (!success) revert TransferFailed();
        }
        return amount - fees;
    }
}