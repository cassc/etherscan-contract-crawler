//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
contract Signer is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "Walts_Vault";
    string private constant SIGNATURE_VERSION = "1";

    struct signedData {
        uint256 nonce;
        uint256 allocatedSpots;
        address userAddress;
        bytes signature;
    }
    
    /**
    @notice This is initializer function is used to initialize values of contracts
    */
    function __Signer_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }

    /**
    @dev This function is used to get signer address of signature
    @param _signedData signedData object
    */
    function getSigner(signedData memory _signedData) public view returns (address) {
        return _verifyOrder(_signedData);

    }
    
    /**
    @dev This function is used to generate hash message
    @param _signedData signedData object to create hash
    */
    function _signedDataHash(signedData memory _signedData) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("signedData(uint256 nonce,uint256 allocatedSpots,address userAddress)"),
                    _signedData.nonce,
                    _signedData.allocatedSpots,
                    _signedData.userAddress
                )
            )
        );
    }

    /**
    @dev This function is used to verify signature
    @param _signedData signedData object to verify
    */
    function _verifyOrder(signedData memory _signedData) internal view returns (address) {
        bytes32 digest = _signedDataHash(_signedData);
        return ECDSAUpgradeable.recover(digest, _signedData.signature);
    }
}