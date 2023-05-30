// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC677 is IERC20 {
    /**
     * @dev transfer token to a contract address with additional data if the recipient is a contact.
     * @param recipient The address to transfer to.
     * @param amount The amount to be transferred.
     * @param data The extra data to be passed to the receiving contract.
     */
    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes memory data
    ) external returns (bool success);

    event TransferAndCall(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );
}