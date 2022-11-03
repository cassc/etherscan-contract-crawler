// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {SafeTransferWithFeesUpgradeable} from "./common/SafeTransferWithFees.sol";
import {GatewayStateV3, GatewayStateManagerV3} from "./common/GatewayState.sol";
import {RenVMHashes} from "./common/RenVMHashes.sol";
import {ILockGateway} from "./interfaces/ILockGateway.sol";
import {CORRECT_SIGNATURE_RETURN_VALUE_} from "./RenVMSignatureVerifier.sol";
import {RenAssetV2} from "../RenAsset/RenAsset.sol";
import {StringV1} from "../libraries/StringV1.sol";

/// LockGatewayV3 handles verifying lock and release requests. A mint authority
/// approves assets being released by providing a digital signature.
/// The balance of assets is assumed not to change without a transfer, so
/// rebasing assets and assets with a demurrage fee are not supported.
contract LockGatewayV3 is Initializable, ContextUpgradeable, GatewayStateV3, GatewayStateManagerV3, ILockGateway {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeTransferWithFeesUpgradeable for IERC20Upgradeable;

    string public constant NAME = "LockGateway";

    // If these parameters are changed, RenAssetFactory must be updated as well.
    function __LockGateway_init(
        string calldata asset_,
        address signatureVerifier_,
        address token_
    ) external initializer {
        __Context_init();
        __GatewayStateManager_init(asset_, signatureVerifier_, token_);
    }

    // Public functions ////////////////////////////////////////////////////////

    /// @notice Transfers tokens into custody by this contract so that they
    ///         can be minted on another chain.
    ///
    /// @param recipientAddress The address to which the locked assets will be
    ///        minted to. The address should be a plain-text address, without
    ///        decoding to bytes first.
    /// @param recipientChain The target chain to which the assets are being
    ///        moved to.
    /// @param recipientPayload An optional payload to be passed to the
    ///        recipient chain along with the address.
    /// @param amount The amount of the token being locked, in the asset's
    ///        smallest unit. (e.g. satoshis for BTC)
    function lock(
        string calldata recipientAddress,
        string calldata recipientChain,
        bytes calldata recipientPayload,
        uint256 amount
    ) external override returns (uint256) {
        // The recipient must not be empty. Better validation is possible,
        // but would need to be customized for each destination ledger.
        require(StringV1.isNotEmpty(recipientAddress), "LockGateway: to address is empty");

        // Lock the tokens. If the user doesn't have enough tokens, this will
        // throw. Note that some assets may transfer less than the provided
        // `amount`, due to transfer fees.
        uint256 transferredAmount = IERC20Upgradeable(getToken()).safeTransferFromWithFees(
            _msgSender(),
            address(this),
            amount
        );

        // Get the latest nonce (also known as lock reference).
        uint256 lockNonce = getEventNonce();

        emit LogLockToChain(
            recipientAddress,
            recipientChain,
            recipientPayload,
            transferredAmount,
            lockNonce,
            recipientAddress,
            recipientChain
        );

        _eventNonce = lockNonce + 1;

        return transferredAmount;
    }

    /// @notice release verifies a release approval signature from RenVM and
    ///         transfers the asset out of custody and to the recipient.
    ///
    /// @param pHash (payload hash) The hash of the payload associated with the
    ///        release.
    /// @param amount The amount of the token being released, in its smallest
    ///        value.
    /// @param nHash (nonce hash) The hash of the nonce, amount and pHash.
    /// @param sig The signature of the hash of the following values:
    ///        (pHash, amount, recipient, nHash), signed by the mintAuthority.
    function release(
        bytes32 pHash,
        uint256 amount,
        bytes32 nHash,
        bytes calldata sig
    ) external override returns (uint256) {
        // The recipient must match the value signed by RenVM.
        address recipient = _msgSender();

        // Calculate the hash signed by RenVM. This binds the payload hash,
        // amount, recipient and nonce hash to the signature.
        bytes32 sigHash = RenVMHashes.calculateSigHash(pHash, amount, getSelectorHash(), recipient, nHash);

        // Check that the signature hasn't been redeemed.
        require(!status(sigHash), "LockGateway: signature already spent");

        // If the signature fails verification, throw an error.
        // `isValidSignature` must return an exact bytes4 value, to avoid
        // a contract mistakingly returning a truthy value without intending to.
        if (getSignatureVerifier().isValidSignature(sigHash, sig) != CORRECT_SIGNATURE_RETURN_VALUE_) {
            revert(
                string(
                    abi.encodePacked(
                        "LockGateway: invalid signature. phash: ",
                        StringsUpgradeable.toHexString(uint256(pHash), 32),
                        ", amount: ",
                        StringsUpgradeable.toString(amount),
                        ", shash",
                        StringsUpgradeable.toHexString(uint256(getSelectorHash()), 32),
                        ", msg.sender: ",
                        StringsUpgradeable.toHexString(uint160(recipient), 20),
                        ", nhash: ",
                        StringsUpgradeable.toHexString(uint256(nHash), 32)
                    )
                )
            );
        }

        // Update the status for both the signature hash and the nHash.
        _status[sigHash] = true;

        // Release the amount to the recipient.
        IERC20Upgradeable(getToken()).safeTransfer(recipient, amount);

        // Emit a log with a unique identifier 'n'.
        emit LogRelease(recipient, amount, sigHash, nHash);

        return amount;
    }
}