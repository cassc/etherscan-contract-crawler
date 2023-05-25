// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

import '../sales/Saleable.sol';
import './RightwayDecoder.sol';
import './RightwayMetadata.sol';

contract RightwayToken is ERC721Enumerable, Saleable, AccessControl {
  bytes32 public constant INFRA_ROLE = keccak256('INFRA_ROLE');
  bytes32 public constant REDEEM_ROLE = keccak256('REDEEM_ROLE');
  bytes32 public constant CONTENT_ROLE = keccak256('CONTENT_ROLE');

  event TokenRedeemed(uint256 indexed tokenId);
  event TokenContentAdded(uint256 indexed tokenId);

  constructor(
    string memory name,
    string memory symbol,
    string memory newCreator
  ) ERC721(name, symbol) {
    creator = newCreator;
    dropSealed = false;
    contentApi = 'https://tbd.io/content';
    metadataApi = string(abi.encodePacked('https://tbd.io/metadata/', addressToString(address(this)), '/'));
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }


  string public creator;
  address payable public     royaltyAddress;
  uint256 public             royaltyBps;

  /*
   * drop information
   */
  RightwayDecoder.Drop internal drop;
  bool public dropSealed;

  mapping(uint256 => RightwayMetadata.TokenState) internal stateByToken;

  /*
   * hosting information
   */
  string internal contentApi;
  string internal metadataApi;

  modifier unsealed() {
    require(!dropSealed, 'drop is sealed');
    _;
  }

  modifier issealed() {
    require(dropSealed, 'drop is not sealed');
    _;
  }

  function setDropRoyalties( address payable newRoyaltyAddress, uint256 newRoyaltyBps ) public onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyAddress = newRoyaltyAddress;
    royaltyBps = newRoyaltyBps;
  }

  function setApis( string calldata newContentApi, string calldata newMetadataApi ) public onlyRole(INFRA_ROLE) {
    contentApi = newContentApi;
    metadataApi = string(abi.encodePacked(newMetadataApi, '/', addressToString(address(this)), '/'));
  }

  function addDropContentLibraries( RightwayDecoder.DropContentLibrary[] memory contentLibraries ) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    for (uint idx = 0; idx < contentLibraries.length; idx++) {
      drop.contentLibraries.push(contentLibraries[idx]);
    }
  }

  function addDropContent( bytes32[] calldata content, uint offset ) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < content.length) {
      drop.content[offset + idx] = content[idx];
      idx++;
    }
  }

  function addDropStringData( bytes32[] calldata stringData, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < stringData.length) {
      drop.stringData[offset + idx] = stringData[idx];
      idx++;
    }
  }

  function addDropSentences( bytes32[] calldata sentences, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < sentences.length) {
      drop.sentences[offset + idx] = sentences[idx];
      idx++;
    }
  }

  function addDropAttributes( bytes32[] calldata attributes, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < attributes.length) {
      drop.attributes[offset + idx] = attributes[idx];
      idx++;
    }
  }

  function addDropTemplates( bytes32[] calldata templates, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < templates.length) {
      drop.templates[offset + idx] = templates[idx];
      idx++;
    }
  }

  function addDropEditions( bytes32[] calldata editions, uint offset) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < editions.length) {
      drop.editions[offset + idx] = editions[idx];
      idx++;
    }
  }

  function addDropTokens( bytes32[] calldata tokens, uint offset, uint length) public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    uint idx = 0;
    while(idx < tokens.length) {
      drop.tokens[offset + idx] = tokens[idx];
      idx++;
    }
    drop.numTokens = length;
  }

  function sealDrop() public onlyRole(DEFAULT_ADMIN_ROLE) unsealed {
    dropSealed = true;
  }

  function addTokenContent( uint256[] calldata tokens, string calldata slug, string calldata contentLibraryArweaveHash, uint16 contentIndex, string calldata contentType) public onlyRole(CONTENT_ROLE) issealed {
    for (uint idx = 0; idx < tokens.length; idx++) {
      require(_exists(tokens[idx]), 'No such token');
      stateByToken[tokens[idx]].additionalContent.push();
      uint cidx = stateByToken[tokens[idx]].additionalContent.length - 1;
      stateByToken[tokens[idx]].additionalContent[cidx].contentLibraryArweaveHash = contentLibraryArweaveHash;
      stateByToken[tokens[idx]].additionalContent[cidx].contentIndex = contentIndex;
      stateByToken[tokens[idx]].additionalContent[cidx].contentType = contentType;
      stateByToken[tokens[idx]].additionalContent[cidx].slug = slug;
      emit TokenContentAdded(tokens[idx]);
    }
  }

  function mint(address to, uint256 tokenId, uint16 attributesStart, uint16 attributesLength) public onlyRole(DEFAULT_ADMIN_ROLE) issealed {
    require(drop.numTokens > tokenId, 'No such token');
    _safeMint(to, tokenId);
    RightwayMetadata.TokenState storage state = stateByToken[tokenId];
    state.attributesStart = attributesStart;
    state.attributesLength = attributesLength;
  }

  function mintBatch(address to, uint256[] calldata tokenIds, uint16 attributesStart, uint16 attributesLength) public onlyRole(DEFAULT_ADMIN_ROLE) issealed {
    for (uint idx = 0; idx < tokenIds.length; idx++) {
      mint(to, tokenIds[idx], attributesStart, attributesLength);
    }
  }

  function redeem(uint256 tokenId, uint64 timestamp, string memory memo) public onlyRole(REDEEM_ROLE) issealed {
    require(_exists(tokenId), 'No such token');
    RightwayMetadata.TokenState storage state = stateByToken[tokenId];
    state.redemptions.push();
    uint redemptionIdx = state.redemptions.length - 1;
    RightwayMetadata.TokenRedemption storage record = state.redemptions[redemptionIdx];
    record.timestamp = timestamp;
    record.memo = memo;
    emit TokenRedeemed(tokenId);
  }

  function addressToString(address addr) internal pure returns(string memory) {
    bytes32 value = bytes32(uint256(uint160(addr)));
    bytes memory alphabet = '0123456789abcdef';

    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i = 0; i < 20; i++) {
      str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
      str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }

  function getMetadata(uint256 tokenId) public view returns (RightwayMetadata.TokenMetadata memory) {
    RightwayMetadata.TokenState memory state;
    bool isMinted = false;
    if (_exists(tokenId)) {
      state = stateByToken[tokenId];
      isMinted = true;
    }

    return RightwayMetadata.getMetadata(creator, drop, contentApi, tokenId, state, isMinted);
  }

   /**
    * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
    * in child contracts.
    */
  function _baseURI() internal view virtual override returns (string memory) {
    return metadataApi;
  }

  /**
   *  @dev Saleable interface
   */
  function _processSaleOffering(uint256 offeringId, address buyer, uint256 price) internal override issealed {
    require(drop.numTokens > offeringId, 'No such token');
    _safeMint(buyer, offeringId);
    RightwayMetadata.TokenState storage state = stateByToken[offeringId];

    // solhint-disable-next-line not-rely-on-time
    state.soldOn = uint64(block.timestamp);
    state.buyer = buyer;
    state.price = price;
  }

  function registerSeller(address seller) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _registerSeller(seller);
  }

  function deregisterSeller(address seller) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _deregisterSeller(seller);
  }

  bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC721Enumerable) returns (bool) {
      return interfaceId == _INTERFACE_ID_FEES || AccessControl.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
  }

  function getFeeRecipients(uint256) public view returns (address payable[] memory) {
    address payable[] memory result = new address payable[](1);
    result[0] = royaltyAddress;
    return result;
  }

  function getFeeBps(uint256) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](1);
    result[0] = royaltyBps;
    return result;
  }
}