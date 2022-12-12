// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IWETH.sol";

contract WETHUnwrapper {
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    receive() external payable {}

    /// @notice Convert WETH to ETH and transfer to msg.sender
    /// @dev msg.sender needs to send WETH before calling this withdraw
    /// @param _amount amount to withdraw.
    function withdraw(uint256 _amount) external {
        IWETH(weth).withdraw(_amount);
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send ETH");
    }
}