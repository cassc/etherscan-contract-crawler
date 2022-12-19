//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IMultisigOwnerCut} from "../interfaces/IMultisigOwnerCut.sol";

/// @author Amit Molek
/// @dev EIP712 helper functions for IMultisigOwnerCut multi-sig
library LibEIP712MultisigOwnerCut {
    bytes32 internal constant _OWNER_CUT_TYPEHASH =
        keccak256(
            "OwnerCut(uint256 action,address account,address prevAccount,uint256 endsAt)"
        );

    function _hashOwnerCut(IMultisigOwnerCut.OwnerCut memory cut)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _OWNER_CUT_TYPEHASH,
                    cut.action,
                    cut.account,
                    cut.prevAccount,
                    cut.endsAt
                )
            );
    }
}