// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract DropExchange is AccessControl, ReentrancyGuard, EIP712, Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER");

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(bytes32 => bool) public executedOrders;

    /* solhint-disable max-line-length */
    bytes32 public constant SELLORDER_TYPE_HASH =
        keccak256(
            "SellOrder(address collection,uint256 tokenId,uint256 quantity,uint256 amount,address seller,address buyer,uint256 deadline,address feesRecipient,uint256 feesAmount)"
        );
    /* solhint-enable max-line-length */

    // fired every time a drop is redeemed
    event DropRedeemed(address collection, uint256 tokenId, uint256 quantity, address buyer);
    // fire every time a drop is invalidated
    event DropInvalidated(address collection, uint256 tokenId, uint256 quantity, address buyer);

    struct SellOrder {
        // asset
        address collection;
        uint256 tokenId;
        uint256 quantity;
        // sale amount for everything
        uint256 amount;
        // seller
        address seller;
        // buyer
        address buyer;
        // safety
        uint256 deadline;
        // fees
        address feesRecipient;
        uint256 feesAmount;
    }

    constructor(address admin) EIP712("DropExchange", "1") {
        require(admin != address(0), "CB: Admin cannot be the zero address");
        // set the admin role
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        // set the admin role
        _setupRole(PAUSER_ROLE, admin);

        // set admin as minter to
        _setupRole(MINTER_ROLE, admin);
    }

    /// @notice executes a drop buy authorized by a signing authority
    /// @dev re-entry guard is needed because we transfer ETH
    /// @param order needs to be a valid order
    /// @param signature needs to be a signature from an authority
    function executeOrder(SellOrder memory order, DropExchange.Signature memory signature)
        public
        payable
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        return _executeOrder(order, signature);
    }

    function _executeOrder(SellOrder memory order, DropExchange.Signature memory signature) internal returns (bool) {
        /// ---------- VALIDATE TRANSACTION ------
        // make sure the order isn't expired
        require(order.deadline <= block.timestamp, "CB: Order expired");

        // make sure the buyer is the person sending the transaction
        require(msg.sender == order.buyer, "CB: Buyer does not match order");

        //// --------- VALIDATE SIGNATURE -------
        // create the hash of the order
        bytes32 hash = hashOrder(order);
        verifyOrderHash(hash, signature);

        ///// EFFECTS
        // mark the order as confirmed
        executedOrders[hash] = true;

        ///// INTERACTIONS
        //// ------- SETTLE TRANSACTION -------

        // transfer eth to seller
        // solhint-disable-next-line avoid-low-level-calls
        (bool sellerTransfer, ) = order.seller.call{ value: order.amount }("");
        require(sellerTransfer, "CB: Seller eth transfer failed");

        // transfer eth to fee recipient
        if (order.feesAmount > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool feesTransfer, ) = order.feesRecipient.call{ value: order.feesAmount }("");
            require(feesTransfer, "CB: Fees eth transfer failed");
        }

        // transfer nft to buyer
        if (order.quantity == 0) {
            // ERC721
            IERC721 erc721Collection = IERC721(order.collection);

            erc721Collection.safeTransferFrom(order.seller, order.buyer, order.tokenId);

            // Ensure the erc721 transfer has successfully gone through
            require(erc721Collection.ownerOf(order.tokenId) == order.buyer, "CB: Buyer has not received ERC721");
        } else {
            // ERC1155
            IERC1155 erc1155Collection = IERC1155(order.collection);

            erc1155Collection.safeTransferFrom(order.seller, order.buyer, order.tokenId, order.quantity, bytes(""));
        }

        // emit an event for the indexer team
        emit DropRedeemed(order.collection, order.tokenId, order.quantity, order.buyer);
        // bool to show successful order
        return true;
    }

    /// @notice executes a batch of orders
    /// @param orders needs to be an array valid order
    /// @param signatures needs to be an array of signatures from an authority
    /// @return true if all orders successful, else false
    function batchExecuteOrder(
        SellOrder[] memory orders,
        DropExchange.Signature[] memory signatures,
        bool revertIfIncomplete
    ) external payable nonReentrant whenNotPaused returns (bool[] memory) {
        require(orders.length == signatures.length, "CB: length mismatch between orders and signatures");
        bool[] memory successes = new bool[](orders.length);
        for (uint256 i = 0; i < orders.length; ++i) {
            if (revertIfIncomplete) {
                require(_executeOrder(orders[i], signatures[i]), "CB: failed to execute order");
            } else {
                successes[i] = _executeOrder(orders[i], signatures[i]);
            }
        }
        return successes;
    }

    /// @notice verifiers that the signer signed the order
    /// @param hash needs to be a valid EIP712 hash of the order
    /// @param sig needs to be a signature from an authority
    function verifyOrderHash(
        // needs to be a valid order
        bytes32 hash,
        // needs to be a signature from an authority
        DropExchange.Signature memory sig
    ) public view returns (bool) {
        //// ------- VALIDATE ORDER ----------

        // make sure the order has not been executed
        require(!executedOrders[hash], "CB: Order has been executed");

        // get the signer of the hash and verify
        (address signer, ) = ECDSA.tryRecover(hash, sig.v, sig.r, sig.s);
        require(signer != address(0), "CB: Signature is invalid");

        // make sure that the signer is a valid authority
        require(hasRole(MINTER_ROLE, signer), "CB: Unauthorized minter");

        return true;
    }

    /// @notice See EIP-712, prevents signatures here from being used elsewhere
    /// @return Returns the domain separator for the current chain.
    function getDomainHash() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @notice hashes an order on-chain
    /// @param order needs to be a valid order
    /// @return a hash of the orderHash and the domain separator
    function hashOrder(SellOrder memory order) public view returns (bytes32) {
        bytes32 orderHash = keccak256(
            abi.encode(
                SELLORDER_TYPE_HASH,
                order.collection,
                order.tokenId,
                order.quantity,
                order.amount,
                order.seller,
                order.buyer,
                order.deadline,
                order.feesRecipient,
                order.feesAmount
            )
        );

        return _hashTypedDataV4(orderHash);
    }

    /// @notice invalidates a sell order before it gets used
    /// @param order needs to be a valid order
    /// @return True if order was successfully invalidated
    function invalidate(SellOrder memory order) external onlyRole(MINTER_ROLE) returns (bool) {
        ///// CHECKS
        bytes32 hash = hashOrder(order);

        require(!executedOrders[hash], "CB: Order is already invalid");

        ///// EFFECTS

        executedOrders[hash] = true;

        emit DropInvalidated(order.collection, order.tokenId, order.quantity, order.buyer);

        return true;
    }

    /// @notice pause the contract
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice unpause the contract
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}