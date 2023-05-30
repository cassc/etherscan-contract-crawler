// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "hardhat/console.sol";
//access control
import "@openzeppelin/contracts/access/AccessControl.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./MetropolisWorldGenesis.sol";

interface ExtInter {
  function extensionNameList(uint256[] calldata exts)external view returns (bytes memory);
}

//holds the data for the NFT's done this way to reduce gas for the user when they mint and maintain everything on chain.

contract AddingData is AccessControl {
  address public EXT_CONTRACT;
  ExtInter ExtContract;
  //other contracts
  //MetropolisWorldGenesis mg;

  //defining the access roles
  bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
  bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

  uint16 public addedNamesCount = 0;
  uint16 public addedFeaturesCount = 0;
  // uint16[] private idsAdded;

  //store a list of all the NFT's available to mint.
  //this is built on when the constructor is called.
  mapping(uint => PropertyAttributes) public defaultProperties;
  //store which has been minted.
  mapping(uint256 => bool) public MintedNfts;
  //store mint prices
  mapping(uint16 => uint256) public MintPrice;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(UPDATER_ROLE, msg.sender);
    //mg = MetropolisWorldGenesis(_t);
  }

  function addContractRoles(address cityContract)external onlyRole(UPDATER_ROLE){
    require(cityContract != address(0), "Please enter valid contract address");
    _grantRole(CONTRACT_ROLE, cityContract);
  }

  function setUpExtensionContractInterface(address extContract)external onlyRole(UPDATER_ROLE){
    EXT_CONTRACT = extContract;
    ExtContract = ExtInter(EXT_CONTRACT);
  }

  /**
   * @dev adding the first part of the metadata to the contract
   * @notice data is split into 2 halves so we can deploy it all and maintian on chain not 3rd party ipfs
   * @param ids the key element is this array which matches with other half
   */
  function addNameDescImagePricesTowers(
    uint16[] memory ids,
    string[] memory propertyNames,
    uint256[] memory prices,
    string[] memory descs,
    string[] memory images,
    string[] memory towers,
    string[] memory districts
  ) external onlyRole(UPDATER_ROLE) {
    uint16 count = addedNamesCount;
    for (uint16 i = 0; i < ids.length; i++) {
      uint16 mapNo = ids[i];
      defaultProperties[mapNo] = PropertyAttributes({
        id: ids[i],
        propertyIndex: ids[i],
        name: propertyNames[i],
        description: descs[i],
        image: images[i],
        properties: Properties({
          tower: towers[i],
          district: districts[i],
          neighborhood: "", //neighborhoods[i],
          primary_type: "", //primeTypes[i],
          sub_type_1: "", //subType1[i],
          sub_type_2: "", //subType2[i],
          structure: "", //structures[i],
          feature_1: "", //feature1[i],
          feature_2: "", //feature2[i],
          feature_3: "", //feature3[i],
          feature_4: "", //feature4[i],
          tier: "" //raritys[i]
        }),
        extensionCount: 0,
        extensionIds: new uint256[](0)
      });
      //created minted list with all false
      MintedNfts[ids[i]] = false;
      //record the mint price
      MintPrice[ids[i]] = prices[i];
      count ++;
    }
    addedNamesCount = count;
  }

  /**
   * @dev adding the second part of the metadata to the contract
   * @notice data is split into 2 halves so we can deploy it all and maintian on chain not 3rd party ipfs
   * @param ids the key element is this array which matches with other half
   */
  function addNftData(
    uint16[] memory ids,
    string[] memory neighs,
    string[] memory primes,
    string[] memory subs1,
    string[] memory subs2,
    string[] memory structures,
    string[] memory fets1,
    string[] memory fets2,
    string[] memory fets3,
    string[] memory fets4,
    string[] memory tiers
  ) external onlyRole(UPDATER_ROLE) {
    uint16 fetCount = addedFeaturesCount;
    for (uint16 i = 0; i < ids.length; i++) {
      uint16 id = ids[i];
      PropertyAttributes memory x = defaultProperties[id];
      x.properties.neighborhood = neighs[i];
      x.properties.primary_type = primes[i];
      x.properties.sub_type_1 = subs1[i];
      x.properties.sub_type_2 = subs2[i];
      x.properties.structure = structures[i];
      x.properties.feature_1 = fets1[i];
      x.properties.feature_2 = fets2[i];
      x.properties.feature_3 = fets3[i];
      x.properties.feature_4 = fets4[i];
      x.properties.tier = tiers[i];
      defaultProperties[id] = x;
      fetCount++;
    }
    addedFeaturesCount = fetCount;
  }

  /**
    @dev function to allow us to change the image at a later date if needed. 
    @param propId the id we use to referance the property taken from master sheet 
    @param image string of the new image address. 
     */
  function changeImage(uint16 propId, string calldata image)
    external
    onlyRole(UPDATER_ROLE)
  {
    defaultProperties[propId].image = image;
  }

  /**
    @dev function to allow us to adjust price of individual properties 
    @param propId the id we use to referance the property taken from master sheet 
    @param newPrice the new price to charge. 
     */
  function changePrice(uint16 propId, uint256 newPrice)
    external
    onlyRole(UPDATER_ROLE)
  {
    MintPrice[propId] = newPrice;
  }

  /**
   *@dev returns the price of a property NFT
   *@param nftId the id of the property id you want the price for.
   */
  function price(uint16 nftId) external view returns (uint256) {
    return MintPrice[nftId];
  }

  /**
   * @dev returns the metadata for a given property NFT
   * @param nftId the id of the property nft you want the metadata for.
   */
  function nftProperties(uint16 nftId)
    external
    view
    returns (PropertyAttributes memory)
  {
    return defaultProperties[nftId];
  }

  /**
   *@dev returns a bool to indicate if a property has been minted yet.
   *@notice we use mint status to avoid properties being minted more then once.
   *@param nftId the id of the property you want to chaeck mint status of
   */
  function getMintStatus(uint16 nftId) external view returns (bool) {
    return MintedNfts[nftId];
  }

  /**
   *@dev sets mint status to true, used by main contract in minting process
   *@param nftId the id of the property you want to change the mint status of
   */
  function changeMintStatus(uint16 nftId) external onlyRole(CONTRACT_ROLE) {
    MintedNfts[nftId] = true;
  }

  /**
    *@dev used to add an extension NFT to the property 
    *@notice called by the extension contract 
    @param nftId the internal id of the property NFT 
    @param extId the token id of the extension NFT 
     */
  function addExtensionToMetadata(uint16 nftId, uint256 extId)external onlyRole(CONTRACT_ROLE){
    //PropertyAttributes memory x = defaultProperties[nftId];
    console.log("starting addExtensionToMetadata");
    defaultProperties[nftId].extensionCount += 1;
    defaultProperties[nftId].extensionIds.push(extId);
    console.log("added extention in data contract");
  }

  /**
   *@dev used to remove the extension from the property
   *@notice only called by the extnesions contract
   *@param nftId the internal id of the property nft
   *@param extId the ID of the extension NFT
   */
  function removeExtensionFromMetadata(uint16 nftId, uint256 extId)external onlyRole(CONTRACT_ROLE){
    console.log("starting removeExtensionFromMetadata");
    for (uint16 i = 0; i < defaultProperties[nftId].extensionIds.length; i++) {
      if (defaultProperties[nftId].extensionIds[i] == extId) {
        defaultProperties[nftId].extensionIds[i] = defaultProperties[nftId].extensionIds[defaultProperties[nftId].extensionIds.length - 1];
        defaultProperties[nftId].extensionIds.pop();
        defaultProperties[nftId].extensionCount -= 1;
        console.log("removed it ");
      }
    }
  }


  /**
  @dev used by the other contracts to verify of the user owns the extension. 
  @param propId the internal ID of the propety nft 
  @param extTokenId the token ID of the extension. 
   */
  function checkOwnershipOfExtension(uint16 propId, uint256 extTokenId)external view onlyRole(CONTRACT_ROLE) returns (bool){
    for (uint16 i = 0; i < defaultProperties[propId].extensionIds.length; i++) {
      if (defaultProperties[propId].extensionIds[i] == extTokenId) {
        return true;
      }
    }
    return false;
  }

  function sectionOne(uint16 propId) external view returns (bytes memory) {
    bytes memory dataURI = abi.encodePacked(
      '{"name": "',
      defaultProperties[propId].name,
      '", "description": "',
      defaultProperties[propId].description,
      '", "image": "',
      defaultProperties[propId].image
    );
    return dataURI;
  }

  function sectionTwo(uint16 propId) external view returns (bytes memory) {
    bytes memory dataURI = abi.encodePacked(
      '", "attributes": [{ "trait_type": "Tower", "value": "',
      defaultProperties[propId].properties.tower,
      '"},{"trait_type": "District", "value": "',
      defaultProperties[propId].properties.district,
      '"},{"trait_type": "Neighborhood", "value": "',
      defaultProperties[propId].properties.neighborhood,
      '"},{"trait_type": "Primary Type", "value": "',
      defaultProperties[propId].properties.primary_type
    );
    return dataURI;
  }

  function sectionThree(uint16 propId) external view returns (bytes memory) {
    bytes memory dataURI = abi.encodePacked(
      '"},{"trait_type": "Sub Type 1", "value": "',
      defaultProperties[propId].properties.sub_type_1,
      '"},{"trait_type": "Sub Type 2", "value": "',
      defaultProperties[propId].properties.sub_type_2,
      '"},{"trait_type": "Structure", "value": "',
      defaultProperties[propId].properties.structure,
      '"},{"trait_type": "Feature 1", "value": "',
      defaultProperties[propId].properties.feature_1,
      '"},{"trait_type": "Feature 2", "value": "',
      defaultProperties[propId].properties.feature_2,
      '"},{"trait_type": "Feature 3", "value": "',
      defaultProperties[propId].properties.feature_3
    );
    return dataURI;
  }

  function extensionNames(uint16 propId) internal view returns (bytes memory) {
    if (defaultProperties[propId].extensionCount > 0) {
      return
        ExtContract.extensionNameList(defaultProperties[propId].extensionIds);
    } else {
      bytes memory st = abi.encodePacked(
        '"},{"trait_type": "Extensions", "value": "',
        "None"
      );
      return st;
    }
  }

  function sectionFour(uint16 propId) external view returns (bytes memory) {
    bytes memory dataURI = abi.encodePacked(
      '"},{"trait_type": "Feature 4", "value": "',
      defaultProperties[propId].properties.feature_4,
      '"},{"trait_type": "Tier", "value": "',
      defaultProperties[propId].properties.tier,
      extensionNames(propId),
      '"},{ "display_type": "boost_number","trait_type": "Extensions", "value":"',
      Strings.toString(defaultProperties[propId].extensionCount),
      '"}]}'
    );
    return dataURI;
  }
}

// genesis
// add all the id to the mapping of minted nbfts with false

// for (uint i = 0; i < propertyNames.length; i ++){
//     defaultProperties.push(
//         PropertyAttributes({
//             id: i+1,
//             propertyIndex: i,
//             name: propertyNames[i],
//             description: '',//description[i],
//             image:'',//imageURIs[i],
//             properties: Properties( {
//                 tower: '',//towers[i],
//                 district: '',//districts[i],
//                 neighborhood: '',//neighborhoods[i],
//                 primary_type: '',//primeTypes[i],
//                 sub_type_1: '',//subType1[i],
//                 sub_type_2: '',//subType2[i],
//                 structure: '',//structures[i],
//                 feature_1: '',//feature1[i],
//                 feature_2: '',//feature2[i],
//                 feature_3: '',//feature3[i],
//                 feature_4: '',//feature4[i],
//                 feature_5: '',//feature5[i],
//                 rarity: ''//raritys[i]
//             }),
//             extensionCount: 0
//             //extentions: [ex]
//     })
//     );
//     //created minted list with all false
//     MintedNfts[i] = false;
//     //record the mint price
//     MintPrice[i] = prices[i] * (1 ether);
//     //PropertyAttributes memory p = defaultProperties[i];
//     //console.log("Done initializing %s w/ HP %s, img %s", p.name, p.description, p.image);
// }

// //TODO: add NFT as extention
// function addNFTExtension(string memory cat, string memory name, string memory contractId, string memory tokenId, uint propId) public{

//     Extension memory ex = Extension({
//         catergory: cat,
//         name: name,
//         contractId: contractId,
//         tokenId: tokenId
//     });

//     uint _propertyIndex = propId - 1;
//     uint _tokenId = PropertyIndexTotokenId[_propertyIndex];

//     //update the mapping to include the extension
//     prop_extensions[_tokenId].extentions_list.push(ex);

// }

// //TODO: sell with NFT extensions

// //TODO: sell without NFT extensions
//     struct PropertyAttributes {
//         uint256 id;
//         uint256 propertyIndex;
//         string name;
//         string description;
//         string image;
//         Properties properties;
//         uint256 extensionCount;
//     }

//     struct Properties {
//         string tower;
//         string district;
//         string neighborhood;
//         string primary_type;
//         string sub_type_1;
//         string sub_type_2;
//         string structure;
//         string feature_1;
//         string feature_2;
//         string feature_3;
//         string feature_4;
//         string feature_5;
//         string feature_6;
//     }