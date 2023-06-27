// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
// Adapted for use by the registry

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./UniversalRegistrar.sol";

/**
 * @title BaseUniversalRegistrarController
 * @dev This contract allows to split Ether payments among an owner (a staker) and the registry.
 *
 * `BaseUniversalRegistrarController` follows a _pull payment_ model. This means that payments are not automatically
 * forwarded to the accounts but kept in this contract, and the actual transfer is triggered as a separate step by
 * calling the {releaseToOwner} and {releaseToRegistry} functions.
 *
 */
abstract contract BaseUniversalRegistrarController is Initializable {
    event PaymentReleased(bytes32 node, address to, uint256 amount);

    // The total number of shares
    uint256 private _totalShares;

    // Number of shares the registry owns
    uint256 private _registryShare;

    // Number of shares a staker owns
    uint256 private _ownerShare;

    // Amount of Ether available for release to share holders.
    mapping(bytes32 => uint256) private _balances;

    // Total amount of Ether already released to share holders.
    mapping(bytes32 => uint256) private _totalReleased;

    // Amount of Ether already released to the registry.
    mapping(bytes32 => uint256) private _registryReleased;

    // Amount of Ether already released to the TLD owner.
    mapping(bytes32 => uint256) private _ownerReleased;

    UniversalRegistrar public base;

    // Owner payee address for the specified TLD
    function ownerPayee(bytes32 node) public view returns (address) {
        // get address of current owner from registrar
        return base.ownerOfNode(node);
    }

    // Registry payee address
    function registryPayee() public view returns (address) {
        // get address of root owner from registrar
        return base.root().owner();
    }

    constructor(UniversalRegistrar base_, uint256 ownerShare_, uint256 registryShare_) {
        base = base_;
        _ownerShare = ownerShare_;
        _registryShare = registryShare_;
        _totalShares = ownerShare_ + registryShare_;
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased(bytes32 node) public view returns (uint256) {
        return _totalReleased[node];
    }

    /**
     * @dev Getter for the amount of shares held by owner
     */
    function ownerShare() public view returns (uint256) {
        return _ownerShare;
    }

    /**
     * @dev Getter for the amount of shares held by registry.
     */
    function registryShare() public view returns (uint256) {
        return _registryShare;
    }

    /**
     * @dev Getter for the amount of Ether already released to the owner
     */
    function ownerReleased(bytes32 node) public view returns (uint256) {
        return _ownerReleased[node];
    }

    /**
     * @dev Getter for the amount of Ether already released to the registry.
     */
    function registryReleased(bytes32 node) public view returns (uint256) {
        return _registryReleased[node];
    }

    function balance(bytes32 node) public view returns (uint256) {
        return _balances[node];
    }

    function _addPayment(bytes32 node, uint256 amount) internal {
        _balances[node] += amount;
    }

    /**
     * @dev Triggers a transfer to the owner for the amount of Ether they are owed, according to their
     * percentage of the total shares and their previous withdrawals.
     */
    function releaseToOwner(bytes32 node) public virtual {
        uint256 totalReceived = balance(node) + totalReleased(node);
        uint256 payment = _pendingPayment(ownerShare(), totalReceived, ownerReleased(node));

        require(payment != 0, "owner is not due payment");

        _ownerReleased[node] += payment;
        _totalReleased[node] += payment;
        _balances[node] -= payment;

        address owner = ownerPayee(node);
        AddressUpgradeable.sendValue(payable(owner), payment);
        emit PaymentReleased(node, owner, payment);
    }

    /**
     * @dev Triggers a transfer to the registry owner of the amount of Ether they are owed, according to their
     * percentage of the total shares and their previous withdrawals.
     */
    function releaseToRegistry(bytes32 node) public virtual {
        uint256 totalReceived = balance(node) + totalReleased(node);
        uint256 payment = _pendingPayment(registryShare(), totalReceived, registryReleased(node));

        require(payment != 0, "registry is not due payment");

        _registryReleased[node] += payment;
        _totalReleased[node] += payment;
        _balances[node] -= payment;

        address rootOwner = registryPayee();
        AddressUpgradeable.sendValue(payable(rootOwner), payment);
        emit PaymentReleased(node, rootOwner, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an account given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        uint256 shares,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * shares) / _totalShares - alreadyReleased;
    }
}