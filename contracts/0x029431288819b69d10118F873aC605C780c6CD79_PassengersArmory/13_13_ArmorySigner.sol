//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract ArmorySigner is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "PassengersArmory";
    string private constant SIGNATURE_VERSION = "1";
    
    struct Gear {
        uint8 actionType;
        uint64 nonce;
        uint256 encodedData;
        address userAddress;
        address assetAddress;
        bytes signature;
    }
    
    /**
    @notice This is initializer function is used to initialize values of contracts
    */
    function __Armoury_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }
    
    /**
    @dev This function is used to get signer address of signature
    @param gear Gear object
    */
    function getSigner(Gear memory gear) public view returns (address) {
        return _verify(gear);
        
    }
    
    /**
    @dev This function is used to generate hash message
    @param gear whitelist object to create hash
    */
    function _hash(Gear memory gear) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
        "Gear(uint8 actionType,uint64 nonce,uint256 encodedData,address userAddress,address assetAddress)"),
                    gear.actionType,
                    gear.nonce,
                    gear.encodedData,
                    gear.userAddress,
                    gear.assetAddress
                )
            )
        );
    }
    
    /**
    @dev This function is used to verify signature
    @param gear whitelist object to verify
    */
    function _verify(Gear memory gear) internal view returns (address) {
        bytes32 digest = _hash(gear);
        return ECDSAUpgradeable.recover(digest, gear.signature);
    }
}