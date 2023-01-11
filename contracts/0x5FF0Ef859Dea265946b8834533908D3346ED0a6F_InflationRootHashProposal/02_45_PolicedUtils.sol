// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

import "../clone/CloneFactory.sol";
import "./Policed.sol";
import "./ERC1820Client.sol";

/** @title Utility providing helpers for policed contracts
 *
 * See documentation for Policed to understand what a policed contract is.
 */
abstract contract PolicedUtils is Policed, CloneFactory {
    bytes32 internal constant ID_FAUCET = keccak256("Faucet");
    bytes32 internal constant ID_ECO = keccak256("ECO");
    bytes32 internal constant ID_ECOX = keccak256("ECOx");
    bytes32 internal constant ID_TIMED_POLICIES = keccak256("TimedPolicies");
    bytes32 internal constant ID_TRUSTED_NODES = keccak256("TrustedNodes");
    bytes32 internal constant ID_POLICY_PROPOSALS =
        keccak256("PolicyProposals");
    bytes32 internal constant ID_POLICY_VOTES = keccak256("PolicyVotes");
    bytes32 internal constant ID_CURRENCY_GOVERNANCE =
        keccak256("CurrencyGovernance");
    bytes32 internal constant ID_CURRENCY_TIMER = keccak256("CurrencyTimer");
    bytes32 internal constant ID_ECOXSTAKING = keccak256("ECOxStaking");

    // The minimum time of a generation.
    uint256 public constant MIN_GENERATION_DURATION = 14 days;
    // The initial generation
    uint256 public constant GENERATION_START = 1000;

    address internal expectedInterfaceSet;

    constructor(Policy _policy) Policed(_policy) {}

    /** ERC1820 permissioning interface
     *
     * @param _addr The address of the contract this might act on behalf of.
     */
    function canImplementInterfaceForAddress(bytes32, address _addr)
        external
        view
        override
        returns (bytes32)
    {
        require(
            _addr == address(policy) || _addr == expectedInterfaceSet,
            "Only the policy or interface contract can set the interface"
        );
        return ERC1820_ACCEPT_MAGIC;
    }

    /** Set the expected interface set
     */
    function setExpectedInterfaceSet(address _addr) public onlyPolicy {
        expectedInterfaceSet = _addr;
    }

    /** Create a clone of this contract
     *
     * Creates a clone of this contract by instantiating a proxy at a new
     * address and initializing it based on the current contract. Uses
     * optionality.io's CloneFactory functionality.
     *
     * This is used to save gas cost during deployments. Rather than including
     * the full contract code in every contract that might instantiate it, it
     * can be deployed once and the location it was deployed can be referred to for
     * cloning. The calls to clone() create instances as needed without
     * increasing the code size of the instantiating contract.
     */
    function clone() public virtual returns (address) {
        require(
            implementation() == address(this),
            "This method cannot be called on clones"
        );
        address _clone = createClone(address(this));
        PolicedUtils(_clone).initialize(address(this));
        return _clone;
    }

    /** Find the policy contract for a particular identifier.
     *
     * This is intended as a helper function for contracts that are managed by
     * a policy framework. A typical use case is checking if the address calling
     * a function is the authorized policy for a particular action.
     *
     * eg:
     * ```
     * function doSomethingPrivileged() public {
     *   require(
     *     msg.sender == policyFor(keccak256("PolicyForDoingPrivilegedThing")),
     *     "Only the privileged contract may call this"
     *     );
     * }
     * ```
     */
    function policyFor(bytes32 _id) internal view returns (address) {
        return ERC1820REGISTRY.getInterfaceImplementer(address(policy), _id);
    }
}