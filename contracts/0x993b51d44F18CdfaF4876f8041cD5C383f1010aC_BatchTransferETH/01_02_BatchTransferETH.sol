// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BatchTransferETH {
    function batchTransferETH(
        address[] memory receivers, uint256[] memory amounts
    ) public payable {
        require(receivers.length != 0, "Receiver invalid");
        require(receivers.length == amounts.length, "Mismatch");

        for (uint256 i = 0; i < receivers.length; i++) {
            payable(receivers[i]).transfer(amounts[i]);
        }
    }

    function batchTransferERC20(
        address[] memory receivers, uint256[] memory amounts,
        address token
    ) public {
        require(receivers.length != 0, "Receiver invalid");
        require(receivers.length == amounts.length, "Mismatch");

        for (uint256 i = 0; i < receivers.length; i++) {
            IERC20(token).transferFrom(msg.sender, receivers[i], amounts[i]);
        }
    }
}