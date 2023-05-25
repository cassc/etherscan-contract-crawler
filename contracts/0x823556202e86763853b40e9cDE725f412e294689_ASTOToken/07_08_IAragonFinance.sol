// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IAragonFinance {
    /**
     * @notice Deposit token `_token` to AragonDAO Finance with amout: `_amount`. Reference: `_reference`
     * param _token The token address to be deposited
     * param _amount The amount of token to be deposited
     * param _reference The reference message
     */
    function deposit(
        address _token,
        uint256 _amount,
        string calldata _reference
    ) external;
}