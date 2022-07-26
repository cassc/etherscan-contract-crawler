// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Governable} from "./Governable.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title BaseGovernedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with our governor system
 * @author Origin Protocol Inc
 */
contract GovernedUpgradeabilityProxy is Governable, ERC1967Proxy {
    /**
     * @dev Contract constructor
     * @param _logic Address of the initial implementation.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    constructor(address _logic, bytes memory _data)
        payable
        Governable()
        ERC1967Proxy(_logic, _data)
    {}

    /**
     * @return The address of the proxy admin/it's also the governor.
     */
    function admin() external view returns (address) {
        return _governor();
    }

    /**
     * @return The address of the implementation.
     */
    function implementation() external view returns (address) {
        return _implementation();
    }

    /**
     * @dev Upgrade the backing implementation of the proxy.
     * Only the admin can call this function.
     * @param newImplementation Address of the new implementation.
     */
    function upgradeTo(address newImplementation) external onlyGovernor {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy and call a function
     * on the new implementation.
     * This is useful to initialize the proxied contract.
     * @param newImplementation Address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        onlyGovernor
    {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }
}