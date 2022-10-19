//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../libraries/MetadataLib.sol";
import "../libraries/AttributeLib.sol";
import "../libraries/DiamondLib.sol";
import "../libraries/ERC721ALib.sol";

import "../utilities/Modifiers.sol";

/* solhint-disable mark-callable-contracts */
/* solhint-disable var-name-mixedcase */
/* solhint-disable no-unused-vars */
/* solhint-disable two-lines-top-level-separator */
/* solhint-disable indent */


contract ERC721AMetadataFacet is Modifiers {

    using MetadataLib for MetadataContract;
    using ERC721ALib for ERC721AContract;

    function setMetadata(MetadataContract memory _contract) external {

        LibDiamond.enforceIsContractOwner();
        MetadataLib.metadataStorage().metadata.setMetadata(_contract);
    }

    function initializeERC721AMetadataFacet(
        string memory _name, 
        string memory _symbol, 
        string memory _baseURI) external {

    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view returns (string memory) {

        // solhint-disable-next-lsine
        return MetadataLib.metadataStorage().metadata.name();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view returns (string memory) {

        // solhint-disable-next-line
        return MetadataLib.metadataStorage().metadata.symbol();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function description() external view returns (string memory) {

        // solhint-disable-next-line
        return MetadataLib.metadataStorage().metadata.description();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function image() external view returns (string memory) {

        // solhint-disable-next-line
        return MetadataLib.metadataStorage().metadata.image();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function externalUri() external view returns (string memory) {

        // solhint-disable-next-line
        return MetadataLib.metadataStorage().metadata._externalUri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {

        ERC721AContract storage erc721Contract = ERC721ALib.erc721aStorage().erc721Contract;        
        if (!erc721Contract._exists(tokenId)) revert URIQueryForNonexistentToken();
        
        MetadataContract storage metadata = MetadataLib.metadataStorage().metadata;
        AttributeContract storage attributes = AttributeLib.attributeStorage().attributes;
        DiamondContract storage diamond = DiamondLib.diamondStorage().diamondContract;

        return metadata.tokenURI(diamond, attributes, tokenId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts().
     */
    function contractURI() external view returns (string memory) {

        MetadataContract storage metadata = MetadataLib.metadataStorage().metadata;
        Trait[] memory dum;
        (, string memory svg) = metadata.getContractImage();
        string memory json = Base64.encode(
            bytes(
                metadata.getTokenMetadata(dum, svg)
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

}