// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import {Offer, Signature} from "../DataTypes.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @title  SigningUtils
 * @author XY3
 * @notice Helper functions for signature.
 */
library SigningUtils {
    /**
     * @dev Get the current chain ID.
     */
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /**
     * @dev check signature without nftId.
     * @param _offer  The offer data
     * @param _nftId The NFT Id
     * @param _signature The signature data
     */

    function offerSignatureIsValid(
        Offer memory _offer,
        uint256 _nftId,
        Signature memory _signature
    ) public view returns(bool) {
        require(block.timestamp <= _signature.expiry, "Signature expired");
        if (_signature.signer == address(0)) {
            return false;
        } else {
            bytes32 message = keccak256(
                abi.encodePacked(getEncodedOffer(_offer), _nftId, getEncodedSignature(_signature), address(this), getChainID())
            );
            return
                SignatureChecker.isValidSignatureNow(
                    _signature.signer,
                    ECDSA.toEthSignedMessageHash(message),
                    _signature.signature
                );
        }
    }

    /**
     * @dev check signature without nftId.
     * @param _offer  The offer data
     * @param _signature - The signature data
     */
    function offerSignatureIsValid(
        Offer memory _offer,
        Signature memory _signature
    ) public view returns (bool) {
        require(block.timestamp <= _signature.expiry, "Signature has expired");
        if (_signature.signer == address(0)) {
            return false;
        } else {
            bytes32 message = keccak256(
                abi.encodePacked(getEncodedOffer(_offer), getEncodedSignature(_signature), address(this), getChainID())
            );

            return
                SignatureChecker.isValidSignatureNow(
                    _signature.signer,
                    ECDSA.toEthSignedMessageHash(message),
                    _signature.signature
                );
        }
    }

    /**
     * @dev Helper function.
     */
    function getEncodedOffer(Offer memory _offer) internal pure returns (bytes memory data) {
            data = 
                abi.encodePacked(
                    _offer.borrowAsset,
                    _offer.borrowAmount,
                    _offer.repayAmount,
                    _offer.nftAsset,
                    _offer.borrowDuration,
                    _offer.timestamp,
                    _offer.extra
                );
    }

    /**
     * @dev Helper function.
     */
    function getEncodedSignature(Signature memory _signature) internal pure returns (bytes memory) {
        return abi.encodePacked(_signature.signer, _signature.nonce, _signature.expiry);
    }
}