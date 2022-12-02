// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./_external/IERC20Metadata.sol";

interface IVotingVaultController {
    function _CappedToken_underlying(address capToken)
        external
        view
        returns (address underlying);

    function _underlying_CappedToken(address underlying)
        external
        view
        returns (address capToken);

    function mintVault(uint96 id) external returns (address);

    function votingVaultId(address voting_vault_address)
        external
        view
        returns (uint96);

    function vaultId(address vault_address) external view returns (uint96);

    function votingVaultAddress(uint96 vault_id)
        external
        view
        returns (address);

    function _vaultId_votingVaultAddress(uint96 vaultID)
        external
        view
        returns (address);
}