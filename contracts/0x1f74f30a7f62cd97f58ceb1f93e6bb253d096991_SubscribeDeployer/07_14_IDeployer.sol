// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * @title IDeployer
 * @author CyberConnect
 */
interface IDeployer {
    /**
     * @notice Parameters when constructing a Content, Essence or W3ST.
     *
     * @return engine The engine address.
     */
    function params() external view returns (address engine);

    /**
     * @notice Deploy a new Essence.
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param engine The CyberEngine address.
     *
     * @return addr The deployed essence address.
     */
    function deployEssence(
        bytes32 salt,
        address engine
    ) external returns (address addr);

    /**
     * @notice Deploy a new Content
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param engine The CyberEngine address.
     *
     * @return addr The deployed content address.
     */
    function deployContent(
        bytes32 salt,
        address engine
    ) external returns (address addr);

    /**
     * @notice Deploy a new W3ST
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param engine The CyberEngine address.
     *
     * @return addr The deployed W3ST address.
     */
    function deployW3st(
        bytes32 salt,
        address engine
    ) external returns (address addr);
}