//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract MagicSigner is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "MagicCraft";
    string private constant SIGNATURE_VERSION = "1";

    struct WhiteList {
        address userAddress;
        bytes signature;
    }

    function __MagicSigner_init() internal onlyInitializing {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }

    function getSigner(WhiteList memory magic) public view returns (address) {
        return _verify(magic);
    }

    /// @notice Returns a hash of the given rarity, prepared using EIP712 typed data hashing rules.

    function _hash(WhiteList memory magic) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(keccak256("WhiteList(address userAddress)"), magic.userAddress)
                )
            );
    }

    function _verify(WhiteList memory magic) internal view returns (address) {
        bytes32 digest = _hash(magic);
        return ECDSAUpgradeable.recover(digest, magic.signature);
    }

    function getChainID() external view returns (uint256) {
        uint256 id;

        assembly {
            id := chainid()
        }

        return id;
    }
}