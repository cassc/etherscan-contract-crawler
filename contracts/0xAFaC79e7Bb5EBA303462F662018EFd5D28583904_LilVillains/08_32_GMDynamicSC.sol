// SPDX-License-Identifier: MIT
// GM2 Contracts (last updated v0.0.1)
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@gm2/blockchain/src/interfaces/IGMTransferController.sol';
import '@gm2/blockchain/src/interfaces/IGMAttributesController.sol';
import '@gm2/blockchain/src/errors/AddressValidatorErrors.sol';
import { Attribute, Royalty, SCBehavior } from '@gm2/blockchain/src/structs/DynamicMetadataStructs.sol';
import { Metadata as MetadataV1 } from '../structs/DynamicMetadataStructs.sol';

import '../libraries/DynamicMetadata.sol';
import '../errors/DynamicMetadataErrors.sol';

abstract contract GMDynamicSC {
  using Strings for uint256;
  using DynamicMetadata for Attribute[];
  using DynamicMetadata for MetadataV1;

  mapping(uint256 => Attribute[]) _baseAttributesDictionary;
  mapping(uint256 => string) _imageURLDictionary;
  address _attributesControllerSC;
  address _transferControllerSC;
  string _defaultBaseURI;
  string _defaultImagePath;
  string _metadataDescription;

  SCBehavior sCBehavior = SCBehavior(_defaultTokenURI, _defaultCanTokenBeTransferred, _defaultTransferBlockedToken);

  constructor(string memory baseURI, string memory description) {
    _defaultBaseURI = baseURI;
    _metadataDescription = description;
  }

  modifier onlyNotZeroAddress(address addr) {
    if (addr == address(0)) {
      revert ZeroAddressNotSupported();
    }
    _;
  }

  modifier onlyIfSupports(address addr, bytes4 interfaceId) {
    if (IERC165(addr).supportsInterface(interfaceId) == false) {
      revert InterfaceIsNotImplemented(addr, interfaceId);
    }
    _;
  }

  function transferBlockedToken(address to, uint256 tokenId) public onlyNotZeroAddress(to) {
    sCBehavior.transferBlockedToken(to, tokenId);
  }

  function getDynamicSCAddresses() public view virtual returns (address[2] memory) {
    return [_attributesControllerSC, _transferControllerSC];
  }

  function _setAttributesControllerSC(address newAttributesControllerSC)
    internal
    virtual
    onlyNotZeroAddress(newAttributesControllerSC)
    onlyIfSupports(newAttributesControllerSC, type(IGMAttributesController).interfaceId)
  {
    _beforeSetAttributesControllerSC(newAttributesControllerSC);
    _attributesControllerSC = newAttributesControllerSC;
    sCBehavior.getTokenURI = _getDynamicTokenURI;
  }

  function _beforeSetAttributesControllerSC(address) internal virtual {
    if (bytes(_defaultImagePath).length == 0) {
      revert DefaultImagePathRequired();
    }
  }

  function _setTransferControllerSC(address newTransferControllerSC)
    internal
    virtual
    onlyNotZeroAddress(newTransferControllerSC)
    onlyIfSupports(newTransferControllerSC, type(IGMTransferController).interfaceId)
  {
    _beforeSetTransferControllerSC(newTransferControllerSC);
    _transferControllerSC = newTransferControllerSC;
    sCBehavior.canTokenBeTransferred = _dynamicCanTokenBeTransferred;
    sCBehavior.transferBlockedToken = _dynamicTransferBlockedToken;
  }

  function _beforeSetTransferControllerSC(address) internal virtual {}

  function _setImagePath(uint256 tokenId, string memory newImageURL) internal virtual {
    _beforeSetImagePath(tokenId, newImageURL);
    _imageURLDictionary[tokenId] = newImageURL;
  }

  function _beforeSetImagePath(uint256 tokenId, string memory newImageURL) internal virtual {
    if (_baseAttributesDictionary[tokenId].length == 0) {
      revert CannotSetImageWithoutBaseAttributes(tokenId, newImageURL);
    }
  }

  function _setBaseAttributes(uint256 tokenId, Attribute[] memory newBaseAttributes) internal virtual {
    _beforeSetBaseAttributes(tokenId, newBaseAttributes);
    _baseAttributesDictionary[tokenId].appendBaseAttributes(newBaseAttributes);
  }

  function _beforeSetBaseAttributes(uint256 tokenId, Attribute[] memory) internal virtual {
    if (_baseAttributesDictionary[tokenId].length != 0) {
      revert AlreadyHaveBaseAttributes(tokenId);
    }
  }

  function _dynamicTransferBlockedToken(address to, uint256 tokenId) internal {
    _beforeTransferBlockedToken(to, tokenId);
    IGMTransferController(_transferControllerSC).bypassTokenId(address(this), tokenId);
    _transferBlockedToken(to, tokenId);
    IGMTransferController(_transferControllerSC).removeBypassTokenId(address(this), tokenId);
  }

  function _beforeTransferBlockedToken(address to, uint256 tokenId) internal virtual {}

  function _transferBlockedToken(address to, uint256 tokenId) internal virtual {}

  function _getRoyaltiesData() internal view virtual returns (Royalty memory) {}

  function _getDynamicTokenURI(uint256 tokenId) internal view returns (string memory) {
    string memory tokenURI = _defaultTokenURI(tokenId);
    Attribute[] memory attributes = _baseAttributesDictionary[tokenId];

    // INFO: Has Base attributes
    if (attributes.length != 0) {
      Attribute[] memory dynamicAttributes = IGMAttributesController(_attributesControllerSC).getDynamicAttributes(
        address(this),
        tokenId
      );

      // INFO: Has dynamic attributes
      if (dynamicAttributes.length > 0) {
        attributes = _baseAttributesDictionary[tokenId].concatDynamicAttributes(dynamicAttributes);
      }

      string memory metadataImageURL = _getImageURL(tokenId);
      string memory metadataName = string(abi.encodePacked('#', tokenId.toString()));
      Royalty memory royalty = _getRoyaltiesData();

      MetadataV1 memory metadata = MetadataV1(
        _metadataDescription,
        metadataImageURL,
        metadataName,
        attributes,
        royalty
      );

      tokenURI = metadata.toBase64URI();
    }

    return tokenURI;
  }

  // INFO: Behavior dynamic methods
  function _dynamicCanTokenBeTransferred(
    address from,
    address to,
    uint256 tokenId
  ) private view returns (bool) {
    return IGMTransferController(_transferControllerSC).canTokenBeTransferred(address(this), from, to, tokenId);
  }

  function _getImageURL(uint256 tokenId) private view returns (string memory) {
    string memory imagePath = string(abi.encodePacked(_defaultImagePath, tokenId.toString()));
    if (bytes(_imageURLDictionary[tokenId]).length > 0) {
      // INFO: TokenID should be in the custom image path
      imagePath = _imageURLDictionary[tokenId];
    }
    return imagePath;
  }

  // INFO: Default behavior methods
  function _defaultTokenURI(uint256 tokenId) private view returns (string memory) {
    return string(abi.encodePacked(_defaultBaseURI, tokenId.toString()));
  }

  function _defaultCanTokenBeTransferred(
    address,
    address,
    uint256
  ) private pure returns (bool) {
    return true;
  }

  function _defaultTransferBlockedToken(address, uint256) private pure {
    revert MethodNotSupported('TransferBlockedToken');
  }
}