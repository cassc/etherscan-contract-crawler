// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable reason-string */
/* solhint-disable no-inline-assembly */

import "../core/BasePaymaster.sol";
/**
 * A sample paymaster that uses external service to decide whether to pay for the UserOp.
 * The paymaster trusts an external signer to sign the transaction.
 * The calling user must pass the UserOp to that external signer first, which performs
 * whatever off-chain verification before signing the UserOp.
 * Note that this signature is NOT a replacement for the account-specific signature:
 * - the paymaster checks a signature to agree to PAY for GAS.
 * - the account checks a signature to prove identity and account ownership.
 */
contract OriginBoundPaymaster is BasePaymaster {
    address public immutable allowedOrigin;

    uint256 private constant VALID_TIMESTAMP_OFFSET = 20;


    constructor(IEntryPoint _entryPoint, address _allowedOrigin) BasePaymaster(_entryPoint) {
        allowedOrigin = _allowedOrigin;
    }

    /**
     * verify our external signer signed this request.
     * the "paymasterAndData" is expected to be the paymaster and a signature over the entire request params
     * paymasterAndData[:20] : address(this)
     * paymasterAndData[20:84] : abi.encode(validUntil, validAfter)
     * paymasterAndData[84:] : signature
     */
    function _validatePaymasterUserOp(UserOperation calldata /*userOp*/, bytes32 /*userOpHash*/, uint256 requiredPreFund)
    internal     view
override returns (bytes memory context, uint256 validationData) {
        (requiredPreFund);

        //don't revert on signature failure: return SIG_VALIDATION_FAILED
        if (allowedOrigin != tx.origin) {
            return ("",_packValidationData(true,0,0));
        }

        //no need for other on-chain validation: entire UserOp should have been checked
        // by the external service prior to signing it.
        return ("",_packValidationData(false,0,0));
    }
}