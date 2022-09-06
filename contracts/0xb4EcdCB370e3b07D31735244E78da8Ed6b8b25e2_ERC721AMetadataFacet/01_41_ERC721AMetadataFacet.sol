//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../libraries/LibAppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/MetadataLib.sol";
import "../libraries/ERC721ALib.sol";

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
        LibAppStorage.diamondStorage().metadata[address(this)] = _contract;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view returns (string memory) {

        // solhint-disable-next-line
        return LibAppStorage.diamondStorage().metadata[address(this)].name();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view returns (string memory) {

        // solhint-disable-next-line
        return LibAppStorage.diamondStorage().metadata[address(this)].symbol();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function description() external view returns (string memory) {

        // solhint-disable-next-line
        return LibAppStorage.diamondStorage().metadata[address(this)].description();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function image() external view returns (string memory) {

        // solhint-disable-next-line
        return LibAppStorage.diamondStorage().metadata[address(this)].image();
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {

        ERC721AContract storage erc721Contract = s().erc721Contracts[address(this)];        
        if (!erc721Contract._exists(tokenId)) revert URIQueryForNonexistentToken();
        
        MetadataContract storage metadata = s().metadata[address(this)];
        AttributeContract storage attributes = s().attributes[address(this)];

        return metadata.tokenURI(attributes, tokenId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts().
     */
    function contractURI() external view returns (string memory) {

        MetadataContract storage metadata = s().metadata[address(this)];
        Trait[] memory dum;
        string memory svg = metadata._imageName;
        string memory json = Base64.encode(
            bytes(
                metadata.getTokenMetadata(dum, svg, false, 0)
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

}