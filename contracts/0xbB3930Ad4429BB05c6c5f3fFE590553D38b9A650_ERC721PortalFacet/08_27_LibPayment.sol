// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Stores information about Payment Tokens
library LibPayment {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 constant PAYMENT_STORAGE_POSITION = keccak256("payment.storage");

    struct PaymentStorage {
        // Stores all supported tokens as payments for ERC-721
        EnumerableSet.AddressSet tokens;
    }

    function paymentStorage()
        internal
        pure
        returns (PaymentStorage storage ps)
    {
        bytes32 position = PAYMENT_STORAGE_POSITION;

        assembly {
            ps.slot := position
        }
    }

    /// @notice Returns the count of payment tokens
    function tokensCount() internal view returns (uint256) {
        PaymentStorage storage ps = paymentStorage();
        return ps.tokens.length();
    }

    /// @notice Returns the address of the payment token at a given index
    function tokenAt(uint256 _index) internal view returns (address) {
        PaymentStorage storage ps = paymentStorage();
        return ps.tokens.at(_index);
    }

    function updatePaymentToken(address _paymentToken, bool _status) internal {
        PaymentStorage storage ps = paymentStorage();
        if (_status) {
            require(
                ps.tokens.add(_paymentToken),
                "LibPayment: payment token already added"
            );
        } else {
            require(
                ps.tokens.remove(_paymentToken),
                "LibPayment: payment token not found"
            );
        }
    }

    /// @notice Returns true/false depending on whether a given payment token is found
    function containsPaymentToken(address _token) internal view returns (bool) {
        PaymentStorage storage ps = paymentStorage();
        return ps.tokens.contains(_token);
    }
}