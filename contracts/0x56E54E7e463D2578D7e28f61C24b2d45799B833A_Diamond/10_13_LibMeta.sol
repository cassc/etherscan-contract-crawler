// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

library LibMeta {
    bytes32 internal constant _EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"
            )
        );

    function domainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    getChainID(),
                    address(this)
                )
            );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (msg.sender == s.trustedForwarder) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }
}