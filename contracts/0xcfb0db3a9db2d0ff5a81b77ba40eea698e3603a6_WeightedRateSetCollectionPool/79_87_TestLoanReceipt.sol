// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../interfaces/ILiquidity.sol";

import "../LoanReceipt.sol";

/**
 * @title Test Contract Wrapper for LoanReceipt Library
 * @author MetaStreet Labs
 */
contract TestLoanReceipt {
    /**
     * @dev External wrapper function for LoanReceipt.hash()
     */
    function hash(bytes calldata encodedReceipt) external view returns (bytes32) {
        return LoanReceipt.hash(encodedReceipt);
    }

    /**
     * @dev External wrapper function for LoanReceipt.encode()
     */
    function encode(LoanReceipt.LoanReceiptV2 memory receipt) external pure returns (bytes memory) {
        return LoanReceipt.encode(receipt);
    }

    /**
     * @dev External wrapper function for LoanReceipt.decode()
     */
    function decode(bytes calldata encodedReceipt) external pure returns (LoanReceipt.LoanReceiptV2 memory) {
        return LoanReceipt.decode(encodedReceipt);
    }
}