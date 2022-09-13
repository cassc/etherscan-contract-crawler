// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IEssenceMiddleware {
    /**
     * @notice Sets essence related data for middleware.
     *
     * @param profileId The profile id that owns this middleware.
     * @param essenceId The essence id that owns this middleware.
     * @param data Extra data to set.
     */
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Process that runs before the essenceNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param essenceId The essence Id.
     * @param collector The collector address.
     * @param essenceNFT The essence nft address.
     * @param data Extra data to process.
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address essenceNFT,
        bytes calldata data
    ) external;

    /**
     * @notice Process that runs after the essenceNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param essenceId The essence Id.
     * @param collector The collector address.
     * @param essenceNFT The essence nft address.
     * @param data Extra data to process.
     */
    function postProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address essenceNFT,
        bytes calldata data
    ) external;
}