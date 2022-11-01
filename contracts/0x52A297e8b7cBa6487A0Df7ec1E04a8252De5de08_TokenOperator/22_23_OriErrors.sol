// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

/**
 * @dev Revert with an error when a signature that does not contain a v
 *      value of 27 or 28 has been supplied.
 *
 * @param v The invalid v value.
 */
error BadSignatureV(uint8 v);

/**
 * @dev Revert with an error when the signer recovered by the supplied
 *      signature does not match the offerer or an allowed EIP-1271 signer
 *      as specified by the offerer in the event they are a contract.
 */
error InvalidSigner();

/**
 * @dev Revert with an error when a signer cannot be recovered from the
 *      supplied signature.
 */
error InvalidSignature();

/**
 * @dev Revert with an error when an EIP-1271 call to an account fails.
 */
error BadContractSignature();

/**
 * @dev Revert with an error when low-level call with value failed without reason.
 */
error UnknownLowLevelCallFailed();

/**
 * @dev Errors that occur when NFT expires transfer
 */
error expiredError(uint256 id);

/**
 * @dev atomicApproveForAll:approve to op which no implementer
 */
error atomicApproveForAllNoImpl();

/**
 * @dev address in not contract
 */
error notContractError();

/**
 * @dev not support EIP NFT error
 */
error notSupportNftTypeError();

/**
 * @dev not support TokenKind  error
 */
error notSupportTokenKindError();

/**
 * @dev not support function  error
 */
error notSupportFunctionError();

error nftEditorIsEmpty();

error invalidTokenType();

error notFoundLicenseToken();

error amountIsZero();