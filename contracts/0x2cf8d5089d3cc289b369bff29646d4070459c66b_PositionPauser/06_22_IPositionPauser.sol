// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPositionPauser {
    /// @notice pause vault position of an account with max amount
    /// @param _account the address of user
    /// @param _amount amount of shares
    function pausePosition(address _account, uint256 _amount) external;

    /// @notice processes all pending withdrawals
    /// @param _balances of assets transfered to pauser
    function processVaultWithdraw(uint256[] calldata _balances) external;

    /// @notice user withdraws collateral
    /// @param _vault the address of vault
    /// @param _destination the address of the recipient
    function withdrawCollaterals(address _vault, address _destination) external;
}