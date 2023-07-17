// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiTransferERC20Token {
    using SafeERC20 for IERC20;

    /// @notice Send ERC20 tokens and Ether to multiple addresses
    ///  using three arrays which includes the address and the amounts.
    ///
    /// @param token The token to send
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of token amounts to send
    function multiTransferToken(
        IERC20 token,
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external {
        require(_addresses.length == _amounts.length, "405");

        for (uint i; i < _addresses.length; i++) {
            token.safeTransferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }
}