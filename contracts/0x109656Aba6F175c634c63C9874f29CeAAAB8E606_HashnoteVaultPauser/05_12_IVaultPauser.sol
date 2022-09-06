// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IVaultPauser {
    /// @notice pause vault position of an account with max amount
    /// @param _account the address of user
    /// @param _amount amount of shares
    function pausePosition(address _account, uint256 _amount) external;

    /// @notice resume vault position of an account with max amount
    /// @param _vaultAddress the address of vault
    function resumePositionOrWithdraw(address _vaultAddress, address _destination) external;
}