//SPDX-License-Identifier: MIT
pragma solidity >=0.7.5 <0.9.0;

/// @dev when modifying this contract, please copy all to MigrationPoolsV8
interface IMigrationReceiver {

    /// @dev should use onlyPool modifier
    ///         this method is responsible for "accepting" tokens from other pool to our
    function migrateTokenCallback(address _token, address _user, uint256 _amount, bytes calldata _data) external;
}