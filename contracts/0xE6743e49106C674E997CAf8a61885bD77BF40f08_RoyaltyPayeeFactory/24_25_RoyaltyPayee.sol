// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../universal/UniversalRegistrar.sol";
import "./IRoyaltyPayee.sol";
import "./IExtensionPayee.sol";

/**
 * @title RoyaltyPayee
 * @dev This contract allows to split Ether payments between the registry & the TLD owner. The sender does not need to
 * be aware that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * Of all the Ether that this contract receives, each account will be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `RoyaltyPayee` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the
 * {releaseToOwner} & {releaseToRegistry} functions.
 */
contract RoyaltyPayee is IRoyaltyPayee, ERC165, Initializable, Context {
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    uint256 private _registryShare;
    uint256 private _ownerShare;

    uint256 private _registryReleased;
    uint256 private _ownerReleased;

    UniversalRegistrar public registrar;
    bytes32 public node;

    constructor() {
        // Disable initializer on the implementation contract during deployment
        // to prevent the base contract from being initialized (only clones can be initialized).
        // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /**
     * @dev Creates an instance of `RoyaltyPayee` where the registry and owner are assigned a number of shares.
     */
    function initialize(UniversalRegistrar registrar_, bytes32 node_, uint256 ownerShare_, uint256 registryShare_) external initializer {
        registrar = registrar_;
        node = node_;
        _registryShare = registryShare_;
        _ownerShare = ownerShare_;
        _totalShares = ownerShare_ + registryShare_;
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function ownerPayee() public view returns (address) {
        address owner = registrar.ownerOfNode(node);

        // if the owner is a contract and supports the IExtensionPayee interface, use the payee address
        // for payments instead.
        if (Address.isContract(owner)) {
            try IERC165(owner).supportsInterface(type(IExtensionPayee).interfaceId) returns (bool supported) {
                if (supported) {
                    return IExtensionPayee(owner).payeeOf(node);
                }
            } catch {}
        }

        return owner;
    }

    function registryPayee() public view returns (address) {
        return registrar.root().owner();
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() external view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by owner.
     */
    function ownerShare() external override view returns (uint256) {
        return _ownerShare;
    }

    /**
     * @dev Getter for the amount of shares held by registry.
     */
    function registryShare() external override view returns (uint256) {
        return _registryShare;
    }

    /**
     * @dev Getter for the amount of Ether already released to the owner.
     */
    function ownerReleased() external override view returns (uint256) {
        return _ownerReleased;
    }

    /**
     * @dev Getter for the amount of Ether already released to the registry.
     */
    function registryReleased() external override view returns (uint256) {
        return _registryReleased;
    }

    function ownerBalance() external override view returns (uint256) {
        uint256 totalReceived = address(this).balance + _totalReleased;
        return _pendingPayment(_ownerShare, totalReceived, _ownerReleased);
    }

    function registryBalance() external override view returns (uint256) {
        uint256 totalReceived = address(this).balance + _totalReleased;
        return _pendingPayment(_registryShare, totalReceived, _registryReleased);
    }

    /**
     * @dev Triggers a transfer to the owner for the amount of Ether they are owed, according to their
     * percentage of the total shares and their previous withdrawals.
     */
    function releaseToOwner() external override {
        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = _pendingPayment(_ownerShare, totalReceived, _ownerReleased);

        require(payment != 0, "RoyaltyPayee: owner is not due payment");

        _ownerReleased += payment;
        _totalReleased += payment;

        address owner = ownerPayee();
        Address.sendValue(payable(owner), payment);
        emit PaymentReleased(owner, payment);
    }

    /**
     * @dev Triggers a transfer to the registry of the amount of Ether they are owed, according to their
     * percentage of the total shares and their previous withdrawals.
     */
    function releaseToRegistry() external override {
        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = _pendingPayment(_registryShare, totalReceived, _registryReleased);

        require(payment != 0, "RoyaltyPayee: registry is not due payment");

        _registryReleased += payment;
        _totalReleased += payment;

        address rootOwner = registryPayee();
        Address.sendValue(payable(rootOwner), payment);
        emit PaymentReleased(rootOwner, payment);
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

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IRoyaltyPayee).interfaceId || super.supportsInterface(interfaceId);
    }
}