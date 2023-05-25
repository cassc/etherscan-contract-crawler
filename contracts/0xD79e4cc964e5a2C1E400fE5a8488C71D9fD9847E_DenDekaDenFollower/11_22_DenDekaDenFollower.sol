pragma solidity ^0.8.0;

// SPDX-License-Identifier: GLP-3.0



/* 
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@............[email protected]@
* @@@............[email protected]@
* @@@@........................................................................*@@@
* @@@@@.......[email protected]@@@@
* @@@@@@#....[email protected]@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@*[email protected]@@@@@@@[email protected]@@@@@@@%[email protected]@@@@@@@@@@@
* @@@@@@@@@@@@@..............%@@@@@@@[email protected]@@@@@@,[email protected]@@@@@@@@@@@
* @@@@@@@@@@@@@@[email protected]@@@@@@&............/@@@@@@@............/@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@[email protected]@@@@@@*[email protected]@@@@@@@............*@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@.......,@@@@@@@[email protected]@@@@@@%............(@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@............/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@%...............................,@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,............/@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(............%@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@............,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(............%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@([email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.... @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 電殿神伝 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ DenDekaDen @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Do you believe? @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ JD & BH @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import "./ERC721ARoyaltiesOperatorFilterable.sol";
import "./RelicEquippable.sol";
import "./UserDefinableAttributes.sol";

/**
 * @title DenDekaDenFollower
 *
 * @dev DenDekaDenFollower is a ERC721A contract that implements the following:
 *      - ERC721A Royalties Operator Filterable
 *      - RelicEquippable
 *      - UserDefinableAttributes
 */


contract DenDekaDenFollower is 
  ERC721ARoyaltiesOperatorFilterable,
  RelicEquippable,
  UserDefinableAttributes
{

  // Libraries
  using Strings for uint256;

  // CONSTANTS -- do not need to be initialized
  uint8 constant NUM_CHARACTERS = 7;
  uint8 constant MAX_MINT_BATCH = 77;
  uint256 constant FOLLOWERS_PER_CHARACTER = 1111;
  string constant PROVINANCE = "QmQrEAhxwf78cV175DmRMF9dmE4qexmsok1sdVij3dyQZQ";

  // PRICES
  uint256 whitelistMintPrice = 77770000000000000;
  uint256 publicMintPrice = 77770000000000000;
  uint256 attributeChangePrice = 0;

  // PUBLIC RELEASE TIME
  uint256 public publicMintTime = 1680620399;

  // WHITELIST VARIABLES
  bytes32 whitelistRoot;

  // Randomized traits offset
  uint256 public provinanceOffset;

  // base metadata uri
  string baseURI = "https://dendekaden.com/api/metadata/";

  // beneficiary
  address beneficiary = 0x9a4401b3D82335795dE2Ec38219e6B6a58eA46Cc;
  
  // track number of whitelist slots minted    
  mapping(bytes32 /* whitelistNodeId */ => uint256 /* numMinted*/) whitelistNumMinted;

  // track number of public mints
  // NOTE: ideally we would use _numberMinted, but unfortunately
  // logic is that aidropped tokens and whitelists should not count against public mints
  mapping(address /* user */ => uint256 /* numMinted */ ) publicNumMinted;

  // track mints per character -- will be array the size of NUM_CHARACTERS
  uint256[] characterMints = new uint256[](NUM_CHARACTERS);

  // track if attributes have been set for token
  mapping(uint256 /* tokenId */ => bool) attributesSet;


  constructor(string memory name_, string memory symbol_) ERC721ARoyaltiesOperatorFilterable(name_, symbol_, beneficiary, 777) {
    publicMintTime;
  }

  // =============================================================
  //                    Public Frontend Functions
  // =============================================================
  

  /**
   * @dev Check remaining mints for each character
   */
  function characterMintsRemaining() public view returns (uint256[] memory) {
    uint256[] memory remainingMints = new uint256[](NUM_CHARACTERS);
    for(uint8 i = 0; i < NUM_CHARACTERS; i++) {
      remainingMints[i] = FOLLOWERS_PER_CHARACTER - characterMints[i];
    }
    return remainingMints;
  }

  /**
   * @dev Checks the mints remaining for public and whitelist if applicable
   * 
   * Used for frontend
   */
  function userMintsRemaining(
     // ddress wanting to mint
    address user,
    // character minting allowance in merkle proof
    uint8 allowance,
    // timestamp of eligability in merkle proof
    uint256 eligableTimestamp,
    // merkle proof
    bytes32[] memory proof
  ) public view returns (uint256 whitelistMints) {

    whitelistMints = 0;

    bytes32 leaf = generateWhitelistLeaf(user, allowance, eligableTimestamp);
    if(MerkleProof.verify(proof, whitelistRoot, leaf)) {
      whitelistMints = allowance - whitelistNumMinted[leaf];
    }
  }


  /**
   * @dev Checks if an address and proof is  or whitelist
   * 
   * Return LEAF as well so we can use to increment allowance but keep
   * this function as a view function
   */
  function whitelistEligability(
    // address wanting to mint
    address user,
    // quantity to mint
    uint256 quantity,
    // character minting allowance in merkle proof
    uint8 allowance,
    // timestamp of eligability in merkle proof
    uint256 eligableTimestamp,
    // merkle proof
    bytes32[] memory proof
  ) public view returns (bool, bytes32) {
    
    bytes32 leaf = generateWhitelistLeaf(user, allowance, eligableTimestamp);
    
    if(block.timestamp < eligableTimestamp ) return (false, leaf);

    // validate this leaf has not overminted
    if(whitelistNumMinted[leaf] + quantity > allowance) revert IneligableMint();

    return (MerkleProof.verify(proof, whitelistRoot, leaf), leaf);
  }


  // =============================================================
  //                        Mint Functions
  // =============================================================
  

  /**
   * @dev Whitelist mint function
   */
  function mintFollowerWhitelist(
    uint8 quantity,
    // ID of DDD character
    uint8 characterId,
    // character minting allowance in merkle proof
    uint8 allowance,
    // timestamp of eligability in merkle proof
    uint256 eligableTimestamp,
    // merkle proof
    bytes32[] memory proof,
    // address to mint follower to -- can be different from whitelist address
    address to
  ) public payable {
    
    // check eligibility of "to" address so that users can mint from hot wallet to cold wallet
    (bool eligable, bytes32 leaf) = whitelistEligability(to, quantity, allowance, eligableTimestamp, proof);

    if(!eligable) revert IneligableMint();

    // minting from other contract not allowed -- potential contract could be whitelisted
    if(tx.origin != msg.sender) revert IneligableMint();

    whitelistNumMinted[leaf] += quantity;

    // mint token
    _mintFollower(to, quantity, characterId, whitelistMintPrice);

  }

  /**
   * @dev Batch Whitelist Mint
   */
  function mintFollowerWhitelistBatch(
    uint8[] calldata quantities,
    // ID of DDD character
    uint8[] calldata characterIds,
    // character minting allowance in merkle proof
    uint8 allowance,
    // timestamp of eligability in merkle proof
    uint256 eligableTimestamp,
    // merkle proof
    bytes32[] memory proof,
    // address to mint follower to -- can be different from whitelist address
    address to
  ) public payable {

    // validate payment
    uint256 totalQuantity = 0;

    for(uint256 i = 0; i < quantities.length; i++) {
      if(quantities[i] > 0) {
        mintFollowerWhitelist(quantities[i], characterIds[i], allowance, eligableTimestamp, proof, to);
      }
      totalQuantity += quantities[i];
    }

    if(msg.value < whitelistMintPrice * totalQuantity) revert InsufficientPayment();
  }

  /**
   * @dev Public mint function
   */
  function mintFollowerPublic(address to, uint8 quantity, uint8 characterId) public payable {
    
    // ensure sale has started
    if(block.timestamp < publicMintTime) revert IneligableMint();
    
    // ensure quantity per character is < 
    if(quantity > NUM_CHARACTERS) revert MaxBatchExceeded();

    // minting from other contract not allowed
    if(tx.origin != msg.sender) revert IneligableMint();
    
    _mintFollower(to, quantity, characterId, publicMintPrice);

  }

  /**
   * @dev Batch Public Mint
   */
  function mintFollowerPublicBatch(address to, uint8[] calldata quantities, uint8[] calldata characterIds) public payable {
    
    uint256 totalQuantity = 0;
    
    for(uint256 i = 0; i < quantities.length; i++) {
      
      if(quantities[i] > 0) {
        mintFollowerPublic(to, quantities[i], characterIds[i]);
      }
      totalQuantity += quantities[i];
    }

    if(msg.value < publicMintPrice * totalQuantity) revert InsufficientPayment();
  }

  /**
   * @dev Air drop mint function
   * 
   */
  function airdropFollowers(address[] calldata to, uint8[] calldata quantities, uint8[] calldata characterIds) public onlyOwner {
    for(uint256 i = 0; i < to.length; i++) {
      _mintFollower(to[i], quantities[i], characterIds[i], 0);
    }
  }



  /**
   * @dev Common mint function
   */
  function _mintFollower(address to, uint8 quantity, uint8 characterId, uint256 price) internal {
    
    // ensure valid character id
    if(!(characterId < NUM_CHARACTERS)) revert InvalidCharacter();

    // ensure valid quantity
    if(quantity > MAX_MINT_BATCH) revert MaxBatchExceeded();
    
    // increment character mints
    characterMints[characterId] += quantity;

    // ensure character has mints left
    if(characterMints[characterId] > FOLLOWERS_PER_CHARACTER) revert NotEnoughSupply();
    
    // validate payment
    if(msg.value < price * uint256(quantity)) revert InsufficientPayment();


    // TODO: other validation???


    // Save start token to set extra data
    uint256 start = _nextTokenId();

    // actual mint
    _mint(to, quantity);
    
    // need to set extra data after tokens are initialized
    _setExtraDataAt(start, uint24(characterId));

  }

  

  // =============================================================
  //                       Attribute Functions
  // =============================================================
  // NOTE: Attributes with values of 0 means unset.


  /**
   * @dev Get ALL attributes. Used for SVG generation.
   * 
   * Returns:
   *  - characterId
   *  - user defined attributes
   *  - equipt relic attributes
   */
  function getAttributes(uint256 tokenId) public view returns (uint8 characterId, uint256[] memory userDefinedAttributes, address[] memory relicAddresses, uint256[] memory relicTokenIds) {

    // get characterId from extra data field
    TokenOwnership memory ownershipData = _ownershipOf(tokenId);

    characterId = uint8(ownershipData.extraData);

    userDefinedAttributes = getUserAttributes(tokenId);
    (relicAddresses, relicTokenIds) = getRelics(tokenId);
    
  }  

  /**
   * @dev Set attributes for a token
   * 
   * Will revert if not token owner
   */
  function setAttributesAndRelics(
    uint256 tokenId, 
    uint256[] memory attributeIds, 
    uint256[] memory attributeValues,
    address[] memory relicAddresses,
    uint256[] memory relicTokenIds
  ) public payable {

    // check if attributes have been set on token -- if first change, is free
    if(attributesSet[tokenId]) {
      if(msg.value < attributeChangePrice) revert InsufficientPayment();
    } else {
      attributesSet[tokenId] = true;
    }


    if(attributeIds.length > 0) {
      _setUserAttributes(tokenId, attributeIds, attributeValues);
    }

    if(relicAddresses.length > 0) {
      _equipRelics(tokenId, relicAddresses, relicTokenIds);
    }

  }

  /**
   * @dev Expose other ownership data
   * 
   * In future can leverage for staking, time locks, etc
   * 
   * Data includes:
   *  - address
   *  - timestamp of last mint/transfer
   *  - characterId
   */
  function getOwnershipData(uint256 tokenId) public view returns (TokenOwnership memory) {
    return _ownershipOf(tokenId);
  }


  // =============================================================
  //                       Metadata Functions
  // =============================================================

  /**
   * @dev Get owned tokens with their character ids
   */
  function ownedTokensWithCharacterIds(address addr) public view returns (uint256[] memory, uint8[] memory) {
    uint256[] memory ownedTokens = this.tokensOfOwner(addr);
    uint8[] memory characterIds = new uint8[](ownedTokens.length);

    for(uint256 i = 0; i < ownedTokens.length; i++) {
      characterIds[i] = uint8(_ownershipOf(ownedTokens[i]).extraData);
    }

    return (ownedTokens, characterIds);
  }


  /**
   * @dev Override baseURI
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  

  // =============================================================
  //                        Owner Functions
  // =============================================================
  

  /**
   * @dev Withdraw funds
   */
  function withdraw() public {
    (bool success, ) = beneficiary.call{ value: address(this).balance }('');
    if(!success) revert InsufficientPayment();
  }

  /**
   * @dev Set beneficiary and royalty fee
   */
  function setBeneficiary(address _beneficiary, uint96 feeNumerator) public onlyOwner {
    beneficiary = _beneficiary;

    _setDefaultRoyalty(_beneficiary, feeNumerator);
  }

  /**
   * @dev Set Base URI
   */
  function setBaseURI(string memory newURI) public onlyOwner {
    baseURI = newURI;
  }

  /**
   * @dev Set whitelist root
   */
  function setWhitelistRoot(bytes32 root) public onlyOwner {
    whitelistRoot = root;
  }

  /**
   * @dev Set prices
   */
  function setPrice(uint256 _whitelistMintPrice, uint256 _publicMintPrice) public onlyOwner {
    whitelistMintPrice = _whitelistMintPrice;
    publicMintPrice = _publicMintPrice;
  }

  /**
   * @dev Set attribute change price
   */
  function setAttributeChangePrice(uint256 _attributeChangePrice) public onlyOwner {
    attributeChangePrice = _attributeChangePrice;
  }

  /**
   * @dev Set public mint time
   */
  function setPublicMintTime(uint256 _time) public onlyOwner {
    publicMintTime = _time;
  }

  /**
   * @dev Set the provinance offset
   * 
   * Will result in a ~random value from 1-TOTAL_SUPPLY.
   * 
   * Will be set after minting period is complete.
   */
  function setProvinanceOffset() public onlyOwner {
    // if already set, cannot set again
    if(provinanceOffset > 0) revert InvalidPermissions();

    provinanceOffset = uint256(keccak256(abi.encodePacked(block.timestamp, block.number))) % (FOLLOWERS_PER_CHARACTER * NUM_CHARACTERS) + 1; 
  }


  // =============================================================
  //                      Util Functions
  // =============================================================  


  function generateWhitelistLeaf(
    address user,
    uint8 allowance,
    uint256 eligableTimestamp
  ) public pure returns (bytes32) {

    // user addresses are hashed for privacy on frontend
    bytes32 hashedUser = keccak256(abi.encodePacked(user)); 
    // validate merkle tree
    bytes32 leaf = keccak256(abi.encodePacked(hashedUser, allowance, eligableTimestamp));

    return leaf;
  }
  
  
  // =============================================================
  //                      Override Functions
  // =============================================================


  function ownerOf(uint256 tokenId) public view override (
    ERC721A, 
    IERC721A, 
    IERC721TokenOwner
  ) returns (address) {
    return ERC721A.ownerOf(tokenId);
  }

  /**
   * @dev Override _extraData function as we want to keep
   * characterID stored on token after transfer
   */
  function _extraData(
    address /* from */,
    address /* to */,
    uint24 previousExtraData
  ) internal view override returns (uint24) {
    return previousExtraData;
  }


  // =============================================================
  //                      Custom Errors
  // =============================================================


  error IneligableMint();
  error MaxBatchExceeded();
  error InvalidCharacter();
  error InsufficientPayment();
  error InvalidPermissions();
  error NotEnoughSupply();

}