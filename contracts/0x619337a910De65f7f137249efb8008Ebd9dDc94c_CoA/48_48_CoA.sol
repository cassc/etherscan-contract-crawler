// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: yungwknd
/// @artist: alphacentaurikid

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@ensdomains/ens-contracts/contracts/registry/IReverseRegistrar.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
// This Contract is for my physical works. Interactive Certificates Of Authenticity    //
// have the ability to show us historical provenance which might otherwise be hard     //
// to find. These CoA's must remain coupled with their physical counterparts and are   //
// not intended for individual sale. Thank you for caring about my art.                //
//                                                                                     //
//                                                    Developed by ACK + yungwknd      //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////
contract CoA is AdminControl, ICreatorExtensionTokenURI {
    address public _creator;

    struct Attribute {
      string trait_type;
      string value;
    }
    struct Metadata {
      string name;
      string createdBy;
      string description;
      Attribute[] attributes;
      string previewImage;
      string mainTokenURI;
    }
    mapping(uint => Metadata) public metadatas;

    PublicResolver resolver = PublicResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047);

    IReverseRegistrar reverseReg = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);

    function configure(address creatorCore) public adminRequired {
      _creator = creatorCore;
    }

    function configureENS(address resolverAddress, address reverseRegAddress) public adminRequired {
      resolver = PublicResolver(resolverAddress);
      reverseReg = IReverseRegistrar(reverseRegAddress);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function mint(address to) public adminRequired {
      IERC721CreatorCore(_creator).mintExtension(to);
    }

    function configureMeta(
      uint tokenId,
      string memory name,
      string memory createdBy,
      string memory description,
      Attribute[] memory attributes,
      string memory previewImage,
      string memory mainTokenURI
    ) public adminRequired {
      metadatas[tokenId].name = name;
      metadatas[tokenId].createdBy = createdBy;
      metadatas[tokenId].description = description;
      metadatas[tokenId].previewImage = previewImage;
      metadatas[tokenId].mainTokenURI = mainTokenURI;
      delete metadatas[tokenId].attributes;
      for (uint i = 0; i < attributes.length; i++) {
        metadatas[tokenId].attributes.push(attributes[i]);
      }
    }

    function getAnimationURL(uint tokenId) private view returns (string memory) {
        address owner = IERC721(_creator).ownerOf(tokenId);
        string memory name = resolver.name(reverseReg.node(owner));
        return string(abi.encodePacked(metadatas[tokenId].mainTokenURI, "?owner=", bytes(name).length > 0 ? name : Strings.toHexString(uint256(uint160(owner)), 20)));
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        Metadata storage metadata = metadatas[tokenId];
        return string(abi.encodePacked('data:application/json;utf8,',
          '{"name":"',
            metadata.name,
            '","created_by":"',
            metadata.createdBy,
            '","description":"',
            metadata.description,
            '","animation":"',
            getAnimationURL(tokenId),
            '","animation_url":"',
            getAnimationURL(tokenId),
            '","image":"',
            metadata.previewImage,
            '","image_url":"',
            metadata.previewImage,
            '","attributes":',
            _makeTraits(tokenId),
          '}'));
    }

    function _makeTraits(uint tokenId) private view returns(string memory) {
      string memory traits = "[";
      for (uint i = 0; i <  metadatas[tokenId].attributes.length; i++) {
        traits = string(abi.encodePacked(traits, _wrapTrait(metadatas[tokenId].attributes[i].trait_type, metadatas[tokenId].attributes[i].value)));
        if (i < metadatas[tokenId].attributes.length - 1) {
          traits = string(abi.encodePacked(traits, ","));
        }
      }
      return string(abi.encodePacked(traits, "]"));
    }

    function _wrapTrait(string memory trait, string memory value) public pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }
}