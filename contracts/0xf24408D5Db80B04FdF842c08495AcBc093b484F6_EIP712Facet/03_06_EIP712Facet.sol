//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IEIP712} from "../../interfaces/IEIP712.sol";
import {LibEIP712} from "../../libraries/LibEIP712.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712` for docs
contract EIP712Facet is IEIP712 {
    function toTypedDataHash(bytes32 messageHash)
        external
        view
        override
        returns (bytes32)
    {
        return LibEIP712._toTypedDataHash(messageHash);
    }

    function domainSeparator() external view override returns (bytes32) {
        return LibEIP712._domainSeparator();
    }

    function chainId() external view override returns (uint256 id) {
        return LibEIP712._chainId();
    }

    function verifyingContract() external view override returns (address) {
        return LibEIP712._verifyingContract();
    }

    function salt() external pure override returns (bytes32) {
        return LibEIP712._salt();
    }
}