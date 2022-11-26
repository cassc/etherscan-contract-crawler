// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import { ICharge } from "../../../interfaces/core/organization/modules/ICharge.sol";
import { Base } from "./Base.sol";
import { Charge as ChargeStruct, Signature } from "../../../static/Structs.sol";
import { ECDSA } from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import { ERC20 } from "openzeppelin-contracts/token/ERC20/ERC20.sol";

abstract contract Charge is Base, ICharge {
    using ECDSA for bytes32;

    /*******************************
     * Errors *
     *******************************/

    error InvalidChargeSignatureVerification();
    error InvalidChargeAmount();
    error ChargeTotalAmountMismatch();

    /*******************************
     * State vars *
     *******************************/

    /**
     * @notice Gap array, for further state variable changes
     */
    uint256[50] private __gap;

    /*******************************
     * Functions start *
     *******************************/

    function charge(ChargeStruct calldata chargeRequest, Signature calldata signature) external onlyDiagonalBot {
        _verifyChargeRequest(chargeRequest, signature);

        _charge(chargeRequest);
    }

    function chargeWithPermit(
        ChargeStruct calldata chargeRequest,
        Signature calldata signature,
        bytes calldata permit
    ) external onlyDiagonalBot {
        _verifyChargeRequest(chargeRequest, signature);

        _safeCall(chargeRequest.token, permit);

        _charge(chargeRequest);
    }

    function _verifyChargeRequest(ChargeStruct calldata chargeRequest, Signature calldata signature) internal {
        if (chargeRequest.amount == 0) {
            revert InvalidChargeAmount();
        }
        _verifyAndSetNewOperationId(chargeRequest.id);
        _verifyChargeSignature(chargeRequest, signature);
    }

    function _charge(ChargeStruct calldata chargeRequest) internal {
        uint256 totalAmount = chargeRequest.amount;

        for (uint256 i = 0; i < chargeRequest.payouts.length; i++) {
            // reverts on underflow
            totalAmount -= chargeRequest.payouts[i].amount;

            _safeCall(
                chargeRequest.token,
                abi.encodeWithSelector(
                    ERC20.transferFrom.selector,
                    chargeRequest.source,
                    chargeRequest.payouts[i].receiver,
                    chargeRequest.payouts[i].amount
                )
            );
        }

        if (totalAmount != 0) {
            revert ChargeTotalAmountMismatch();
        }
    }

    function _verifyChargeSignature(ChargeStruct calldata chargeRequest, Signature calldata signature) private view {
        bytes32 digest = keccak256(
            abi.encode(
                chargeRequest.id,
                chargeRequest.source,
                chargeRequest.token,
                chargeRequest.amount,
                address(this),
                block.chainid
            )
        );
        address _signer = ECDSA.recover(digest, signature.v, signature.r, signature.s);
        if (signer != _signer) revert InvalidChargeSignatureVerification();
    }
}