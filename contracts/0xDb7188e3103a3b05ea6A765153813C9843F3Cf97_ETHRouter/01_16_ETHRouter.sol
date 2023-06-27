// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LendingVault} from "../src/vaults/LendingVault.sol";
import {Address} from "@openzeppelin/utils/Address.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";

contract ETHRouter {
    IERC20 public immutable weth;
    LendingVault public immutable lendingVault;

    constructor(LendingVault _lendingVault, IERC20 _weth) {
        lendingVault = _lendingVault;
        weth = _weth;
        _weth.approve(address(lendingVault), type(uint256).max);
    }

    /// @notice All of the ETH sent to this contract will be sent to the `WETH`
    /// contract for it to be wrapped and subsequently deposited into the
    /// `LendingVault` in favor of the user.
    receive() external payable {
        // 1. Wrap the ETH by sending it to the WETH contract.
        Address.sendValue(payable(address(weth)), msg.value);
        // 2. Deposit that same amount to the vault in benefit of the sender.
        lendingVault.deposit(msg.value, msg.sender);
    }
}