// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";

import { IERC20 } from "../interfaces/IERC20.sol";
import { SafeERC20 } from "../libraries/SafeERC20.sol";

error NotRoleOwner(address);
error WrongShareAmount();

contract PaymentSplitter is Context {
    using SafeERC20 for IERC20;

    struct ShareRequest {
        uint8 ownerSideOwnerShare;
        uint8 devSideOwnerShare;
    }

    enum Roles {
        owner,
        dev
    }

    address payable public ownerAddress;
    address payable public devAddress;

    uint8 public ownerShare;

    ShareRequest public changeShareRequest;

    constructor(address payable _ownerAddress, address payable _devAddress, uint8 _ownerShare) {
        ownerAddress = _ownerAddress;
        devAddress = _devAddress;
        ownerShare = _ownerShare;
    }

    function changeAccount(address payable account, Roles role) external {
        if (role == Roles.owner) {
            if (_msgSender() != ownerAddress) revert NotRoleOwner(ownerAddress);
            ownerAddress = account;
        } else if (role == Roles.dev) {
            if (_msgSender() != devAddress) revert NotRoleOwner(devAddress);
            devAddress = account;
        }
    }

    function changeOwnerShare(uint8 share) external {
        if (share >= 100) revert WrongShareAmount();

        address from = _msgSender();
        if (from == ownerAddress) {
            changeShareRequest.ownerSideOwnerShare = share;
        } else if (from == devAddress) {
            changeShareRequest.devSideOwnerShare = share;
        } else {
            revert NotRoleOwner(from);
        }

        if (changeShareRequest.ownerSideOwnerShare == changeShareRequest.devSideOwnerShare) {
            ownerShare = share;
        }
    }

    function calculateAmounts(uint256 amount) private view returns(uint256 ownerAmount, uint256 devAmount) {
        ownerAmount = amount * ownerShare / 100;
        devAmount = amount - ownerAmount;
    }

    function splitPayment() internal {
        uint256 amount = address(this).balance;

        (uint256 ownerAmount, uint256 devAmount) = calculateAmounts(amount);

        (bool successOwner, ) = ownerAddress.call{ value: ownerAmount }("");
        (bool successDev, ) = devAddress.call{ value: devAmount }("");
        require(successOwner && successDev, "");
    }

    function splitPayment(address token) internal {
        uint256 amount = IERC20(token).balanceOf(address(this));

        uint256 ownerAmout = amount * ownerShare / 100;
        uint256 devAmount = amount - ownerAmout;

        IERC20(token).safeTransfer(ownerAddress, ownerAmout);
        IERC20(token).safeTransfer(devAddress, devAmount);
    }
}