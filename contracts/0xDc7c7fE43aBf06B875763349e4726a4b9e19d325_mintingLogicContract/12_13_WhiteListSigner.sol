//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "hardhat/console.sol";
contract Whitelist is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "PassengersWhitelistList";
    string private constant SIGNATURE_VERSION = "1";

    struct whitelist {
        address userAddress;
        uint256 listType;
        bytes signature;
    }

    /**
    @notice This is initializer function is used to initialize values of contracts
    */
    function __WhiteList_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }

    /**
    @dev This function is used to get signer address of signature
    @param _whitelist whitelist object
    */
    function getSigner(whitelist memory _whitelist) public view returns (address) {
        return _verify(_whitelist);

    }

    /**
    @dev This function is used to generate hash message
    @param _whitelist whitelist object to create hash
    */
    function _hash(whitelist memory _whitelist) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("whitelist(address userAddress,uint256 listType)"),
                    _whitelist.userAddress,
                    _whitelist.listType
                )
            )
        );
    }

    /**
    @dev This function is used to verify signature   
    @param _whitelist whitelist object to verify    
    */
    function _verify(whitelist memory _whitelist) internal view returns (address) {
        bytes32 digest = _hash(_whitelist);
        return ECDSAUpgradeable.recover(digest, _whitelist.signature);
    }
}