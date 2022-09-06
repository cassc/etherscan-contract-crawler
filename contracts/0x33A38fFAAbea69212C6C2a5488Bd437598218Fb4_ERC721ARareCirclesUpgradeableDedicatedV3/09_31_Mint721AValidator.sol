// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract Mint721AValidator is EIP712Upgradeable {
    function __Mint721AValidator_init_unchained() internal initializer {
        __EIP712_init_unchained("Rarecircles", "1");
    }

    function validate(address signer, bytes32 structHash, bytes memory signature) internal view {
        bytes32 encodedHash = _hashTypedDataV4(structHash);
        require(ECDSAUpgradeable.recover(encodedHash, signature) == signer, "RC: signature verification error");
    }

    function getValidator(bytes32 structHash, bytes memory signature) internal view returns (address signer) {
        bytes32 encodedHash = _hashTypedDataV4(structHash);
        signer = ECDSAUpgradeable.recover(encodedHash, signature);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}