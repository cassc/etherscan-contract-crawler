// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IERC173} from "../interfaces/utils/IERC173.sol";
import {IDopaminePrimaryCheckout} from "../interfaces/payments/IDopaminePrimaryCheckout.sol";

import {Ownable} from "../utils/Ownable.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import {EIP712Signable} from "../utils/EIP712Signable.sol";
import {Order, Bundle} from "./DopaminePrimaryCheckoutStructs.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title  Dopamine Primary Checkout
/// @author @leeren
/// @notice Crypto checkout attribution for Dopamine Streetwear+ bundle orders.
contract DopaminePrimaryCheckout is ReentrancyGuard, Ownable, EIP712Signable, IDopaminePrimaryCheckout {

    /// @notice Do not permit more than 10 bundles to be purchased at a time.
    uint256 MAX_BUNDLES = 10;

    /// @notice EIP-712 claim hash used for processing and validating orders.
    bytes32 public constant ORDER_TYPEHASH = keccak256("Order(string id,address purchaser,Bundle[] bundles)Bundle(uint64 brand,uint64 collection,uint64 colorway,uint64 size,uint256 price)");
    bytes32 public constant BUNDLE_TYPEHASH = keccak256("Bundle(uint64 brand,uint64 collection,uint64 colorway,uint64 size,uint256 price)");

    /// @notice Tracks whether a bundle was purchased or not.
    mapping(string => bool) public orderProcessed;

    /// @notice Instantiates the Dopamine Primary Checkout contract.
    /// @param signer Address whose sigs are used for purchase verification.
	constructor(address signer) {
        setSigner(signer, true);
    }

    /// @notice Gets the EIP-712 order hash or tracking crypto-based purchases.
    /// @param id The Dopamine tracking identifier associated with the order.
    /// @param purchaser The address granted permission to make the purchase.
    /// @param bundles A list of bundled products included in the order.
    /// @return The EIP-712 hash identifying the marketplace order.
    function getOrderHash(
        string memory id,
        address purchaser,
        Bundle[] calldata bundles
    ) public pure returns (bytes32) {
        bytes32[] memory bundleHashes = new bytes32[](bundles.length);
        Bundle memory bundle;
        for (uint256 i = 0; i < bundles.length; ++i) {
            bundle = bundles[i];
            bundleHashes[i] = getBundleHash(
                bundle.brand, bundle.collection, bundle.colorway, bundle.size, bundle.price
            );
        }
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                keccak256(bytes(id)),
                purchaser,
                keccak256(abi.encodePacked(bundleHashes))
            )
        );
    }

    /// @notice Gets the EIP-712 bundle hash for a specific merchandise item.
    /// @param brand The identifier for the bundle brand.
    /// @param collection The product identifier for a bundle.
    /// @param colorway The chosen bundle colorway identifier.
    /// @param size The size identifier for a bundle.
    /// @param price The price (in USD) of the individual bundle.
    /// @return The EIP-712 hash identifying the bundle.
    function getBundleHash(
        uint64 brand,
        uint64 collection,
        uint64 colorway,
        uint64 size,
        uint256 price
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                BUNDLE_TYPEHASH,
                brand,
                collection,
                colorway,
                size,
                price
            )
        );
    }

    /// @notice Performs registered checkout of a crypto-based Dopamine order.
    /// @param order The bundle order to be processed.
    function checkout(Order calldata order) external payable nonReentrant {
        if (orderProcessed[order.id]) {
            revert OrderAlreadyProcessed();
        }
        if (order.bundles.length > MAX_BUNDLES) {
            revert OrderCapacityExceeded();
        }

        (bytes32 orderHash) = getOrderHash(
            order.id,
            order.purchaser,
            order.bundles
        );

        _verifySignature(
            order.signature,
            _deriveEIP712Digest(orderHash)
        );

        orderProcessed[order.id] = true;
        emit OrderFulfilled(orderHash, order.purchaser, order.bundles);
    }

    /// @notice Withdrawals all collected payments to the owner address.
    /// @param amount The amount in wei to withdraw.
    /// @param to The address to withdraw the wei to.
    function withdraw(uint256 amount, address to) public onlyOwner {
        if (amount > address(this).balance) {
            revert WithdrawalInvalid();
        }
        _transferETH(payable(to), amount);
    }

    /// @notice Sets up a new signer for authorizing checkouts.
    /// @param signer The address verifying crypto-based checkouts.
    /// @param setting Whether the signer has permission to verify checkouts.
    function setSigner(address signer, bool setting) public onlyOwner {
        signers[signer] = setting;
        emit DopamineCheckoutSignerSet(signer, setting);
    }

    /// @notice Checks if the given contract supports an interface.
    /// @param interfaceId The 4-byte ERC-165 interface identifier.
    function supportsInterface(bytes4 interfaceId) public override(IERC165, Ownable) pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IERC173).interfaceId;
    }

    /// @notice Transfers `amount` wei to address `to`.
    /// @param to The address receiving the transfer.
    /// @param amount The amount in wei being transferred.
    function _transferETH(address payable to, uint256 amount) public {
        (bool success, ) = to.call{value: amount}("");
        if(!success){
            revert EthTransferFailed();
        }
    }

    /// @notice EIP-712 name identifier used for signature verification.
    function _NAME() internal override pure returns (string memory) {
        return "Dopamine Primary Checkout";
    }

    /// @notice EIP-712 version identifier used for signature verification.
    function _VERSION() internal override pure returns (string memory) {
        return "1.0";
    }

}