// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * @title ISubscribeDeployer
 * @author CyberConnect
 */
interface ISubscribeDeployer {
    /**
     * @notice Parameters when constructing a Content, Essence or W3ST.
     *
     * @return engine The engine address.
     */
    function params() external view returns (address engine);

    /**
     * @notice Deploy a new Subscribe
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param engine The CyberEngine address.
     *
     * @return addr The deployed Subscribe address.
     */
    function deploySubscribe(
        bytes32 salt,
        address engine
    ) external returns (address addr);
}