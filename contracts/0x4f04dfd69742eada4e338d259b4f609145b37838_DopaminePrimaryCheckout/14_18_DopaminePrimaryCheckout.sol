// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IERC173} from "../interfaces/utils/IERC173.sol";
import {IDopaminePrimaryCheckout} from "../interfaces/payments/IDopaminePrimaryCheckout.sol";
import {Order, Bundle} from "./DopaminePrimaryCheckoutStructs.sol";
import {Ownable} from "../utils/Ownable.sol";
import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import {EIP712Signable} from "../utils/EIP712Signable.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title  Dopamine Primary Checkout
/// @notice Dopamine primary checkout mechanism for logging and processing
///         purchases of Dopamine streetwear+ bundles.
contract DopaminePrimaryCheckout is ReentrancyGuard, Ownable, EIP712Signable, IDopaminePrimaryCheckout {

    /// @notice Do not permit more than 10 bundles to be purchased at a time.
    uint256 MAX_BUNDLES = 10;

    /// @notice EIP-712 claim hash used for processing and validating orders.
    bytes32 public constant ORDER_TYPEHASH = keccak256("Order(address purchaser,Bundle[] bundles)Bundle(bytes32 id,address pnft,address[] bindables,uint256 price)");
    bytes32 public constant BUNDLE_TYPEHASH = keccak256("Bundle(bytes32 id,address pnft,address[] bindables,uint256 price)");

    /// @notice Tracks whether a bundle was purchased or not.
    mapping(bytes32 => bool) public bundlePurchased;

    /// @notice Instantiates the Dopamine Primary Checkout contract.
    /// @param signer Address whose sigs are used for purchase verification.
	constructor(address signer) {
        setSigner(signer, true);
    }

    function getOrderHash(
        address purchaser,
        Bundle[] calldata bundles
    ) public view returns (bytes32) {
        bytes32[] memory bundleHashes = new bytes32[](bundles.length);
        Bundle memory bundle;
        for (uint256 i = 0; i < bundles.length; ++i) {
            bundle = bundles[i];
            bundleHashes[i] = getBundleHash(
                bundle.id, bundle.pnft, bundle.bindables, bundle.price
            );
        }
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                purchaser,
                keccak256(abi.encodePacked(bundleHashes))
            )
        );
    }

    function getBundleHash(
        bytes32 id,
        address pnft,
        address[] memory bindables,
        uint256 price
    ) public view returns (bytes32) {
        bytes32[] memory bindableHashes = new bytes32[](bindables.length);
        return keccak256(
            abi.encode(
                BUNDLE_TYPEHASH,
                id,
                pnft,
                keccak256(abi.encodePacked(bindables)),
                price
            )
        );
    }

    function checkout(Order calldata order) external payable nonReentrant {
        (uint256 refund, bytes32 orderHash) = _verifyRefundAndOrderHash(
            order.purchaser,
            order.bundles
        );

        _verifySignature(
            order.signature,
            _deriveEIP712Digest(orderHash)
        );

        if (refund != 0) {
            _transferETH(payable(msg.sender), refund);
        }

        emit OrderFulfilled(orderHash, order.purchaser, order.bundles);
    }

    function withdraw(uint256 amount) public onlyOwner {
        if (amount < address(this).balance) {
            revert WithdrawalInvalid();
        }
        _transferETH(payable(msg.sender), amount);
    }

    function setSigner(address signer, bool setting) public onlyOwner {
        signers[signer] = setting;
        emit DopamineCheckoutSignerSet(signer, setting);
    }

    function supportsInterface(bytes4 interfaceId) public override(IERC165, Ownable) view returns (bool) {
        return interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IERC173).interfaceId;
    }


    function _verifyRefundAndOrderHash(
        address purchaser,
        Bundle[] memory bundles
    ) internal returns (uint256 refund, bytes32 hash) {
        if (bundles.length > MAX_BUNDLES) {
            revert OrderCapacityExceeded();
        }
        bytes32[] memory bundleHashes = new bytes32[](bundles.length);
        Bundle memory bundle;
        refund = msg.value;
        for (uint256 i = 0; i < bundles.length; ++i) {
            bundle = bundles[i];
            if (bundlePurchased[bundle.id]) {
                revert BundleAlreadyPurchased();
            }
            if (bundle.price > refund) {
                revert PaymentInsufficient();
            }
            refund -= bundle.price;
            bundlePurchased[bundle.id] = true;
            bundleHashes[i] = getBundleHash(
                bundle.id, bundle.pnft, bundle.bindables, bundle.price
            );
        }

        hash = keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                purchaser,
                keccak256(abi.encodePacked(bundleHashes))
            )
        );
    }

    function _transferETH(address payable to, uint256 amount) public {
        (bool success, ) = to.call{value: amount}("");
        if(!success){
            revert EthTransferFailed();
        }
    }

    function _NAME() internal override pure returns (string memory) {
        return "Dopamine Primary Checkout";
    }

    function _VERSION() internal override pure returns (string memory) {
        return "1.0";
    }

}