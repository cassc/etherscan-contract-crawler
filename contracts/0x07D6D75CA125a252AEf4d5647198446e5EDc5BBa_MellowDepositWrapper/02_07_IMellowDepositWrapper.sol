// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

interface IMellowDepositWrapper {
    /// @notice The function of depositing the amount of tokens in exchange
    /// @param erc20RootVaultAddress Address of the ERC20 Root Vault on Mellow
    /// @param minLpTokens Minimal value of LP tokens
    /// @param vaultOptions Options of vaults
    /// @return actualTokenAmounts Arrays of actual token amounts after deposit
    function deposit(
         address erc20RootVaultAddress,
        uint256 minLpTokens,
        bytes memory vaultOptions
    ) external payable returns (uint256[] memory actualTokenAmounts);
}