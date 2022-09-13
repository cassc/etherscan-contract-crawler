// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeMiddleware {
    /**
     * @notice Sets subscribe related data for middleware.
     *
     * @param profileId The profile id that owns this middleware.
     * @param data Extra data to set.
     */
    function setSubscribeMwData(uint256 profileId, bytes calldata data)
        external
        returns (bytes memory);

    /**
     * @notice Process that runs before the subscribeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param subscriber The subscriber address.
     * @param subscribeNFT The subscribe nft address.
     * @param data Extra data to process.
     */
    function preProcess(
        uint256 profileId,
        address subscriber,
        address subscribeNFT,
        bytes calldata data
    ) external;

    /**
     * @notice Process that runs after the subscribeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param subscriber The subscriber address.
     * @param subscribeNFT The subscribe nft address.
     * @param data Extra data to process.
     */
    function postProcess(
        uint256 profileId,
        address subscriber,
        address subscribeNFT,
        bytes calldata data
    ) external;
}