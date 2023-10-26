// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/**
 * @title LoanReceipt
 * @author MetaStreet Labs
 */
library LoanReceipt {
    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Invalid receipt encoding
     */
    error InvalidReceiptEncoding();

    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Loan receipt version
     */
    uint8 internal constant LOAN_RECEIPT_VERSION = 2;

    /**
     * @notice Loan receipt header size in bytes
     * @dev Header excludes borrow options byte array
     */
    uint256 internal constant LOAN_RECEIPT_HEADER_SIZE = 187;

    /**
     * @notice Loan receipt node receipt size in bytes
     */
    uint256 internal constant LOAN_RECEIPT_NODE_RECEIPT_SIZE = 48;

    /**************************************************************************/
    /* Structures */
    /**************************************************************************/

    /**
     * @notice LoanReceiptV2
     * @param version Version (2)
     * @param principal Principal amount in currency tokens
     * @param repayment Repayment amount in currency tokens
     * @param adminFee Admin fee amount in currency tokens
     * @param borrower Borrower
     * @param maturity Loan maturity timestamp
     * @param duration Loan duration
     * @param collateralToken Collateral token
     * @param collateralTokenId Collateral token ID
     * @param collateralWrapperContextLen Collateral wrapper context length
     * @param collateralWrapperContext Collateral wrapper context data
     * @param nodeReceipts Node receipts
     */
    struct LoanReceiptV2 {
        uint8 version;
        uint256 principal;
        uint256 repayment;
        uint256 adminFee;
        address borrower;
        uint64 maturity;
        uint64 duration;
        address collateralToken;
        uint256 collateralTokenId;
        uint16 collateralWrapperContextLen;
        bytes collateralWrapperContext;
        NodeReceipt[] nodeReceipts;
    }

    /**
     * @notice Node receipt
     * @param tick Tick
     * @param used Used amount
     * @param pending Pending amount
     */
    struct NodeReceipt {
        uint128 tick;
        uint128 used;
        uint128 pending;
    }

    /**************************************************************************/
    /* Tightly packed format */
    /**************************************************************************/

    /*
      Header (187 bytes)
          1   uint8   version                        0:1
          32  uint256 principal                      1:33
          32  uint256 repayment                      33:65
          32  uint256 adminFee                       65:97
          20  address borrower                       97:117
          8   uint64  maturity                       117:125
          8   uint64  duration                       125:133
          20  address collateralToken                133:153
          32  uint256 collateralTokenId              153:185
          2   uint16  collateralWrapperContextLen    185:187

      Collateral Wrapper Context Data (M bytes)      187:---

      Node Receipts (48 * N bytes)
          N   NodeReceipts[] nodeReceipts
              16  uint128 tick
              16  uint128 used
              16  uint128 pending
    */

    /**************************************************************************/
    /* API */
    /**************************************************************************/

    /**
     * @dev Compute loan receipt hash
     * @param encodedReceipt Encoded loan receipt
     * @return Loan Receipt hash
     */
    function hash(bytes memory encodedReceipt) internal view returns (bytes32) {
        /* Take hash of chain ID (32 bytes) concatenated with encoded loan receipt */
        return keccak256(abi.encodePacked(block.chainid, encodedReceipt));
    }

    /**
     * @dev Encode a loan receipt into bytes
     * @param receipt Loan Receipt
     * @return Encoded loan receipt
     */
    function encode(LoanReceiptV2 memory receipt) internal pure returns (bytes memory) {
        /* Encode header */
        bytes memory header = abi.encodePacked(
            receipt.version,
            receipt.principal,
            receipt.repayment,
            receipt.adminFee,
            receipt.borrower,
            receipt.maturity,
            receipt.duration,
            receipt.collateralToken,
            receipt.collateralTokenId,
            receipt.collateralWrapperContextLen,
            receipt.collateralWrapperContext
        );

        /* Encode node receipts */
        bytes memory nodeReceipts;
        for (uint256 i; i < receipt.nodeReceipts.length; i++) {
            nodeReceipts = abi.encodePacked(
                nodeReceipts,
                receipt.nodeReceipts[i].tick,
                receipt.nodeReceipts[i].used,
                receipt.nodeReceipts[i].pending
            );
        }

        return abi.encodePacked(header, nodeReceipts);
    }

    /**
     * @dev Decode a loan receipt from bytes
     * @param encodedReceipt Encoded loan Receipt
     * @return Decoded loan receipt
     */
    function decode(bytes calldata encodedReceipt) internal pure returns (LoanReceiptV2 memory) {
        /* Validate encoded receipt length */
        if (encodedReceipt.length < LOAN_RECEIPT_HEADER_SIZE) revert InvalidReceiptEncoding();

        uint256 collateralWrapperContextLen = uint16(bytes2(encodedReceipt[185:187]));

        /* Validate length with collateral wrapper context */
        if (encodedReceipt.length < LOAN_RECEIPT_HEADER_SIZE + collateralWrapperContextLen)
            revert InvalidReceiptEncoding();

        /* Validate length with node receipts */
        if (
            (encodedReceipt.length - LOAN_RECEIPT_HEADER_SIZE - collateralWrapperContextLen) %
                LOAN_RECEIPT_NODE_RECEIPT_SIZE !=
            0
        ) revert InvalidReceiptEncoding();

        /* Validate encoded receipt version */
        if (uint8(encodedReceipt[0]) != LOAN_RECEIPT_VERSION) revert InvalidReceiptEncoding();

        LoanReceiptV2 memory receipt;

        /* Decode header */
        receipt.version = uint8(encodedReceipt[0]);
        receipt.principal = uint256(bytes32(encodedReceipt[1:33]));
        receipt.repayment = uint256(bytes32(encodedReceipt[33:65]));
        receipt.adminFee = uint256(bytes32(encodedReceipt[65:97]));
        receipt.borrower = address(uint160(bytes20(encodedReceipt[97:117])));
        receipt.maturity = uint64(bytes8(encodedReceipt[117:125]));
        receipt.duration = uint64(bytes8(encodedReceipt[125:133]));
        receipt.collateralToken = address(uint160(bytes20(encodedReceipt[133:153])));
        receipt.collateralTokenId = uint256(bytes32(encodedReceipt[153:185]));
        receipt.collateralWrapperContextLen = uint16(collateralWrapperContextLen);
        receipt.collateralWrapperContext = encodedReceipt[187:187 + collateralWrapperContextLen];

        /* Decode node receipts */
        uint256 numNodeReceipts = (encodedReceipt.length - LOAN_RECEIPT_HEADER_SIZE - collateralWrapperContextLen) /
            LOAN_RECEIPT_NODE_RECEIPT_SIZE;
        receipt.nodeReceipts = new NodeReceipt[](numNodeReceipts);
        uint256 offset = LOAN_RECEIPT_HEADER_SIZE + collateralWrapperContextLen;
        for (uint256 i; i < numNodeReceipts; i++) {
            receipt.nodeReceipts[i].tick = uint128(bytes16(encodedReceipt[offset:offset + 16]));
            receipt.nodeReceipts[i].used = uint128(bytes16(encodedReceipt[offset + 16:offset + 32]));
            receipt.nodeReceipts[i].pending = uint128(bytes16(encodedReceipt[offset + 32:offset + 48]));
            offset += LOAN_RECEIPT_NODE_RECEIPT_SIZE;
        }

        return receipt;
    }
}