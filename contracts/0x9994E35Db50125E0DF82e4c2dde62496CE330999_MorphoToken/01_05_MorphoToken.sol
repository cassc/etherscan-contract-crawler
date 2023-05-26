// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.13;

import "@semitransferable-token/Token.sol";

/// @title MorphoToken.
/// @author Morpho Association.
/// @custom:contact [email protected]
/// @notice Morpho token contract.
contract MorphoToken is Token {

    /// @notice Constructs Morpho token contract.
    /// @param _owner The address of the owner (Morpho DAO).
    constructor(address _owner) Token("Morpho Token", "MORPHO", 18, _owner) {
        _mint(_owner, 0.2e9 ether); // Mint 1B of Morpho tokens.
    }
}