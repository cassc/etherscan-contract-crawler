pragma solidity 0.8.4;

import {Offer, Signature} from "../DataTypes.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";


library SigningUtils {
    
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    

    function offerSignatureIsValid(
        Offer memory _offer,
        uint256 _nftId,
        Signature memory _signature
    ) internal view returns(bool) {
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

    
    function offerSignatureIsValid(
        Offer memory _offer,
        Signature memory _signature
    ) internal view returns (bool) {
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

    
    function getEncodedOffer(Offer memory _offer) internal pure returns (bytes memory data) {
            data = 
                abi.encodePacked(
                    _offer.borrowAsset,
                    _offer.borrowAmount,
                    _offer.repayAmount,
                    _offer.nftAsset,
                    _offer.borrowDuration,
                    _offer.adminShare,
                    _offer.timestamp
                );
    }

    
    function getEncodedSignature(Signature memory _signature) internal pure returns (bytes memory) {
        return abi.encodePacked(_signature.signer, _signature.nonce, _signature.expiry);
    }
}