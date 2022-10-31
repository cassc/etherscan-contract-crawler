// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Implementer.sol";
import "../proxy/ForwardTarget.sol";
import "./Policy.sol";

/** @title Policed Contracts
 *
 * A policed contract is any contract managed by a policy.
 */
abstract contract Policed is ForwardTarget, IERC1820Implementer, ERC1820Client {
    bytes32 internal constant ERC1820_ACCEPT_MAGIC =
        keccak256("ERC1820_ACCEPT_MAGIC");

    /** The address of the root policy instance overseeing this instance.
     *
     * This address can be used for ERC1820 lookup of other components, ERC1820
     * lookup of role policies, and interaction with the policy hierarchy.
     */
    Policy public immutable policy;

    /** Restrict method access to the root policy instance only.
     */
    modifier onlyPolicy() {
        require(
            msg.sender == address(policy),
            "Only the policy contract may call this method"
        );
        _;
    }

    constructor(Policy _policy) {
        require(
            address(_policy) != address(0),
            "Unrecoverable: do not set the policy as the zero address"
        );
        policy = _policy;
        ERC1820REGISTRY.setManager(address(this), address(_policy));
    }

    /** ERC1820 permissioning interface
     *
     * @param _addr The address of the contract we might act on behalf of.
     */
    function canImplementInterfaceForAddress(bytes32, address _addr)
        external
        view
        virtual
        override
        returns (bytes32)
    {
        require(
            _addr == address(policy),
            "This contract only implements interfaces for the policy contract"
        );
        return ERC1820_ACCEPT_MAGIC;
    }

    /** Initialize the contract (replaces constructor)
     *
     * Policed contracts are often the targets of proxies, and therefore need a
     * mechanism to initialize internal state when adopted by a new proxy. This
     * replaces the constructor.
     *
     * @param _self The address of the original contract deployment (as opposed
     *              to the address of the proxy contract, which takes the place
     *              of `this`).
     */
    function initialize(address _self)
        public
        virtual
        override
        onlyConstruction
    {
        super.initialize(_self);
        ERC1820REGISTRY.setManager(address(this), address(policy));
    }

    /** Execute code as indicated by the managing policy contract
     *
     * We allow the managing policy contract to execute arbitrary code in our
     * context by allowing it to specify an implementation address and some
     * message data, and then using delegatecall to execute the code at the
     * implementation address, passing in the message data, all within our
     * own address space.
     *
     * @param _delegate The address of the contract to delegate execution to.
     * @param _data The call message/data to execute on.
     */
    function policyCommand(address _delegate, bytes memory _data)
        public
        onlyPolicy
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /* Call the address indicated by _delegate passing the data in _data
             * as the call message using delegatecall. This allows the calling
             * of arbitrary functions on _delegate (by encoding the call message
             * into _data) in the context of the current contract's storage.
             */
            let result := delegatecall(
                gas(),
                _delegate,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            /* Collect up the return data from delegatecall and prepare it for
             * returning to the caller of policyCommand.
             */
            let size := returndatasize()
            returndatacopy(0x0, 0, size)
            /* If the delegated call reverted then revert here too. Otherwise
             * forward the return data prepared above.
             */
            switch result
            case 0 {
                revert(0x0, size)
            }
            default {
                return(0x0, size)
            }
        }
    }
}