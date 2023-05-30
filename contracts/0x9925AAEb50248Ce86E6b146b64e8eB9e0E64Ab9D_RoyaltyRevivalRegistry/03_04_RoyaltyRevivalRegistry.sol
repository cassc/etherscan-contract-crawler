// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "./ERC20.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";
import {Owned} from "./Owned.sol";

/// @title RoyaltyRevivalRegistry
/// @notice Enables paying royalties, after the fact, to specified collection royalty wallets
contract RoyaltyRevivalRegistry is Owned {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    /// @notice Specifies a single royalty payment request
    struct RoyaltyPaymentRequest {
        address collection;
        address royaltyRecipient;
        uint256 tokenId;
        uint256 quantity; // For ERC721s, should always be 1
        address paymentToken;
        uint256 paymentAmount;
        bytes32 originalTransactionHash; // Should refer to the original transaction that lacks a full royalty payment
    }

    /// @notice Specifies the data for royalty payment logs
    struct RoyaltyData {
        // Asset info
        address collection;
        uint256 tokenId;
        uint256 quantity;
        // Royalty info
        address paymentToken;
        uint256 paymentAmount;
    }

    /// @notice Emitted when a royalty payment is made
    event RoyaltyPaid(
        address indexed royaltyPayer,
        address indexed royaltyRecipient,
        bytes32 indexed originalTransactionHash,
        RoyaltyData payment
    );

    /// @notice Sets the contract's owner to msg.sender.
    constructor() Owned(msg.sender) {}

    /// @notice Pays one or more royalty fees.
    /// @param _royalties Royalty payment request data.
    function payRoyalties(RoyaltyPaymentRequest[] calldata _royalties) external payable {
        uint256 royaltiesLength = _royalties.length;
        for (uint256 i = 0; i < royaltiesLength; ) {
            _executeRoyaltyPayment(_royalties[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _executeRoyaltyPayment(RoyaltyPaymentRequest calldata _payment) internal {
        // Transfer funds
        _transferFunds(_payment.paymentToken, msg.sender, _payment.royaltyRecipient, _payment.paymentAmount);

        // Log payment
        RoyaltyData memory paymentData = RoyaltyData(
            _payment.collection,
            _payment.tokenId,
            _payment.quantity,
            _payment.paymentToken,
            _payment.paymentAmount
        );
        emit RoyaltyPaid(msg.sender, _payment.royaltyRecipient, _payment.originalTransactionHash, paymentData);
    }

    function _transferFunds(address token, address from, address to, uint256 amount) internal {
        if (token == address(0)) {
            payable(to).safeTransferETH(amount);
        } else {
            ERC20(token).safeTransferFrom(from, to, amount);
        }
    }

    /// @notice Rescue any funds stuck in this contract
    function rescueFunds(address _token, address _to, uint256 _amount) external onlyOwner {
        _transferFunds(_token, address(this), _to, _amount);
    }
}