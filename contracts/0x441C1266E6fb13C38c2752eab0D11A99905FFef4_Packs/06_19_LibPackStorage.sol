// SPDX-License-Identifier: MIT
// Written by Tim Kang <> illestrater
// Thought innovation by Monstercat
// Product by universe.xyz

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import 'base64-sol/base64.sol';
import './HelperFunctions.sol';

library LibPackStorage {
  using SafeMath for uint256;

  bytes32 constant STORAGE_POSITION = keccak256("com.universe.packs.storage");

  struct Fee {
    address payable recipient;
    uint256 value;
  }

  struct SingleCollectible {
    uint16 count; // Amount of editions per collectible
    uint16 totalVersionCount; // Total number of existing states
    uint16 currentVersion; // Current existing state
    string title; // Collectible name
    string description; // Collectible description
    string[] assets; // Each asset in array is a version
  }

  struct Metadata {
    uint8[] name; // Trait or attribute property field name
    string[] value; // Trait or attribute property value
    bool[] modifiable; // Can owner modify the value of field
    uint16 propertyCount; // Tracker of total attributes
  }

  struct MetadataStore {
    uint8 propertyKey;
    string value;
    bool modifiable;
  }

  struct Collection {
    uint16 collectibleCount; // Total unique assets count
    uint16 bulkBuyLimit;
    uint16 licenseVersion; // Tracker of latest license
    uint256 totalTokenCount; // Total NFT count to be minted
    uint256 tokenPrice;
    uint256 saleStartTime;

    string baseURI; // Token ID base URL

    bool initialized;
    bool editioned; // Display edition # in token name
    bool mintPass;
    bool mintPassOnly;
    bool mintPassFree;
    bool mintPassBurn;
    uint256 mintPassDuration;

    address mintPassAddress;
    ERC721 mintPassContract;
    uint32[] shuffleIDs;

    uint16 metadataKeysLength;

    mapping (uint256 => SingleCollectible) collectibles; // Unique assets
    mapping (uint256 => string) metadataKeys;
    mapping (uint256 => Metadata) metadata; // Trait & property attributes, indexes should be coupled with 'collectibles'
    mapping (uint256 => Fee[]) secondaryFees;
    mapping (uint256 => string) licenseURI; // URL to external license or file
    mapping (uint256 => bool) mintPassClaims;
  }

  struct Storage {
    address relicsAddress;
    address payable daoAddress;
    bool daoInitialized;

    uint256 collectionCount;

    mapping (uint256 => Collection) collection;
  }

  function packStorage() internal pure returns (Storage storage ds) {
    bytes32 position = STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event LogMintPack(
    address minter,
    uint256 tokenID
  );

  event LogCreateNewCollection(
    uint256 index
  );

  event LogAddCollectible(
    uint256 cID,
    string title
  );

  event LogUpdateMetadata(
    uint256 cID,
    uint256 collectibleId,
    uint256 propertyIndex,
    string value
  );

  event LogAddVersion(
    uint256 cID,
    uint256 collectibleId,
    string asset
  );

  event LogUpdateVersion(
    uint256 cID,
    uint256 collectibleId,
    uint256 versionNumber
  );

  event LogAddNewLicense(
    uint256 cID,
    string license
  );

  function random(uint256 cID) internal view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, packStorage().collection[cID].totalTokenCount)));
  }

  function randomTokenID(address relics, uint256 cID) external relicSafety(relics) returns (uint256, uint256) {
    Storage storage ds = packStorage();

    uint256 randomID = random(cID) % ds.collection[cID].shuffleIDs.length;
    uint256 tokenID = ds.collection[cID].shuffleIDs[randomID];

    emit LogMintPack(msg.sender, tokenID);

    return (randomID, tokenID);
  }

  modifier onlyDAO() {
    require(msg.sender == packStorage().daoAddress, "Wrong address");
    _;
  }

  modifier relicSafety(address relics) {
    Storage storage ds = packStorage();
    require(relics == ds.relicsAddress);
    _;
  }

  /**
   * Map token order w/ URI upon mints
   * Sample token ID (edition #77) with collection of 12 different assets: 1200077
   */
  function createTokenIDs(uint256 cID, uint256 collectibleCount, uint16 editions) private {
    Storage storage ds = packStorage();

    for (uint16 i = 0; i < editions; i++) {
      uint32 tokenID = uint32((cID + 1) * 100000000) + uint32((collectibleCount + 1) * 100000) + uint32(i + 1);
      ds.collection[cID].shuffleIDs.push(tokenID);
    }
  }

  function createNewCollection(
    string memory _baseURI,
    bool _editioned,
    uint256[] memory _initParams,
    string[] memory _metadataKeys,
    string memory _licenseURI,
    address _mintPass,
    uint256 _mintPassDuration,
    bool[] memory _mintPassParams
  ) external onlyDAO {
    require(_initParams[1] <= 50, "Limit of 50");
    Storage storage ds = packStorage();

    ds.collection[ds.collectionCount].baseURI = _baseURI;
    ds.collection[ds.collectionCount].editioned = _editioned;
    ds.collection[ds.collectionCount].tokenPrice = _initParams[0];
    ds.collection[ds.collectionCount].bulkBuyLimit = uint16(_initParams[1]);
    ds.collection[ds.collectionCount].saleStartTime = _initParams[2];
    ds.collection[ds.collectionCount].licenseURI[0] = _licenseURI;
    ds.collection[ds.collectionCount].licenseVersion = 1;

    if (_mintPass != address(0)) {
      ds.collection[ds.collectionCount].mintPass = true;
      ds.collection[ds.collectionCount].mintPassAddress = _mintPass;
      ds.collection[ds.collectionCount].mintPassContract = ERC721(_mintPass);
      ds.collection[ds.collectionCount].mintPassDuration = _mintPassDuration;
      ds.collection[ds.collectionCount].mintPassOnly = _mintPassParams[0];
      ds.collection[ds.collectionCount].mintPassFree = _mintPassParams[1];
      ds.collection[ds.collectionCount].mintPassBurn = _mintPassParams[2];
    } else {
      ds.collection[ds.collectionCount].mintPass = false;
      ds.collection[ds.collectionCount].mintPassDuration = 0;
      ds.collection[ds.collectionCount].mintPassOnly = false;
      ds.collection[ds.collectionCount].mintPassFree = false;
      ds.collection[ds.collectionCount].mintPassBurn = false;
    }

    for (uint8 i; i < _metadataKeys.length; i++) {
      ds.collection[ds.collectionCount].metadataKeys[i] = _metadataKeys[i];
    }

    ds.collection[ds.collectionCount].metadataKeysLength = uint16(_metadataKeys.length);

    ds.collectionCount++;

    emit LogCreateNewCollection(ds.collectionCount);
  }

  // Add single collectible asset with main info and metadata properties
  function addCollectible(uint256 cID, string[] memory _coreData, uint16 _editions, string[] memory _assets, MetadataStore[] memory _metadataValues, Fee[] memory _fees) external onlyDAO {
    Storage storage ds = packStorage();

    Collection storage collection = ds.collection[cID];
    uint256 collectibleCount = collection.collectibleCount;

    uint256 sum = 0;
    for (uint256 i = 0; i < _fees.length; i++) {
      require(_fees[i].recipient != address(0x0), "No recipient");
      require(_fees[i].value != 0, "Fee negative");
      collection.secondaryFees[collectibleCount].push(Fee({
        recipient: _fees[i].recipient,
        value: _fees[i].value
      }));
      sum = sum.add(_fees[i].value);
    }

    require(sum < 10000, "Fee GT 100%");
    require(_editions > 0, "GT 0");

    collection.collectibles[collectibleCount] = SingleCollectible({
      title: _coreData[0],
      description: _coreData[1],
      count: _editions,
      currentVersion: uint16(_assets.length),
      assets: _assets,
      totalVersionCount: uint16(_assets.length)
    });

    uint8[] memory propertyNames = new uint8[](_metadataValues.length);
    string[] memory propertyValues = new string[](_metadataValues.length);
    bool[] memory modifiables = new bool[](_metadataValues.length);
    for (uint256 i = 0; i < _metadataValues.length; i++) {
      propertyNames[i] = _metadataValues[i].propertyKey;
      propertyValues[i] = _metadataValues[i].value;
      modifiables[i] = _metadataValues[i].modifiable; // 1 is modifiable, 0 is permanent
    }

    collection.metadata[collectibleCount] = Metadata({
      name: propertyNames,
      value: propertyValues,
      modifiable: modifiables,
      propertyCount: uint16(_metadataValues.length)
    });

    uint16 editions = _editions;
    createTokenIDs(cID, collectibleCount, editions);

    collection.collectibleCount++;
    collection.totalTokenCount = collection.totalTokenCount.add(editions);

    emit LogAddCollectible(cID, _coreData[0]);
  }

  function checkTokensForMintPass(uint256 cID, uint256 mintPassTokenId, address minter) private returns (bool) {
    Storage storage ds = packStorage();
    if (ds.collection[cID].mintPassContract.ownerOf(mintPassTokenId) == minter &&
        ds.collection[cID].mintPassClaims[mintPassTokenId] != true) {
      ds.collection[cID].mintPassClaims[mintPassTokenId] = true;
      if (ds.collection[cID].mintPassBurn) ds.collection[cID].mintPassContract.safeTransferFrom(msg.sender, address(0xdEaD), mintPassTokenId);
      return true;
    } else return false;
  }

  function checkMintPass(address relics, uint256 cID, uint256 mintPassTokenId, address users) external relicSafety(relics) returns (bool) {
    Storage storage ds = packStorage();

    bool canMintPass = false;
    if (ds.collection[cID].mintPass && checkTokensForMintPass(cID, mintPassTokenId, users)) canMintPass = true;

    if (ds.collection[cID].mintPassOnly) {
      require(canMintPass, "Mint pass only");
      require(block.timestamp > ds.collection[cID].saleStartTime - ds.collection[cID].mintPassDuration, "ERR: Sale start");
    } else {
      if (canMintPass) require (block.timestamp > (ds.collection[cID].saleStartTime - ds.collection[cID].mintPassDuration), "ERR: Sale start");
      else require(block.timestamp > ds.collection[cID].saleStartTime, "ERR: Sale start");
    }

    return canMintPass;
  }

  function bulkMintChecks(uint256 cID, uint256 amount) external {
    Storage storage ds = packStorage();

    require(amount > 0, 'Missing amount');
    require(!ds.collection[cID].mintPassOnly, 'Mint pass only');
    require(amount <= ds.collection[cID].bulkBuyLimit, "Over limit");
    require(amount <= ds.collection[cID].shuffleIDs.length, "Total supply reached");
    require((block.timestamp > ds.collection[cID].saleStartTime), "ERR: Sale start");
  }

  function mintPassClaimed(uint256 cID, uint256 tokenId) public view returns (bool) {
    Storage storage ds = packStorage();
    return (ds.collection[cID].mintPassClaims[tokenId] == true);
  }

  function remainingTokens(uint256 cID) public view returns (uint256) {
    Storage storage ds = packStorage();
    return ds.collection[cID].shuffleIDs.length;
  }

  // Modify property field only if marked as updateable
  function updateMetadata(uint256 cID, uint256 collectibleId, uint256 propertyIndex, string memory value) external onlyDAO {
    Storage storage ds = packStorage();
    require(ds.collection[cID].metadata[collectibleId - 1].modifiable[propertyIndex], 'Uneditable');
    ds.collection[cID].metadata[collectibleId - 1].value[propertyIndex] = value;
    emit LogUpdateMetadata(cID, collectibleId, propertyIndex, value);
  }

  // Add new asset, does not automatically increase current version
  function addVersion(uint256 cID, uint256 collectibleId, string memory asset) public onlyDAO {
    Storage storage ds = packStorage();
    ds.collection[cID].collectibles[collectibleId - 1].assets[ds.collection[cID].collectibles[collectibleId - 1].totalVersionCount - 1] = asset;
    ds.collection[cID].collectibles[collectibleId - 1].totalVersionCount++;
    emit LogAddVersion(cID, collectibleId, asset);
  }

  // Adds new license and updates version to latest
  function addNewLicense(uint256 cID, string memory _license) public onlyDAO {
    Storage storage ds = packStorage();
    require(cID < ds.collectionCount, 'ID DNE');
    ds.collection[cID].licenseURI[ds.collection[cID].licenseVersion] = _license;
    ds.collection[cID].licenseVersion++;
    emit LogAddNewLicense(cID, _license);
  }

  function getLicense(uint256 cID, uint256 versionNumber) public view returns (string memory) {
    Storage storage ds = packStorage();
    return ds.collection[cID].licenseURI[versionNumber - 1];
  }

  function getCurrentLicense(uint256 cID) public view returns (string memory) {
    Storage storage ds = packStorage();
    return ds.collection[cID].licenseURI[ds.collection[cID].licenseVersion - 1];
  }

  function getCollectionInfo(uint256 cID) public view returns (string memory) {
    Storage storage ds = packStorage();
    
    string memory encodedMetadata = '';
    for (uint i = 0; i < ds.collection[cID].metadataKeysLength; i++) {
      encodedMetadata = string(abi.encodePacked(
        encodedMetadata,
        '{"index":"',
        HelperFunctions.toString(i),
        '", "name":"',
        ds.collection[cID].metadataKeys[i],
        '"}',
        i == ds.collection[cID].metadataKeysLength - 1 ? '' : ',')
      );
    }

    return string(
      abi.encodePacked(
        '{"weiPrice": "',
        HelperFunctions.toString(ds.collection[cID].tokenPrice),
        '", "saleStart": "',
        HelperFunctions.toString(ds.collection[cID].saleStartTime),
        '", "mintPass": "',
        ds.collection[cID].mintPass ? 'true' : 'false',
        '", "passAddress": "',
        HelperFunctions.addressToString(ds.collection[cID].mintPassAddress),
        '", "passDuration": "',
        HelperFunctions.toString(ds.collection[cID].mintPassDuration),
        '", "passOnly": "',
        ds.collection[cID].mintPassOnly ? 'true' : 'false',
        '", "passBurn": "',
        ds.collection[cID].mintPassBurn ? 'true' : 'false',
        '", "metadata": [',
          encodedMetadata,
        '] }'
      )
    );
  }

  // Dynamic base64 encoded metadata generation using on-chain metadata and edition numbers
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    Storage storage ds = packStorage();

    uint256 edition = HelperFunctions.safeParseInt(HelperFunctions.substring(HelperFunctions.toString(tokenId), bytes(HelperFunctions.toString(tokenId)).length - 5, bytes(HelperFunctions.toString(tokenId)).length)) - 1;
    uint256 collectibleId = HelperFunctions.safeParseInt(HelperFunctions.substring(HelperFunctions.toString(tokenId), bytes(HelperFunctions.toString(tokenId)).length - 8, bytes(HelperFunctions.toString(tokenId)).length - 5)) - 1;
    uint256 cID = ((tokenId - ((collectibleId + 1) * 100000)) - (edition + 1)) / 100000000 - 1;
    string memory encodedMetadata = '';

    Collection storage collection = ds.collection[cID];

    for (uint i = 0; i < collection.metadata[collectibleId].propertyCount; i++) {
      encodedMetadata = string(abi.encodePacked(
        encodedMetadata,
        '{"trait_type":"',
        collection.metadataKeys[collection.metadata[collectibleId].name[i]],
        '", "value":"',
        collection.metadata[collectibleId].value[i],
        '", "permanent":"',
        collection.metadata[collectibleId].modifiable[i] ? 'false' : 'true',
        '"}',
        i == collection.metadata[collectibleId].propertyCount - 1 ? '' : ',')
      );
    }

    SingleCollectible storage collectible = collection.collectibles[collectibleId];
    uint256 asset = collectible.currentVersion - 1;
    string memory encoded = string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                collectible.title,
                collection.editioned ? ' #' : '',
                collection.editioned ? HelperFunctions.toString(edition + 1) : '',
                '", "description":"',
                collectible.description,
                '", "image": "',
                collection.baseURI,
                collectible.assets[asset],
                '", "license": "',
                getCurrentLicense(cID),
                '", "attributes": [',
                encodedMetadata,
                '] }'
              )
            )
          )
        )
      );

    return encoded;
  }

  // Secondary sale fees apply to each individual collectible ID (will apply to a range of tokenIDs);
  function getFeeRecipients(uint256 tokenId) public view returns (address payable[] memory) {
    Storage storage ds = packStorage();

    uint256 edition = HelperFunctions.safeParseInt(HelperFunctions.substring(HelperFunctions.toString(tokenId), bytes(HelperFunctions.toString(tokenId)).length - 5, bytes(HelperFunctions.toString(tokenId)).length)) - 1;
    uint256 collectibleId = HelperFunctions.safeParseInt(HelperFunctions.substring(HelperFunctions.toString(tokenId), bytes(HelperFunctions.toString(tokenId)).length - 8, bytes(HelperFunctions.toString(tokenId)).length - 5)) - 1;
    uint256 cID = ((tokenId - ((collectibleId + 1) * 100000)) - (edition + 1)) / 100000000 - 1;
    Fee[] memory _fees = ds.collection[cID].secondaryFees[collectibleId];
    address payable[] memory result = new address payable[](_fees.length);
    for (uint i = 0; i < _fees.length; i++) {
      result[i] = _fees[i].recipient;
    }
    return result;
  }

  function getFeeBps(uint256 tokenId) public view returns (uint[] memory) {
    Storage storage ds = packStorage();

    uint256 edition = HelperFunctions.safeParseInt(HelperFunctions.substring(HelperFunctions.toString(tokenId), bytes(HelperFunctions.toString(tokenId)).length - 5, bytes(HelperFunctions.toString(tokenId)).length)) - 1;
    uint256 collectibleId = HelperFunctions.safeParseInt(HelperFunctions.substring(HelperFunctions.toString(tokenId), bytes(HelperFunctions.toString(tokenId)).length - 8, bytes(HelperFunctions.toString(tokenId)).length - 5)) - 1;
    uint256 cID = ((tokenId - ((collectibleId + 1) * 100000)) - (edition + 1)) / 100000000 - 1;
    Fee[] memory _fees = ds.collection[cID].secondaryFees[collectibleId];
    uint[] memory result = new uint[](_fees.length);
    for (uint i = 0; i < _fees.length; i++) {
      result[i] = _fees[i].value;
    }

    return result;
  }

  function royaltyInfo(uint256 tokenId, uint256 value) public view returns (address recipient, uint256 amount){
    address payable[] memory rec = getFeeRecipients(tokenId);
    require(rec.length <= 1, "More than 1 royalty recipient");

    if (rec.length == 0) return (address(this), 0);
    return (rec[0], getFeeBps(tokenId)[0] * value / 10000);
  }
}