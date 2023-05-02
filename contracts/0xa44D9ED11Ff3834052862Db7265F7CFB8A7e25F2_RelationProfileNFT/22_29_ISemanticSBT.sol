// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Semantic Soulbound Token
 * Note: the EIP-165 identifier for this interface is 0xfbafb698
 */
interface ISemanticSBT {
    /**
     * @dev This emits when minting a Semantic Soulbound Token.
     * @param tokenId The identifier for the Semantic Soulbound Token.
     * @param rdfStatements The RDF statements for the Semantic Soulbound Token. An RDF statement is the statement made by an RDF triple.
     */
    event CreateRDF (
        uint256 indexed tokenId,
        string rdfStatements
    );


    /**
     * @dev This emits when updating the RDF data of Semantic Soulbound Token. RDF data is a collection of RDF statements that are used to represent information about resources.
     * @param tokenId The identifier for the Semantic Soulbound Token.
     * @param rdfStatements The RDF statements for the semantic soulbound token. An RDF statement is the statement made by an RDF triple.
     */
    event UpdateRDF (
        uint256 indexed tokenId,
        string rdfStatements
    );


    /**
     * @dev This emits when burning or revoking Semantic Soulbound Token.
     * @param tokenId The identifier for the Semantic Soulbound Token.
     * @param rdfStatements The RDF statements for the Semantic Soulbound Token. An RDF statement is the statement made by an RDF triple.
     */
    event RemoveRDF (
        uint256 indexed tokenId,
        string rdfStatements
    );

    /**
     * @dev Returns the RDF statements of the Semantic Soulbound Token. An RDF statement is the statement made by an RDF triple.
     * @param tokenId The identifier for the Semantic Soulbound Token.
     */
    function rdfOf(uint256 tokenId) external view returns (string memory);

}