// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "./AccessControlled.sol";

contract Treasury is AccessControlled {
    address public payoutAddress;

    constructor(address accessController_) AccessControlled(accessController_) {}

    function setPayoutAddress(address payoutAddress_) external onlyAdmin {
        if (payoutAddress_ == address(0)) revert Errors.NullAddressNotAllowed();
        payoutAddress = payoutAddress_;
    }

    function withdraw(uint256 amount) external {
        withdraw(amount, address(0));
    }

    function withdraw(uint256 amount, address token) public onlyAdmin {
        if (payoutAddress == address(0)) revert Errors.PayoutAddressNotSet();
        if (token == address(0)) {
            if (amount == 0) amount = address(this).balance;
            (bool success, ) = payable(payoutAddress).call{value: amount}("");
            if (!success) revert Errors.TransferFailed();
        } else {
            IERC20 tokenContract = IERC20(token);
            if (amount == 0) amount = tokenContract.balanceOf(address(this));
            tokenContract.transfer(payoutAddress, amount);
        }
    }

    receive() external payable {}
}