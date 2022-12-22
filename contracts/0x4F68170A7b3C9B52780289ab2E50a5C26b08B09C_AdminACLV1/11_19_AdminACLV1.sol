// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/0.8.x/IAdminACLV0.sol";
import "./GenArt721CoreV3.sol";
import "@openzeppelin-4.7/contracts/access/Ownable.sol";
import "@openzeppelin-4.7/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin-4.7/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Admin ACL contract, V1.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract has a single superAdmin that passes all ACL checks. It also
 * contains a set of payment approvers who may only call the function
 * `GenArt721CoreV3.adminAcceptArtistAddressesAndSplits`. All checks for any
 * other address will return false.
 * The superAdmin can be changed by the current superAdmin.
 * Payment approvers may only be changed by the current superAdmin.
 * Care must be taken to ensure that the admin ACL contract is secure behind a
 * multi-sig or other secure access control mechanism.
 * This contract continues to broadcast support (and require future-adminACL
 * broadcasted support) for IAdminACLV0 via ERC165 interface detection.
 */
contract AdminACLV1 is IAdminACLV0, ERC165 {
    /// New address added to set of addresses who may approve artist-proposed
    /// payment addresses.
    event PaymentApproverAdded(address indexed _approver);

    /// Address removed from set of addresses who may approve artist-proposed
    /// payment addresses.
    event PaymentApproverRemoved(address indexed _approver);

    // add Enumerable Set methods
    using EnumerableSet for EnumerableSet.AddressSet;

    string public AdminACLType = "AdminACLV1";

    /// superAdmin is the only address that passes any and all ACL checks
    address public superAdmin;

    // Set of addresses that have been granted admin approval of artist-
    // proposed payment address changes
    EnumerableSet.AddressSet private _paymentApprovers;

    constructor() {
        superAdmin = msg.sender;
    }

    /**
     * @notice Allows superAdmin change the superAdmin address.
     * @param _newSuperAdmin The new superAdmin address.
     * @param _genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     * @dev this function is gated to only superAdmin address.
     */
    function changeSuperAdmin(
        address _newSuperAdmin,
        address[] calldata _genArt721CoreAddressesToUpdate
    ) external {
        require(msg.sender == superAdmin, "Only superAdmin");
        address previousSuperAdmin = superAdmin;
        superAdmin = _newSuperAdmin;
        emit SuperAdminTransferred(
            previousSuperAdmin,
            _newSuperAdmin,
            _genArt721CoreAddressesToUpdate
        );
    }

    /**
     * Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function is gated to only superAdmin address.
     * @dev This implementation requires that the new AdminACL contract
     * broadcasts support of IAdminACLV0 via ERC165 interface detection.
     */
    function transferOwnershipOn(address _contract, address _newAdminACL)
        external
    {
        require(msg.sender == superAdmin, "Only superAdmin");
        // ensure new AdminACL contract supports IAdminACLV0
        require(
            ERC165(_newAdminACL).supportsInterface(
                type(IAdminACLV0).interfaceId
            ),
            "AdminACLV1: new admin ACL does not support IAdminACLV0"
        );
        Ownable(_contract).transferOwnership(_newAdminACL);
    }

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function is gated to only superAdmin address.
     */
    function renounceOwnershipOn(address _contract) external {
        require(msg.sender == superAdmin, "Only superAdmin");
        Ownable(_contract).renounceOwnership();
    }

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`. Returns true if sender is superAdmin,
     * or if `_selector` is
     * GenArt721CoreV3.adminAcceptArtistAddressesAndSplits.selector and address
     * is in set of payment approvers.
     */
    function allowed(
        address _sender,
        address, /*_contract*/
        bytes4 _selector
    ) external view returns (bool) {
        // always allow superAdmin
        if (_sender == superAdmin) {
            return true;
        }
        // if calling payment approval function, check if sender is in approver
        // set
        if (
            _selector ==
            GenArt721CoreV3.adminAcceptArtistAddressesAndSplits.selector
        ) {
            return _paymentApprovers.contains(_sender);
        }
        // otherwise, return false
        return false;
    }

    /**
     *
     * @notice Adds address to payment approvers set. Only callable by
     * superAdmin. Address must not already be in set.
     * @param _approver NFT core address to be registered.
     */
    function addPaymentApprover(address _approver) external {
        require(msg.sender == superAdmin, "Only superAdmin");
        require(
            _paymentApprovers.add(_approver),
            "AdminACLV1: Already registered"
        );
        emit PaymentApproverAdded(_approver);
    }

    /**
     *
     * @notice Removes address to payment approvers set. Only callable by
     * superAdmin. Address must be in set.
     * @param _approver NFT core address to be registered.
     */
    function removePaymentApprover(address _approver) external {
        require(msg.sender == superAdmin, "Only superAdmin");
        require(
            _paymentApprovers.remove(_approver),
            "AdminACLV1: Not registered"
        );
        emit PaymentApproverRemoved(_approver);
    }

    /**
     * @notice Gets quantity of addresses registered to approve artist-proposed
     * payment addresses.
     * @return uint256 quantity of addresses approved
     */
    function getNumPaymentApprovers() external view returns (uint256) {
        return _paymentApprovers.length();
    }

    /**
     * @notice Get artist-proposed payment address approver address at index
     * `_index` of enumerable set.
     * @param _index enumerable set index to query.
     * @return NFTAddress payment approver address at index `_index`
     * @dev index must be < quantity of registered payment approvers
     */
    function getPaymentApproverAt(uint256 _index)
        external
        view
        returns (address NFTAddress)
    {
        return _paymentApprovers.at(_index);
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IAdminACLV0).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}