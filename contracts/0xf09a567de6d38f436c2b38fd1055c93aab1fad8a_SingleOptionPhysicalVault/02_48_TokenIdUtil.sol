// SPDX-License-Identifier: MIT
// solhint-disable max-line-length

pragma solidity ^0.8.0;

import "../config/enums.sol";
import "../config/errors.sol";

/**
 * Token ID =
 *
 *  * ------------------- | ------------------- | ---------------- | ---------------- | -------------------------- *
 *  | tokenType (32 bits) | productId (32 bits) | expiry (64 bits) | strike (64 bits) | exerciseWindow (64 bits) |
 *  * ------------------- | ------------------- | ---------------- | ---------------- | -------------------------- *
 */

library TokenIdUtil {
    /**
     * @notice calculate ERC1155 token id for given option parameters. See table above for tokenId
     * @param tokenType TokenType enum
     * @param productId if of the product
     * @param expiry timestamp of option expiry
     * @param strike strike price of the long option, with 6 decimals
     * @param exerciseWindow time after expiry in which the option can be exercised
     * @return tokenId token id
     */
    function getTokenId(TokenType tokenType, uint32 productId, uint64 expiry, uint64 strike, uint64 exerciseWindow)
        internal
        pure
        returns (uint256 tokenId)
    {
        unchecked {
            tokenId = (uint256(tokenType) << 226) + (uint256(productId) << 192) + (uint256(expiry) << 128)
                + (uint256(strike) << 64) + uint256(exerciseWindow);
        }
    }

    /**
     * @notice derive option, product, expiry and strike price from ERC1155 token id
     * @dev    See table above for tokenId composition
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return productId 32 bits product id
     * @return expiry timestamp of option expiry
     * @return strike strike price of the long option, with 6 decimals
     * @return exerciseWindow time after expiry in which the option can be exercised
     */
    function parseTokenId(uint256 tokenId)
        internal
        pure
        returns (TokenType tokenType, uint32 productId, uint64 expiry, uint64 strike, uint64 exerciseWindow)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(226, tokenId)
            productId := shr(192, tokenId)
            expiry := shr(128, tokenId)
            strike := shr(64, tokenId)
            exerciseWindow := tokenId
        }
    }

    /**
     * @notice parse collateral id from tokenId
     * @dev more efficient than parsing tokenId and than parse productId
     * @param tokenId token id
     * @return collateralId
     */
    function parseCollateralId(uint256 tokenId) internal pure returns (uint8 collateralId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // collateralId is the last bits of productId
            collateralId := shr(192, tokenId)
        }
    }

    /**
     * @notice parse engine id from tokenId
     * @dev more efficient than parsing tokenId and than parse productId
     * @param tokenId token id
     * @return engineId
     */
    function parseEngineId(uint256 tokenId) internal pure returns (uint8 engineId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // collateralId is the last bits of productId
            engineId := shr(216, tokenId) // 192 to get product id, another 24 to get engineId
        }
    }

    /**
     * @notice derive option type from ERC1155 token id
     * @param tokenId token id
     * @return tokenType TokenType enum
     */
    function parseTokenType(uint256 tokenId) internal pure returns (TokenType tokenType) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(232, tokenId)
        }
    }

    /**
     * @notice derive if option is expired from ERC1155 token id
     * @param tokenId token id
     * @return expired bool
     */
    function isExpired(uint256 tokenId) internal view returns (bool expired) {
        uint64 expiry;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            expiry := shr(128, tokenId)
        }

        expired = block.timestamp >= expiry;
    }
}