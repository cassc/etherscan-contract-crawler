// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library P2pAddressLib {
    /// @notice Sends amount of ETH in wei to recipient
    /// @param _recipient address of recipient
    /// @param _amount amount of ETH in wei
    /// @return bool whether send succeeded
    function _sendValue(address payable _recipient, uint256 _amount) internal returns (bool) {
        (bool success, ) = _recipient.call{
            value: _amount,
            gas: gasleft() / 4 // to prevent DOS, should be enough in normal cases
        }("");

        return success;
    }

    /// @notice Sends amount of ETH in wei to recipient
    /// @param _recipient address of recipient
    /// @param _amount amount of ETH in wei
    /// @return bool whether send succeeded
    function _sendValueWithoutGasRestrictions(address payable _recipient, uint256 _amount) internal returns (bool) {
        (bool success, ) = _recipient.call{
            value: _amount
        }("");

        return success;
    }
}