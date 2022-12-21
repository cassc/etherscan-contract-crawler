// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Withdrawable
 * @dev Allows for a contract to be withdrawable in native and token balance.
 * @author Phat Loot DeFi Developers
 * @custom:version 1.0
 * @custom:date 20 April 2022
 */
abstract contract Withdrawable is AccessControl {
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    constructor() {
        _setupRole(WITHDRAW_ROLE, msg.sender);
    }

    function withdrawToken(address tokenContractAddress, uint256 amount) external onlyRole(WITHDRAW_ROLE) {
        IERC20 tokenContract = IERC20(tokenContractAddress);
        SafeERC20.safeTransfer(tokenContract, msg.sender, amount);
    }

    function withdrawNative(uint256 amount) external onlyRole(WITHDRAW_ROLE) {
        payable(msg.sender).transfer(amount);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}