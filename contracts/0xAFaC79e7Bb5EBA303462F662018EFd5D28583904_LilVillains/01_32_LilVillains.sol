// SPDX-License-Identifier: CC-BY-NC-ND-4.0
// ”I have read and accept the Terms of service (link: https://lilheroes.io/tos) and privacy policy (https://lilheroes.io/privacy)”

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@gm2/blockchain/src/contracts/GM721.sol';
import '@gm2/blockchain/src/contracts/GM2981.sol';
import { TransferIsNotSupported } from '@gm2/blockchain/src/errors/GM721Errors.sol';
import { Royalty } from '@gm2/blockchain/src/structs/DynamicMetadataStructs.sol';
import './common/contracts/GMDynamicSC.sol';
import './interfaces/ILilCollection.sol';
import './errors/LilVillainsErrors.sol';

contract LilVillains is GM2981, AccessControl, GM721, GMDynamicSC, Ownable, ILilCollection {
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant ALTER_ATTR_ROLE = keccak256('ALTER_ATTR_ROLE');
  bytes32 public constant ALTER_IMAGE_ROLE = keccak256('ALTER_IMAGE_ROLE');
  uint32 private constant MAX_SUPPLY = 7777;
  bool revealed = false;
  string public contractURI;

  string[10] traitTypes = ['Back', 'Mouth', 'Clothes', 'Ears', 'Helmet', 'Nose', 'Eyes', 'Accessory', 'Hat', 'Skin'];

  constructor(
    address villainMinter,
    address royaltyAddressToSet,
    string memory baseURI,
    string memory collectionDescription,
    string memory contractURI_
  ) GM721('LilVillains', 'LILV') GM2981(royaltyAddressToSet, 800) GMDynamicSC(baseURI, collectionDescription) {
    //8% of royalty
    contractURI = contractURI_;
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ALTER_ATTR_ROLE, villainMinter);
    _grantRole(ALTER_IMAGE_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, villainMinter);
  }

  modifier onlyTokenExists(uint256 tokenId) {
    if (!_exists(tokenId)) {
      revert TokenDoesNotExists(tokenId);
    }
    _;
  }

  function setContractURI(string calldata newContractURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    contractURI = newContractURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (revealed) {
      revert CollectionAlreadyRevealed();
    }
    _defaultBaseURI = newBaseUri;
    revealed = true;
  }

  function batchMint(address to, uint256[] calldata tokenIds) external onlyRole(MINTER_ROLE) {
    super._batchMint(to, tokenIds);
  }

  function setBaseAttributes(NFTBaseAttributes[] calldata nFTsBaseAttributes) external onlyRole(ALTER_ATTR_ROLE) {
    for (uint256 i = 0; i < nFTsBaseAttributes.length; i++) {
      NFTBaseAttributes memory nFTBaseAttributes = nFTsBaseAttributes[i];
      Attribute[] memory baseAttributes = new Attribute[](nFTBaseAttributes.values.length);
      for (uint256 j = 0; j < baseAttributes.length; j++) {
        baseAttributes[j] = Attribute('', traitTypes[j], nFTBaseAttributes.values[j]);
      }
      _setBaseAttributes(nFTBaseAttributes.id, baseAttributes);
    }
  }

  function setRoyaltyAddress(address newRoyaltyAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _royaltyAddress = newRoyaltyAddress;
  }

  function tokenURI(uint256 tokenId) public view virtual override onlyTokenExists(tokenId) returns (string memory) {
    return sCBehavior.getTokenURI(tokenId);
  }

  function getDynamicSCAddresses() public view override onlyRole(DEFAULT_ADMIN_ROLE) returns (address[2] memory) {
    return super.getDynamicSCAddresses();
  }

  function setDefaultImagePath(string calldata newDefaultImagePath) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _defaultImagePath = newDefaultImagePath;
  }

  function setAttributesControllerSC(address newAttributesControllerSC) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setAttributesControllerSC(newAttributesControllerSC);
  }

  function setTransferControllerSC(address newTransferControllerSC) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _setTransferControllerSC(newTransferControllerSC);
  }

  function setImagePath(uint256 tokenId, string memory newImageURL) public onlyRole(ALTER_IMAGE_ROLE) {
    _setImagePath(tokenId, newImageURL);
  }

  function supportsInterface(bytes4 interfaceId) public view override(GM2981, AccessControl, ERC721) returns (bool) {
    return interfaceId == type(ILilCollection).interfaceId || super.supportsInterface(interfaceId);
  }

  function transferOwnership(address newOwner)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
    onlyNotZeroAddress(newOwner)
  {
    super.transferOwnership(newOwner);
    grantRole(DEFAULT_ADMIN_ROLE, newOwner);
    revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function _beforeBatchMint(address, uint256[] calldata tokenIds) internal view override(GM721) {
    uint256 currentSupply = totalSupply();
    uint256 supplyRequired = currentSupply + tokenIds.length;
    if (supplyRequired > MAX_SUPPLY) {
      revert SupplyIsNotEnought(tokenIds.length, currentSupply, MAX_SUPPLY);
    }
  }

  function _beforeRoyaltyInfo(uint256 tokenId) internal view override(GM2981) onlyTokenExists(tokenId) {}

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal view override(ERC721) {
    if (!sCBehavior.canTokenBeTransferred(from, to, tokenId)) {
      revert TokenIsBlockedToTransfer(tokenId);
    }
  }

  function _getRoyaltiesData() internal view override returns (Royalty memory) {
    return Royalty(_royaltyAddress, _royaltyPercentage);
  }

  function _beforeTransferBlockedToken(address to, uint256 tokenId) internal override {
    if (!_checkERC721Compatibility(msg.sender, to, tokenId, '')) {
      revert TransferIsNotSupported(to, tokenId);
    }
  }

  function _transferBlockedToken(address to, uint256 tokenId) internal override {
    _transfer(msg.sender, to, tokenId);
  }
}