// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BulkTransfer{
    function bulkTransfer(
        address _token,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external {
        require(accounts.length < 201, "Maxlimit of requests");
        require(
            accounts.length == amounts.length,
            "Invalid number of requests"
        );
        require(_token != address(0), "Invalid token address");
        IERC20 token = IERC20(_token);

        uint256 i = 0;
        for (i; i < accounts.length; i++) {
            token.transferFrom(msg.sender, accounts[i], amounts[i]);
        }
    }
}