// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./exchange/ExchangeCore.sol";

contract KompeteMarketplace is ExchangeCore, Ownable, Pausable {
    string public constant NAME = "Kompete Marketplace";
    string public constant VERSION = "1.0";
    string public constant CODENAME = "Late rabbit";

    event ProtocolFeeRecipientChanged(address indexed recipient);
    event MintFeeRecipientChanged(address indexed collection, address indexed recipient);

    event CollectionAdded(address indexed collection);
    event CollectionRemoved(address indexed collection);

    constructor(IERC20 tokenAddress, address protocolFeeAddress) EIP712(NAME, VERSION) {
        exchangeToken = tokenAddress;
        protocolFeeRecipient = protocolFeeAddress;
    }

    /**
     * @dev Change the protocol fee recipient (admins only)
     * @param recipient New protocol fee recipient address
     */
    function setProtocolFeeRecipient(address recipient) external onlyOwner {
        protocolFeeRecipient = recipient;
        emit ProtocolFeeRecipientChanged(recipient);
    }

    /**
     * @dev Change the mint fee recipient for a collection (admins only)
     * @param recipient New protocol fee recipient address (set collection address(0) for default value)
     */
    function setMintFeeRecipient(address collection, address recipient) external onlyOwner {
        mintFeeRecipient[collection] = recipient;
        emit MintFeeRecipientChanged(collection, recipient);
    }

    /**
     * @dev Allow/Disallow a collection to be traded in the marketplace (admins only)
     */
    function toggleCollection(address collection, bool allowed) external onlyOwner {
        if (collection == address(0)) revert InvalidCollection();

        if (allowedCollections[collection] != allowed) {
            allowedCollections[collection] = allowed;
            if (allowed) emit CollectionAdded(collection);
            else emit CollectionRemoved(collection);
        }
    }

    /**
     * @dev Call hashOrder
     */
    function hashOrder_(Order memory order) public view returns (bytes32) {
        return hashOrder(order, nonces[order.maker]);
    }

    /**
     * @dev Call hashToSign
     */
    function hashToSign_(Order memory order) public view returns (bytes32) {
        return hashToSign(order, nonces[order.maker]);
    }

    /**
     * @dev Call validateOrderParameters
     */
    function validateOrderParameters_(Order memory order) public view returns (bool) {
        return validateOrderParameters(order);
    }

    /**
     * @dev Call validateOrder
     */
    function validateOrder_(Order memory order, bytes memory signature) public view returns (bool) {
        return validateOrder(hashToSign(order, nonces[order.maker]), order, signature);
    }

    /**
     * @dev Call approveOrder
     */
    function approveOrder_(Order memory order, bool orderbookInclusionDesired) external whenNotPaused {
        return approveOrder(order, orderbookInclusionDesired);
    }

    /**
     * @dev Call cancelOrder
     */
    function cancelOrder_(Order memory order, bytes memory signature) external whenNotPaused {
        return cancelOrder(order, signature, nonces[order.maker]);
    }

    /**
     * @dev Call cancelOrder, supplying a specific nonce — enables cancelling orders
     that were signed with nonces greater than the current nonce.
     */
    function cancelOrderWithNonce_(
        Order memory order,
        bytes memory signature,
        uint256 nonce
    ) external {
        return cancelOrder(order, signature, nonce);
    }

    /**
     * @dev Call ordersCanMatch
     */
    function ordersCanMatch_(Order memory buy, Order memory sell) public view returns (bool) {
        return ordersCanMatch(buy, sell);
    }

    /**
     * @dev Atomically match two orders
     * @param buy Buy-side order
     * @param buySig Buy-side order signature
     * @param sell Sell-side order
     * @param sellSig Sell-side order signature
     */
    function atomicMatch_(
        Order memory buy,
        bytes memory buySig,
        Order memory sell,
        bytes memory sellSig,
        bytes32 metadata
    ) external payable whenNotPaused {
        atomicMatch(buy, buySig, sell, sellSig, metadata);
    }

    /**
     * @dev Pauses the marketplace
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the marketplace
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}