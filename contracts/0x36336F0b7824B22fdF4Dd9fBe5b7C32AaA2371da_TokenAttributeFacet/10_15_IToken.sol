// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @notice common struct definitions for tokens
interface IToken {

    struct Token {

        uint256 id;
        uint256 balance;
        bool burn;

    }

    /// @notice a set of tokens.
    struct TokenSet {

        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
        Token[] valueList;

    }

    /// @notice the definition for a token.
    struct TokenDefinition {

        // the host multitoken
        address token;

        // the id of the token definition. if static mint then also token hash
        uint256 id;

        // the category name
        uint256 collectionId;

        // the name of the token
        string name;

        // the symbol of the token
        string symbol;

        // the description of the token
        string description;

        // the decimals of the token. 0 for NFT
        uint8 decimals;

        // the total supply of the token
        uint256 totalSupply;

        // whether to generate the id or not for new tokens. if false then we use id field of the definition to mint tokens
        bool generateId;

        // probability of the item being awarded
        uint256 probability;

         // the index of the probability in its array
        uint256 probabilityIndex;

         // the index of the probability in its array
        uint256 probabilityRoll;

    }

    struct TokenRecord {

        uint256 id;
        address owner;
        address minter;
        uint256 _type;
        uint256 balance;

    }

    /// @notice the token source type. Either a static source or a collection.
    enum TokenSourceType {

        Static,
        Collection

    }

    /// @notice the token source. Specifies the source of the token - either a static source or a collection.
    struct TokenSource {

        // the token source type
        TokenSourceType _type;
        // the source id if a static collection
        uint256 staticSourceId;
        // the collection source address if collection
        address collectionSourceAddress;

    }
}