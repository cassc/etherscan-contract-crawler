/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Policy.sol";
import "./PolicedUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** @title Policy initialization contract
 *
 * This contract is used to configure a policy contract immediately after
 * construction as the target of a proxy. It sets up permissions for other
 * contracts and makes future initialization impossible.
 */
contract PolicyInit is Policy, Ownable {
    /** Initialize and fuse future initialization of a policy contract
     *
     * @param _policy The address of the policy contract to replace this one.
     * @param _setters The interface identifiers for privileged contracts. The
     *                 contracts registered at these identifiers will be able to
     *                 execute code in the context of the policy contract.
     * @param _keys The identifiers for associated governance contracts.
     * @param _values The addresses of associated governance contracts (must
     *                align with _keys).
     */
    function fusedInit(
        Policy _policy,
        bytes32[] calldata _setters,
        bytes32[] calldata _keys,
        address[] calldata _values
    ) external onlyOwner {
        require(
            _keys.length == _values.length,
            "_keys and _values must correspond exactly (length)"
        );

        setImplementation(address(_policy));

        // attribute all the identifier hashes to their addresses
        for (uint256 i = 0; i < _keys.length; ++i) {
            ERC1820REGISTRY.setInterfaceImplementer(
                address(this),
                _keys[i],
                _values[i]
            );
        }

        // store which hashes have setter privileges
        for (uint256 i = 0; i < _setters.length; ++i) {
            setters[_setters[i]] = true;
        }
    }

    constructor() Ownable() {
        //calling parent ownable constructor
    }

    /** Initialize the contract on a proxy
     *
     * @param _self The address of the original contract deployment (as opposed
     *              to the address of the proxy contract, which takes the place
     *              of `this`).
     */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);
        _transferOwnership(Ownable(_self).owner());
    }
}