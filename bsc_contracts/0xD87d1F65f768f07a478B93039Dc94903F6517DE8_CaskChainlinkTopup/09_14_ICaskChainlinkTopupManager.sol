// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICaskChainlinkTopupManager {

    enum SwapProtocol {
        UNIV2,
        UNIV3,
        GMX
    }

    function registerChainlinkTopup(bytes32 _chainlinkTopupId) external;

    function registryAllowed(address _registry) external view returns(bool);

    /** @dev Emitted the feeDistributor is changed. */
    event SetFeeDistributor(address feeDistributor);

    /** @dev Emitted when a registry is allowed. */
    event RegistryAllowed(address registry);

    /** @dev Emitted when a registry is disallowed. */
    event RegistryDisallowed(address registry);

    /** @dev Emitted when manager parameters are changed. */
    event SetParameters();

    /** @dev Emitted when chainlink addresses are changed. */
    event SetChainlinkAddresses();
}