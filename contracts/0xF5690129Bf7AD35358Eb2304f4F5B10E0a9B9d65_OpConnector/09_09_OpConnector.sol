//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IL1StandardBridge} from "@eth-optimism/contracts/L1/messaging/IL1StandardBridge.sol";

contract OpConnector is Ownable {
    using SafeERC20 for IERC20;

    address public immutable l1Token;
    address public immutable l2Token;
    address public immutable target;
    address public immutable l1BridgeAddr;

    event LogDeposit(address indexed caller, address destination, uint256 amount);

    constructor(
        address _l1Token,
        address _l2Token,
        address _target,
        address _l1BridgeAddr
    ) {
        l1Token = _l1Token;
        l2Token = _l2Token;
        target = _target;
        l1BridgeAddr = _l1BridgeAddr;
    }

    function bridge() external {
        uint256 amount = IERC20(l1Token).balanceOf(address(this));
        require(amount > 0, "OpConnector: Amount zero");
        uint256 currentAllowance = IERC20(l1Token).allowance(address(this), l1BridgeAddr);
        if (currentAllowance < type(uint256).max) {
            // Approve the allowance once for all
            IERC20(l1Token).safeIncreaseAllowance(l1BridgeAddr, type(uint256).max - currentAllowance);
        }
        IL1StandardBridge(l1BridgeAddr).depositERC20To(
            l1Token,
            l2Token,
            target,
            amount,
            1000000, // within the free gas limit amount
            ""
        );

        emit LogDeposit(msg.sender, target, amount);
    }

    function claimTokens(address recipient) external onlyOwner {
        require(recipient != address(0), "OpConnector: Recipient null");

        uint256 balance = IERC20(l1Token).balanceOf(address(this));
        require(balance > 0, "OpConnector: Amount zero");

        IERC20(l1Token).safeTransfer(recipient, balance);
    }
}