//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract Whitelist is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "SupperClub";
    string private constant SIGNATURE_VERSION = "1";

    struct whitelist {
        address userAddress;
        bool isOgList;
        bytes signature;
    }

    function __SupperClubSigner_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
    }

    function getSigner(whitelist memory supper) public view returns (address) {
        return _verify(supper);
    }

    /// @notice Returns a hash of the given rarity, prepared using EIP712 typed data hashing rules.

    function _hash(whitelist memory supper) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "whitelist(address userAddress,bool isOgList)"
                    ),
                    supper.userAddress,
                    supper.isOgList
                )
            )
        );
    }

    function _verify(whitelist memory supper) internal view returns (address) {
        bytes32 digest = _hash(supper);
        return ECDSAUpgradeable.recover(digest, supper.signature);
    }
}