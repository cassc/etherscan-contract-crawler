//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC1271} from "../../interfaces/IERC1271.sol";
import {LibERC1271} from "../../libraries/LibERC1271.sol";

/// @author Amit Molek
/// @dev ERC1271 support
contract EIP1271Facet is IERC1271 {
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override
        returns (bytes4)
    {
        return LibERC1271._isValidSignature(hash, signature);
    }
}