// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./KeevoRole.sol";

/**
 * @title KeevoDeposit contract
 * @author Keevo
 * @dev This contract is for creating and tracing client deposits
 * - Contract support:
 *   # Admin and Depositer roles. See KeevoRole.sol
 *     Admin able to manage roles
 *     Depositer able to collect funds for contract owner
 *   # Adding funds to deposit.
 *   # Deposit withdrawal by client.
 *   # Collecting funds by contract owner. Amount for collect is declared in EIP712 message signed by customer.
 *   # Offchain offers signing by client (see KeevoOffer structure).
 *   # Refusing signed offer by client (if funds wasn't collected).
 **/
contract KeevoDepositEip712 is Ownable, ReentrancyGuard, KeevoRole {

    bytes32 constant KEEVO_SERVICE_TYPEHASH = keccak256("KeevoOffer(address customer,string service,uint256 id,uint256 cost,uint256 lifetime)");
    bytes32 constant KEEVO_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant KEEVO_EIP712_DOMAIN_NAME_HASH = keccak256("Keevo Deposit Service");
    bytes32 constant KEEVO_EIP712_DOMAIN_VERSION_HASH = keccak256("1.0.0");

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Structure for EIP712 message.
     * All fields supposed to be filled by Keevo and signed by customer.
     * - customer is address used by customer for sign EIP712 message
     * - service is string description of what service is provided
     * - id is offer id for tracking
     * - cost is amount of wei that be paid for service. Will be collected from customer deposit
     * - lifetime is time when offer become invalid. In seconds since the epoch
     **/
    struct KeevoOffer{
        address customer;
        string  service;
        uint256 id;
        uint256 cost;
        uint256 lifetime;
    }

    /**
     * @dev map client address to his deposit
     */
    mapping(address => uint256) private clientBalances;

    /**
     * @dev hashes of KeevoOffer which already accepted or refused
     */
    mapping(bytes32 => bool) private inactiveOffers;

    /**
     * @dev event emitted when deposit value is changed.
     * custom listeners can use it to deposit info offchain
     * - owner is address of deposit owner
     * - oldBalance is balance before deposit changes
     * - newBalance is balance after deposit changes
     */
    event depositChanged(
        address owner,
        uint256 oldBalance,
        uint256 newBalance
    );

    /**
     * @dev Constructor function
     */
    constructor() {
        addAdmin(_msgSender());
        addDepositer(_msgSender());
    }

    /**
     * @dev Add funds to customer deposit
     */
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Amount should be positive!");
        uint256 oldBalance = clientBalances[msg.sender];
        clientBalances[msg.sender] += msg.value;
        emit depositChanged(msg.sender, oldBalance, clientBalances[msg.sender]);
    }

    /**
     * @dev Withdraw deposit by client
     */
    function withdrawDeposit() external payable nonReentrant {
        require(clientBalances[msg.sender] > 0, "Deposit is empty");
        uint256 amount = clientBalances[msg.sender];
        clientBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit depositChanged(msg.sender, amount, clientBalances[msg.sender]);
    }

    /**
     * @dev Collect deposit for contract owner
     * @param offer description of Keevo offer which was accepted and signed by client
     * @param v is v part of client signature
     * @param r is r part of client signature
     * @param s is s part of client signature
     */
    function collectDeposit(KeevoOffer memory offer, uint8 v, bytes32 r, bytes32 s)
        external
        payable
        onlyDepositer
        nonReentrant
    {
        require(block.timestamp <= offer.lifetime, "Offer expired");

        bytes32 hash = getServiceHash(offer);
        require(inactiveOffers[hash] == false, "Offer invalid");

        address signer = ecrecover(hash, v, r, s);
        require(signer == offer.customer, "Signature incorrect");

        uint256 balance = clientBalances[signer];
        require(balance >= offer.cost, "Insufficient funds");

        inactiveOffers[hash] = true;
        clientBalances[signer] -= offer.cost;
        payable(owner()).transfer(offer.cost);
        
        emit depositChanged(signer, balance, clientBalances[signer]);
    }

    /**
     * @dev Calculate EIP712 message hash
     * @param offer is description of offer in EIP712 message
     */
    function getServiceHash(KeevoOffer memory offer) private view returns (bytes32 hash) {
        bytes32 eip712DomainHash = keccak256(abi.encode(
            KEEVO_DOMAIN_TYPEHASH,
            KEEVO_EIP712_DOMAIN_NAME_HASH,
            KEEVO_EIP712_DOMAIN_VERSION_HASH,
            block.chainid,
            address(this)
        ));

        bytes32 hashStruct =  keccak256(abi.encode(
            KEEVO_SERVICE_TYPEHASH,
            offer.customer,
            keccak256(bytes(offer.service)),
            offer.id,
            offer.cost,
            offer.lifetime
        ));

        return keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
    }

    /**
     * @dev Return current balance of client
     * @param client is address of client
     */
    function getBalance(address client) public view returns (uint256 balance) {
        return clientBalances[client];
    }

    /**
     * @dev Check offer activeness
     * @param offer is offer description
     */
    function isOfferActive(KeevoOffer memory offer) public view returns (bool isActive) {
        bytes32 hash = getServiceHash(offer);
        return !inactiveOffers[hash];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
