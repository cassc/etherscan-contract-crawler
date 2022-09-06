// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Address} from "contracts/libraries/Imports.sol";
import {AssetAllocationBase} from "./AssetAllocationBase.sol";

/**
 * @notice Asset allocation with underlying tokens that cannot be added/removed
 */
abstract contract ImmutableAssetAllocation is AssetAllocationBase {
    using Address for address;

    constructor() public {
        _validateTokens(_getTokenData());
    }

    function tokens() public view override returns (TokenData[] memory) {
        TokenData[] memory tokens_ = _getTokenData();
        return tokens_;
    }

    /**
     * @notice Verifies that a `TokenData` array works with the `TvlManager`
     * @dev Reverts when there is invalid `TokenData`
     * @param tokens_ The array of `TokenData`
     */
    function _validateTokens(TokenData[] memory tokens_) internal view virtual {
        // length restriction due to encoding logic for allocation IDs
        require(tokens_.length < type(uint8).max, "TOO_MANY_TOKENS");
        for (uint256 i = 0; i < tokens_.length; i++) {
            address token = tokens_[i].token;
            _validateTokenAddress(token);
            string memory symbol = tokens_[i].symbol;
            require(bytes(symbol).length != 0, "INVALID_SYMBOL");
        }
        // TODO: check for duplicate tokens
    }

    /**
     * @notice Verify that a token is a contract
     * @param token The token to verify
     */
    function _validateTokenAddress(address token) internal view virtual {
        require(token.isContract(), "INVALID_ADDRESS");
    }

    /**
     * @notice Get the immutable array of underlying `TokenData`
     * @dev Should be implemented in child contracts with a hardcoded array
     * @return The array of `TokenData`
     */
    function _getTokenData() internal pure virtual returns (TokenData[] memory);
}