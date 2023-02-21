// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "../proxy/ForwardTarget.sol";
import "./ERC1820Client.sol";

/** @title The policy contract that oversees other contracts
 *
 * Policy contracts provide a mechanism for building pluggable (after deploy)
 * governance systems for other contracts.
 */
contract Policy is ForwardTarget, ERC1820Client {
    mapping(bytes32 => bool) public setters;

    modifier onlySetter(bytes32 _identifier) {
        require(
            setters[_identifier],
            "Identifier hash is not authorized for this action"
        );

        require(
            ERC1820REGISTRY.getInterfaceImplementer(
                address(this),
                _identifier
            ) == msg.sender,
            "Caller is not the authorized address for identifier"
        );

        _;
    }

    /** Remove the specified role from the contract calling this function.
     * This is for cleanup only, so if another contract has taken the
     * role, this does nothing.
     *
     * @param _interfaceIdentifierHash The interface identifier to remove from
     *                                 the registry.
     */
    function removeSelf(bytes32 _interfaceIdentifierHash) external {
        address old = ERC1820REGISTRY.getInterfaceImplementer(
            address(this),
            _interfaceIdentifierHash
        );

        if (old == msg.sender) {
            ERC1820REGISTRY.setInterfaceImplementer(
                address(this),
                _interfaceIdentifierHash,
                address(0)
            );
        }
    }

    /** Find the policy contract for a particular identifier.
     *
     * @param _interfaceIdentifierHash The hash of the interface identifier
     *                                 look up.
     */
    function policyFor(bytes32 _interfaceIdentifierHash)
        public
        view
        returns (address)
    {
        return
            ERC1820REGISTRY.getInterfaceImplementer(
                address(this),
                _interfaceIdentifierHash
            );
    }

    /** Set the policy label for a contract
     *
     * @param _key The label to apply to the contract.
     *
     * @param _implementer The contract to assume the label.
     */
    function setPolicy(
        bytes32 _key,
        address _implementer,
        bytes32 _authKey
    ) public onlySetter(_authKey) {
        ERC1820REGISTRY.setInterfaceImplementer(
            address(this),
            _key,
            _implementer
        );
    }

    /** Enact the code of one of the governance contracts.
     *
     * @param _delegate The contract code to delegate execution to.
     */
    function internalCommand(address _delegate, bytes32 _authKey)
        public
        onlySetter(_authKey)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = _delegate.delegatecall(
            abi.encodeWithSignature("enacted(address)", _delegate)
        );
        require(_success, "Command failed during delegatecall");
    }
}