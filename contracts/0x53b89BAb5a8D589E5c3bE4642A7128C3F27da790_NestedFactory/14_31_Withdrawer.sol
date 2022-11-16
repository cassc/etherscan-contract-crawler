// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

import "./interfaces/external/IWETH.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Native token withdrawer
/// @dev Withdraw native token from the wrapper contract on behalf
///      of the sender. Upgradeable proxy contracts are not able to receive
///      native tokens from contracts via `transfer` (EIP1884), they need a
///      middleman forwarding all available gas and reverting on errors.
contract Withdrawer is ReentrancyGuard {
    IWETH public immutable weth;

    constructor(IWETH _weth) {
        weth = _weth;
    }

    receive() external payable {
        require(msg.sender == address(weth), "WD: ETH_SENDER_NOT_WETH");
    }

    /// @notice Withdraw native token from wrapper contract
    /// @param amount The amount to withdraw
    function withdraw(uint256 amount) external nonReentrant {
        weth.transferFrom(msg.sender, address(this), amount);
        weth.withdraw(amount);
        Address.sendValue(payable(msg.sender), amount);
    }
}