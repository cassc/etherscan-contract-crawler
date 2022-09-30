//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGatewayRegistry} from "@renproject/gateway-sol/src/GatewayRegistry/interfaces/IGatewayRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Payment, FEE_CURRENCY} from "./libraries/Payment.sol";

contract Lender is Context, AccessControlEnumerable, Payment {
    using SafeERC20 for IERC20;

    event Lent();
    event Repayed();

    bytes32 public constant LENDER_ADMIN = keccak256("LENDER_ADMIN");
    bytes32 public constant FUNDS_ADMIN = keccak256("FUNDS_ADMIN");

    mapping(bytes32 => uint256) public loans;

    constructor(address roleAdminAddress) payable {
        AccessControlEnumerable._grantRole(
            AccessControl.DEFAULT_ADMIN_ROLE,
            roleAdminAddress
        );
        AccessControlEnumerable._grantRole(FUNDS_ADMIN, roleAdminAddress);
    }

    function deposit(address erc20, uint256 amount) external payable {
        if (erc20 == FEE_CURRENCY) {
            require(msg.value == amount, "Lender: insufficient msg.value");
        } else {
            IERC20(erc20).safeTransferFrom(_msgSender(), address(this), amount);
        }
    }

    function withdraw(address erc20, uint256 amount) external {
        require(hasRole(LENDER_ADMIN, _msgSender()), "Lender: not funds admin");
        payToken(_msgSender(), erc20, amount);
    }

    function borrow(
        address token,
        bytes32 borrower,
        uint256 amount
    ) external returns (uint256) {
        require(
            hasRole(LENDER_ADMIN, _msgSender()),
            "Lender: not lender admin"
        );
        loans[borrower] += amount;
        if (token == FEE_CURRENCY) {
            payable(address(_msgSender())).transfer(amount);
        } else {
            IERC20(token).safeTransfer(_msgSender(), amount);
        }
        return amount;
    }

    function repay(
        address erc20,
        bytes32 borrower,
        uint256 amount
    ) external payable returns (uint256) {
        require(
            hasRole(LENDER_ADMIN, _msgSender()),
            "Lender: not lender admin"
        );

        uint256 change = 0;
        if (amount > loans[borrower]) {
            change = amount - loans[borrower];
            loans[borrower] = 0;
        } else {
            loans[borrower] -= amount;
        }

        if (erc20 == FEE_CURRENCY) {
            require(amount == msg.value, "Lender: insufficient msg.value");
            if (change > 0) {
                payable(_msgSender()).transfer(change);
            }
        } else {
            IERC20(erc20).safeTransferFrom(
                _msgSender(),
                address(this),
                amount - change
            );
        }
        return change;
    }
}