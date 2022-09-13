// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileMiddleware {
    /**
     * @notice Sets namespace related data for middleware.
     *
     * @param namespace The related namespace address.
     * @param data Extra data to set.
     */
    function setProfileMwData(address namespace, bytes calldata data)
        external
        returns (bytes memory);

    /**
     * @notice Process that runs before the profileNFT creation happens.
     *
     * @param params The params for creating profile.
     * @param data Extra data to process.
     */
    function preProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external payable;

    /**
     * @notice Process that runs after the profileNFT creation happens.
     *
     * @param params The params for creating profile.
     * @param data Extra data to process.
     */
    function postProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external;
}