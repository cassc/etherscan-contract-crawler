// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngineEvents {
    /**
     * @notice Emiited when the engine is initialized
     *
     * @param owner The address of the engine owner.
     * @param rolesAuthority The address of the role authority.
     */
    event Initialize(address indexed owner, address indexed rolesAuthority);

    /**
     * @notice Emitted when a profile middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowProfileMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a profile middleware has been set.
     *
     * @param namespace The namespace address.
     * @param mw The middleware address.
     * @param returnData The profile middeware data.
     */
    event SetProfileMw(address indexed namespace, address mw, bytes returnData);

    /**
     * @notice Emitted when a subscription middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowSubscribeMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a essence middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowEssenceMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a namespace has been created
     *
     * @param namespace The namespace address.
     * @param name The namespace name.
     * @param symbol The namespace symbol.
     */
    event CreateNamespace(
        address indexed namespace,
        string name,
        string symbol
    );
}