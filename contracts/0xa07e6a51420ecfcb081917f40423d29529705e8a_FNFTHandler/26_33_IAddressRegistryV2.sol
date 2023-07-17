// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IAddressRegistry.sol";

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistryV2 is IAddressRegistry {

        function initialize_with_legacy(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address legacy_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getLegacyTokenVault() external view returns (address legacy);

    function setLegacyTokenVault(address legacyVault) external;

    function breakGlass() external;

    function pauseToken() external;

    function unpauseToken() external;

    function modifyPauser(address pauser, bool grant) external;

    function modifyBreaker(address breaker, bool grant) external;
}