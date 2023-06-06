// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import { ICurrencyReceiver } from "./interfaces/ICurrencyReceiver.sol";

contract CurrencyReceiver is ICurrencyReceiver, AccessControl {

    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public constant REFUND_ROLE = keccak256("REFUND_ROLE");

    using SafeERC20 for IERC20;

    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WITHDRAW_ROLE, msg.sender);
        _setupRole(REFUND_ROLE, msg.sender);
        _setRoleAdmin(WITHDRAW_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(REFUND_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function pay(
        address currency,
        uint256 amount,
        string calldata orderId
    ) external override {
        require(currency != address(0),"currency fail");
        require(amount > 0 ,"amount fail");
        IERC20(currency).safeTransferFrom(msg.sender,address(this),amount);
        emit Pay(currency,msg.sender,amount,orderId);
    }

    function withdraw(
        address[] calldata currency,
        uint256[] calldata amount,
        address[] calldata to,
        string[] calldata billId
    ) external override onlyRole(WITHDRAW_ROLE) {
        require(currency.length > 0,"currency fail");
        require(currency.length == amount.length,"currency or amount fail");

        for(uint256 i=0;i<currency.length;i++) {
            require(amount[i] > 0, "amount fail");
            IERC20(currency[i]).safeTransfer(to[i],amount[i]);
            emit Withdraw(currency[i],amount[i],to[i],billId[i]);
        }
        
    }

    function refund(
        address[] calldata currency,
        uint256[] calldata amount,
        address[] calldata to,
        string[] calldata orderId
    ) external override onlyRole(REFUND_ROLE) {

        require(currency.length > 0,"currency fail");
        require(currency.length == amount.length,"amount fail");
        require(currency.length == to.length,"to fail");
        require(currency.length == orderId.length,"orderId fail");

        for(uint256 i=0;i<currency.length;i++) {
            require(amount[i] > 0, "amount fail");
            IERC20(currency[i]).safeTransfer(to[i],amount[i]);
            emit Refund(currency[i],amount[i],to[i],orderId[i]);
        }
        
    }

    function balanceOf(
        address currency
    ) external view override returns (uint256) {
        require(currency != address(0),"currency fail");
        return IERC20(currency).balanceOf(address(this));
    }

}