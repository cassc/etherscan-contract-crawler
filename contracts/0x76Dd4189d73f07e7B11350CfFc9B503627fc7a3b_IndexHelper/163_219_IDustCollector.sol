// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./IBaseErrors.sol";

interface IDustCollector is IBaseErrors {
    /// @notice Emitted when dust is sent
    /// @param _to The address which wil received the funds
    /// @param _token The token that will be transferred
    /// @param _amount The amount of the token that will be transferred
    event DustSent(address _token, uint256 _amount, address _to);

    /// @notice Allows an authorized user to transfer the tokens or eth that may have been left in a contract
    /// @param _token The token that will be transferred
    /// @param _amount The amount of the token that will be transferred
    /// @param _to The address that will receive the idle funds
    function sendDust(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}