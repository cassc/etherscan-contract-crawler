//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract Whitelist is EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "LabGrownBeasts";
    string private constant SIGNATURE_VERSION = "1";

    struct whitelist {
        address userAddress;
        uint256 listType;
        bytes signature;
    }

    function __WhitelistSigner_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);   
    }

    function getSigner(whitelist memory _data) public view returns (address) {
        return _verify(_data);
    }

    /// @notice Returns a hash of the given rarity, prepared using EIP712 typed data hashing rules.

    function _hash(whitelist memory _data) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "whitelist(address userAddress,uint256 listType)"
                    ),
                    _data.userAddress,
                    _data.listType
                )
            )
        );
    }

    function _verify(whitelist memory _data) internal view returns (address) {
        bytes32 digest = _hash(_data);
        return ECDSAUpgradeable.recover(digest, _data.signature);
    }
}