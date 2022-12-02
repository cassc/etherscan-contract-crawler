// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

interface IVotingVault {
    /// @notice this struct is used to store the vault metadata
    /// this should reduce the cost of minting by ~15,000
    /// by limiting us to max 2**96-1 vaults
    struct VaultInfo {
        uint96 id;
        address vault_address;
    }

    function _vaultInfo() external view returns (VaultInfo memory);

    function id() external view returns (uint96);
    function delegateCompLikeTo(address delegatee, address token_address) external;
}