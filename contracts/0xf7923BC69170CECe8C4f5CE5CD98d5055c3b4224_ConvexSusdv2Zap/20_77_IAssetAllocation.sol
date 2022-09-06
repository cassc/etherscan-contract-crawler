// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {INameIdentifier} from "./INameIdentifier.sol";

/**
 * @notice For use with the `TvlManager` to track the value locked in a protocol
 */
interface IAssetAllocation is INameIdentifier {
    struct TokenData {
        address token;
        string symbol;
        uint8 decimals;
    }

    /**
     * @notice Get data for the underlying tokens stored in the protocol
     * @return The array of `TokenData`
     */
    function tokens() external view returns (TokenData[] memory);

    /**
     * @notice Get the number of different tokens stored in the protocol
     * @return The number of tokens
     */
    function numberOfTokens() external view returns (uint256);

    /**
     * @notice Get an account's balance for a token stored in the protocol
     * @dev The token index should be ordered the same as the `tokens()` array
     * @param account The account to get the balance for
     * @param tokenIndex The index of the token to get the balance for
     * @return The account's balance
     */
    function balanceOf(address account, uint8 tokenIndex)
        external
        view
        returns (uint256);

    /**
     * @notice Get the symbol of a token stored in the protocol
     * @dev The token index should be ordered the same as the `tokens()` array
     * @param tokenIndex The index of the token
     * @return The symbol of the token
     */
    function symbolOf(uint8 tokenIndex) external view returns (string memory);

    /**
     * @notice Get the decimals of a token stored in the protocol
     * @dev The token index should be ordered the same as the `tokens()` array
     * @param tokenIndex The index of the token
     * @return The decimals of the token
     */
    function decimalsOf(uint8 tokenIndex) external view returns (uint8);
}