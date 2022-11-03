// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {RenAssetV2} from "../RenAsset/RenAsset.sol";
import {GatewayStateV3, GatewayStateManagerV3} from "./common/GatewayState.sol";
import {RenVMHashes} from "./common/RenVMHashes.sol";
import {IMintGateway} from "./interfaces/IMintGateway.sol";
import {StringV1} from "../libraries/StringV1.sol";
import {CORRECT_SIGNATURE_RETURN_VALUE_} from "./RenVMSignatureVerifier.sol";

/// MintGateway handles verifying mint and burn requests. A mintAuthority
/// approves new assets to be minted by providing a digital signature. An owner
/// of an asset can request for it to be burnt.
contract MintGatewayV3 is Initializable, ContextUpgradeable, GatewayStateV3, GatewayStateManagerV3, IMintGateway {
    string public constant NAME = "MintGateway";

    event TokenOwnershipTransferred(address indexed tokenAddress, address indexed nextTokenOwner);

    // If these parameters are changed, RenAssetFactory must be updated as well.
    function __MintGateway_init(
        string calldata asset_,
        address signatureVerifier_,
        address token_
    ) external initializer {
        __Context_init();
        __GatewayStateManager_init(asset_, signatureVerifier_, token_);
    }

    // Governance functions ////////////////////////////////////////////////////

    /// @notice Allow the owner to update the owner of the RenERC20 token.
    function transferTokenOwnership(address nextTokenOwner) external onlySignatureVerifierOwner {
        require(AddressUpgradeable.isContract(nextTokenOwner), "MintGateway: next token owner must be a contract");
        require(nextTokenOwner != address(0x0), "MintGateway: invalid next token owner");

        address token_ = getToken();
        RenAssetV2(token_).transferOwnership(address(nextTokenOwner));

        emit TokenOwnershipTransferred(token_, nextTokenOwner);
    }

    // PUBLIC FUNCTIONS ////////////////////////////////////////////////////////

    /// @notice mint verifies a mint approval signature from RenVM and creates
    ///         tokens after taking a fee for the `_feeRecipient`.
    ///
    /// @param pHash (payload hash) The hash of the payload associated with the
    ///        mint.
    /// @param amount The amount of the token being minted, in its smallest
    ///        value. (e.g. satoshis for BTC).
    /// @param nHash (nonce hash) The hash of the nonce, amount and pHash.
    /// @param sig The signature of the hash of the following values:
    ///        (pHash, amount, recipient, nHash), signed by the mintAuthority.
    function mint(
        bytes32 pHash,
        uint256 amount,
        bytes32 nHash,
        bytes calldata sig
    ) external override returns (uint256) {
        return _mint(pHash, amount, nHash, sig, _msgSender());
    }

    /// @notice burnWithPayload allows minted assets to be released to their
    ///         native chain, or to another chain as specified by the chain and
    ///         payload parameters.
    ///         WARNING: Burning with invalid parameters can cause the funds to
    ///         become unrecoverable.
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
    function burnWithPayload(
        string calldata recipientAddress,
        string calldata recipientChain,
        bytes calldata recipientPayload,
        uint256 amount
    ) external override returns (uint256) {
        return _burnWithPayload(recipientAddress, recipientChain, recipientPayload, amount, _msgSender());
    }

    /// @notice burn is a convenience function that is equivalent to calling
    ///         `burnWithPayload` with an empty payload and chain, releasing
    ///         the asset to the native chain.
    function burn(string calldata recipient, uint256 amount) external virtual override returns (uint256) {
        return _burnWithPayload(recipient, "", "", amount, _msgSender());
    }

    /// Same as `burn` with the recipient parameter being `bytes` instead of
    /// a `string`. For backwards compatibility with the MintGatewayV2.
    function burn(bytes calldata recipient, uint256 amount) external virtual override returns (uint256) {
        return _burnWithPayload(string(recipient), "", "", amount, _msgSender());
    }

    function _mintFromPreviousGateway(
        bytes32 pHash,
        uint256 amount,
        bytes32 nHash,
        bytes calldata sig,
        address caller
    ) external onlyPreviousGateway returns (uint256) {
        return _mint(pHash, amount, nHash, sig, caller);
    }

    function _burnFromPreviousGateway(
        string calldata recipientAddress,
        string calldata recipientChain,
        bytes calldata recipientPayload,
        uint256 amount,
        address caller
    ) external onlyPreviousGateway returns (uint256) {
        return _burnWithPayload(string(recipientAddress), recipientChain, recipientPayload, amount, caller);
    }

    // INTERNAL FUNCTIONS //////////////////////////////////////////////////////

    function _mint(
        bytes32 pHash,
        uint256 amount,
        bytes32 nHash,
        bytes memory sig,
        address recipient
    ) internal returns (uint256) {
        // Calculate the hash signed by RenVM. This binds the payload hash,
        // amount, recipient and nonce hash to the signature.
        bytes32 sigHash = RenVMHashes.calculateSigHash(pHash, amount, getSelectorHash(), recipient, nHash);

        // Check that the signature hasn't been redeemed.
        require(!status(sigHash), "MintGateway: signature already spent");

        // If the signature fails verification, throw an error.
        // `isValidSignature` must return an exact bytes4 value, to avoid
        // a contract mistakingly returning a truthy value without intending to.
        if (getSignatureVerifier().isValidSignature(sigHash, sig) != CORRECT_SIGNATURE_RETURN_VALUE_) {
            revert(
                string(
                    abi.encodePacked(
                        "MintGateway: invalid signature. phash: ",
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

        // Update the status for the signature hash.
        _status[sigHash] = true;

        // Mint the amount to the recipient.
        RenAssetV2(getToken()).mint(recipient, amount);

        // Emit mint log. For backwards compatiblity reasons, the sigHash is
        // cast to a uint256.
        emit LogMint(recipient, amount, uint256(sigHash), nHash);

        return amount;
    }

    /// @notice burn destroys tokens after taking a fee for the `_feeRecipient`,
    ///         allowing the associated assets to be released on their native
    ///         chain.
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
    function _burnWithPayload(
        string memory recipientAddress,
        string memory recipientChain,
        bytes memory recipientPayload,
        uint256 amount,
        address caller
    ) internal returns (uint256) {
        // The recipient must not be empty. Better validation is possible,
        // but would need to be customized for each destination ledger.
        require(StringV1.isNotEmpty(recipientAddress), "MintGateway: to address is empty");

        // Burn the tokens. If the user doesn't have enough tokens, this will
        // throw.
        RenAssetV2(getToken()).burn(caller, amount);

        uint256 burnNonce = getEventNonce();

        // If a paylaod of recipient chain has been included, emit more detailed
        // event.
        if (StringV1.isNotEmpty(recipientChain) || recipientPayload.length > 0) {
            emit LogBurnToChain(
                recipientAddress,
                recipientChain,
                recipientPayload,
                amount,
                burnNonce,
                recipientAddress,
                recipientChain
            );
        } else {
            emit LogBurn(bytes(recipientAddress), amount, burnNonce, bytes(recipientAddress));
        }

        _eventNonce = burnNonce + 1;

        return amount;
    }
}