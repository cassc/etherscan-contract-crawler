// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
// Adapted for use by the registry

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Address.sol";
import "./UniversalRegistrar.sol";

/**
 * @title BaseUniversalRegistrarController
 * @dev This contract allows to split Ether payments among a payee and the registry.
 *
 * `BaseUniversalRegistrarController` follows a _pull payment_ model. This means that payments are not automatically
 * forwarded to the accounts but kept in this contract, and the actual transfer is triggered as a separate step by
 * calling the {releaseToPayee} and {releaseToRegistry} functions.
 *
 */
abstract contract BaseUniversalRegistrarController {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(bytes32 node, address to, uint256 amount);

    // The total number of shares
    uint256 private constant _totalShares = 100;

    // Amount of Ether available for release to share holders.
    mapping(bytes32 => uint256) private _balances;

    // Total amount of Ether already released to share holders.
    mapping(bytes32 => uint256) private _totalReleased;

    // Amount of shares of the registry.
    mapping(bytes32 => uint256) private _registryShares;

    // Amount of shares of a payee.
    mapping(bytes32 => uint256) private _payeeShares;

    // Amount of Ether already released to the registry.
    mapping(bytes32 => uint256) private _registryReleased;

    // Amount of Ether already released to a payee.
    mapping(bytes32 => uint256) private _payeeReleased;

    mapping(bytes32 => address) private _payee;

    UniversalRegistrar public base;

    // Registry payee address
    function registryPayee() public view returns (address) {
        // get address of root owner from registrar
        return base.root().owner();
    }

    constructor(UniversalRegistrar base_) {
        base = base_;
    }

    modifier onlyRegistry {
        require(msg.sender == registryPayee(), "Caller is not owner!");
        _;
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public pure returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased(bytes32 node) internal view returns (uint256) {
        return _totalReleased[node];
    }

    /**
     * @dev Getter for the payee address of a node
     */
    function payee(bytes32 node) internal view returns (address) {
        return _payee[node];
    }

    /**
     * @dev Getter for the amount of shares held by payee
     */
    function payeeShare(bytes32 node) internal view returns (uint256) {
        return _payeeShares[node];
    }

    /**
     * @dev Getter for the amount of shares held by registry
     */
    function registryShare(bytes32 node) internal view returns (uint256) {
        return _registryShares[node];
    }

    /**
     * @dev Getter for the amount of Ether already released to the registry
     */
    function registryReleased(bytes32 node) internal view returns (uint256) {
        return _registryReleased[node];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee
     */
    function payeeReleased(bytes32 node) internal view returns (uint256) {
        return _payeeReleased[node];
    }

    /**
     * @dev Getter for the balance of a node.
    */
    function balance(bytes32 node) internal view returns (uint256) {
        return _balances[node];
    }

    /**
     * @dev Add balance to a node
    */
    function _addPayment(bytes32 node, uint256 amount) internal {
        _balances[node] += amount;
    }

    /**
     * @dev Triggers a transfer to the registry for the amount of Ether they are owed, according to their
     * percentage of the total shares and their previous withdrawals.
     */
    function releaseToRegistry(bytes32 node) public virtual onlyRegistry {
        uint256 payment;

        if(payee(node) == address(0)) {
            payment = balance(node);
        } else {
            uint256 totalReceived = balance(node) + totalReleased(node);
            payment = _pendingPayment(registryShare(node), totalReceived, registryReleased(node));
        }

        require(payment != 0, "Registry is not due payment");

        _registryReleased[node] += payment;
        _totalReleased[node] += payment;
        _balances[node] -= payment;

        address rootOwner = registryPayee();
        Address.sendValue(payable(rootOwner), payment);
        emit PaymentReleased(node, rootOwner, payment);
    }

    /**
     * @dev Triggers a transfer to a payee of the amount of Ether they are owed, according to their
     * percentage of the total shares and their previous withdrawals.
     */
    function releaseToPayee(bytes32 node) public virtual {
        require(msg.sender == payee(node), "Caller is not Payee!");
        require(payeeShare(node) > 0, "Payee has no shares!");

        uint256 totalReceived = balance(node) + totalReleased(node);
        uint256 payment = _pendingPayment(payeeShare(node), totalReceived, payeeReleased(node));

        require(payment != 0, "Payee is not due payment");

        _payeeReleased[node] += payment;
        _totalReleased[node] += payment;
        _balances[node] -= payment;

        address payee_ = payee(node);
        Address.sendValue(payable(payee_), payment);
        emit PaymentReleased(node, payee_, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an account given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        uint256 shares_,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private pure returns (uint256) {
        return (totalReceived * shares_) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Set a payee to the contract.
     * @param node The node.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
    */
    function setPayee(bytes32 node, address account, uint256 shares_) external onlyRegistry {
        _payee[node] = account;
        setPayeeShares(node, shares_);
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev Set shares of an account to the contract.
     * @param node The node.
     * @param shares_ The number of shares of a payee to set.
    */
    function setPayeeShares(bytes32 node, uint256 shares_) public onlyRegistry {
        _payeeShares[node] = shares_;
        _registryShares[node] = totalShares() - shares_;
    }

    /**
     * @dev Set shares of an account to the contract.
     * @param node The node.
     * @param shares_ The number of shares of a payee to set.
    */
    function setRegistryShares(bytes32 node, uint256 shares_) public onlyRegistry {
        _registryShares[node] = shares_;
        _payeeShares[node] = totalShares() - shares_;
    }
}