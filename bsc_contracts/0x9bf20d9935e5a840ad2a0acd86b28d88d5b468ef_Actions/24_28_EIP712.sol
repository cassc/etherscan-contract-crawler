// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract EIP712 {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant _HASHED_VERSION = keccak256("1");
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the contract's {EIP712} domain separator.
     *
     * @return bytes32 the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _TYPE_HASH,
                    keccak256(bytes(_domainSeparatorName())),
                    _HASHED_VERSION,
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) internal view {
        require(deadline >= block.timestamp, "DEADLINE_EXCEEDED");
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "INVALID_SIGNATURE_S_VAULE"
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == expectedSigner, "INVALID_SIGNATURE");
    }

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        _requiresExpectedSigner(
            digest,
            expectedSigner,
            sig.v,
            sig.r,
            sig.s,
            sig.deadline
        );
    }

    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash)
            );
    }

    function _domainSeparatorName()
        internal
        view
        virtual
        returns (string memory);
}