// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";

import { ICyberEngineEvents } from "../interfaces/ICyberEngineEvents.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngine is ICyberEngineEvents {
    /**
     * @notice Initializes the CyberEngine.
     *
     * @param _owner Owner to set for CyberEngine.
     * @param _rolesAuthority RolesAuthority address to manage access control
     */
    function initialize(address _owner, RolesAuthority _rolesAuthority)
        external;

    /**
     * @notice Allows the profile middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowProfileMw(address mw, bool allowed) external;

    /**
     * @notice Allows the subscriber middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowSubscribeMw(address mw, bool allowed) external;

    /**
     * @notice Allows the essence middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowEssenceMw(address mw, bool allowed) external;

    /**
     * @notice Creates a new namespace.
     *
     * @param params The namespace params:
     *  name: The namespace name.
     *  symbol: The namespace symbol.
     *  owner: The namespace owner.
     * @return profileProxy The profile proxy address.
     * @return subBeacon The Subscribe beacon address.
     * @return essBeacon The Essence beacon address.
     */
    function createNamespace(DataTypes.CreateNamespaceParams calldata params)
        external
        returns (
            address profileProxy,
            address subBeacon,
            address essBeacon
        );

    /**
     * @notice Upgrade SubscribeNFT to new version by namespace.
     *
     * @param newImpl The new SubscribeNFT implementation address.
     * @param namespace The namespace to upgrade.
     */
    function upgradeSubscribeNFT(address newImpl, address namespace) external;

    /**
     * @notice Upgrade EssenceNFT to new version by namespace.
     *
     * @param newImpl The new EssenceNFT implementation address.
     * @param namespace The namespace to upgrade.
     */
    function upgradeEssenceNFT(address newImpl, address namespace) external;

    /**
     * @notice Upgrade ProfileNFT to new version.
     *
     * @param newImpl The new ProfileNFT implementation address.
     * @param namespace The namespace to upgrade.
     */
    function upgradeProfileNFT(address newImpl, address namespace) external;

    /**
     * @notice Sets the profile middleware.
     *
     * @param namespace The namespace address.
     * @param mw The middleware address.
     * @param data The middleware data.
     * @dev the profile middleware needs to be allowed first.
     */
    function setProfileMw(
        address namespace,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Gets the profile name by the namespace.
     *
     * @param namespace The namespace address.
     * @return string The profile name.
     */
    function getNameByNamespace(address namespace)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile middleware by the namespace.
     *
     * @param namespace The namespace address.
     * @return address The middleware name.
     */
    function getProfileMwByNamespace(address namespace)
        external
        view
        returns (address);

    /**
     * @notice Checks if the essence middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isEssenceMwAllowed(address mw) external view returns (bool);

    /**
     * @notice Checks if the subscriber middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isSubscribeMwAllowed(address mw) external view returns (bool);

    /**
     * @notice Checks if the profile middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isProfileMwAllowed(address mw) external view returns (bool);
}