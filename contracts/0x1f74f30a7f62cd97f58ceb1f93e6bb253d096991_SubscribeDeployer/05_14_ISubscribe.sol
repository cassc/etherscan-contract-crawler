// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * @title ISubscribe
 * @author CyberConnect
 */
interface ISubscribe {
    /**
     * @notice Mints the Subscribe.
     *
     * @param to The recipient address.
     * @param to The duration with unit Day.
     * @return uint256 The token id.
     */
    function mint(address to, uint256 durationDay) external returns (uint256);

    /**
     * @notice Initializes the Subscribe NFT.
     *
     * @param account The account address for the Subscribe NFT.
     * @param name The name for the Subscribe NFT.
     * @param symbol The symbol for the Subscribe NFT.
     */
    function initialize(
        address account,
        string calldata name,
        string calldata symbol
    ) external;

    /**
     * @notice Extends the Subscribe NFT.
     *
     * @param account The account address for the Subscribe NFT.
     * @param durationDay The duration with unit Day.
     * @return uint256 The token id.
     */
    function extend(
        address account,
        uint256 durationDay
    ) external returns (uint256);
}