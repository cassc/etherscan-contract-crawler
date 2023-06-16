// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./PermissionsV2.sol";

abstract contract WithdrawableV2 is PermissionsV2 {
    using SafeERC20 for IERC20;

    event EtherWithdraw(uint256 amount, address sendTo);
    event TokenWithdraw(IERC20 token, uint256 amount, address sendTo);

    /**
     * @dev Allows governance to withdraw Ether in a Pendle contract
     *      in case of accidental ETH transfer into the contract.
     * @param amount The amount of Ether to withdraw.
     * @param sendTo The recipient address.
     */
    function withdrawEther(uint256 amount, address payable sendTo) external onlyGovernance {
        (bool success, ) = sendTo.call{value: amount}("");
        require(success, "WITHDRAW_FAILED");
        emit EtherWithdraw(amount, sendTo);
    }

    /**
     * @dev Allows governance to withdraw all IERC20 compatible tokens in a Pendle
     *      contract in case of accidental token transfer into the contract.
     * @param token IERC20 The address of the token contract.
     * @param amount The amount of IERC20 tokens to withdraw.
     * @param sendTo The recipient address.
     */
    function withdrawToken(
        IERC20 token,
        uint256 amount,
        address sendTo
    ) external onlyGovernance {
        require(_allowedToWithdraw(address(token)), "TOKEN_NOT_ALLOWED");
        token.safeTransfer(sendTo, amount);
        emit TokenWithdraw(token, amount, sendTo);
    }

    // must be overridden by the sub contracts, so we must consider explicitly
    // in each and every contract which tokens are allowed to be withdrawn
    function _allowedToWithdraw(address) internal view virtual returns (bool allowed);
}