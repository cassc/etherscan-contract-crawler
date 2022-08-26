// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./EIP712FileSignature.sol";

contract MrKavesMetaCollect is ERC721, ReentrancyGuard, Ownable, VRFConsumerBaseV2, EIP712FileSignature {
  using Counters for Counters.Counter;

  event HasMinted(uint256 _tokenId, bytes _signature, string _dataId);

  string public metadataServiceAccount;
  string private customBaseURI;
  string private customRevealedBaseURI;
  string private customContractURI;

  uint256 public MINT_PRICE;
  uint256 public MAX_SUPPLY;

  bool public saleIsActive;
  bool public isRevealed;

  PaymentSplitter private SPLITTER;

  uint64 s_subscriptionId;
  address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
  bytes32 s_keyHash = 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92;
  uint32 callbackGasLimit = 150000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  1;

  mapping(uint256 => string) requestIdForAttributeType;
  mapping(uint256 => uint256) requestIdForTokenId;
  mapping(string => string[]) attributesAllowed;
  mapping(string => mapping(string => uint256)) attributesTotals;
  mapping(string => mapping(string => uint256)) attributesAssigned;
  mapping(uint256 => mapping(string => string)) attributesForToken;
  mapping(uint256 => mapping(string => bool)) attributeExistsForToken;

  VRFCoordinatorV2Interface COORDINATOR;

  Counters.Counter private tokenCounter;

  mapping(address => uint256[]) tokensForOwner;
  mapping(uint256 => bytes) filesSignatureForToken;

  constructor (
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _customBaseURI,
    string memory _customRevealedBaseURI,
    string memory _contractURI,
    string memory _metadataServiceAccount,
    uint256 _mintPrice,
    address[] memory _payees,
    uint256[] memory _shares,
    uint64 _subscriptionId
   ) ERC721(_tokenName, _tokenSymbol) EIP712FileSignature() VRFConsumerBaseV2(vrfCoordinator) {
    customBaseURI = _customBaseURI;
    customContractURI = _contractURI;
    customRevealedBaseURI = _customRevealedBaseURI;
    metadataServiceAccount = _metadataServiceAccount;

    MAX_SUPPLY = 1;
    MINT_PRICE = _mintPrice;

    SPLITTER = new PaymentSplitter(_payees, _shares);

    saleIsActive = false;
    isRevealed = false;

    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = _subscriptionId;
  }

  /**
    * @dev Changes the current sales state
    */
  function flipSaleIsActive() external onlyOwner {
    saleIsActive = !saleIsActive;
  }

  /**
    * @dev Changes the current is revealed state
    */
  function flipIsRevealed() external onlyOwner {
    isRevealed = !isRevealed;
  }

  /**
    * @dev Updates the base uri
    * @param _count The total number of tokens that the contract can mint
    */
  function setMaxSupply(uint256 _count) public onlyOwner {
    MAX_SUPPLY = _count;
  }

  /**
    * @dev Sets the value needed to mint tokens
    * @param _price The cost to mint a token
    */
  function setMintPrice(uint256 _price) public onlyOwner {
    MINT_PRICE = _price;
  }

  /**
    * @dev Gets total number of existing tokens
    */
  function totalTokens() public view returns (uint256) {
    return tokenCounter.current();
  }

  /**
    * @dev Sets new token in mapping for new group
    */
  function setTokensForOwner() private {
    tokensForOwner[msg.sender].push(totalTokens());
  }

  /**
    * @dev Gets total number of existing tokens
    * @param _owner Wallet address for owner
    */
  function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
    return tokensForOwner[_owner];
  }

  /**
    * @dev Sets the file signature for a new token
    * @param _signature Off chain web3 wallet signature approving the attached files checksums
    */
  function setFilesSignatureForToken(bytes calldata _signature) private {
    filesSignatureForToken[totalTokens()] = _signature;
  }

  /**
    * @dev Adds new token attribtues and assigns all indexing values
    * @param _attributeType Type of attribute being added
    * @param _attributeName Identifier used to track attribute assignments
    * @param _count Total number of tokens allowed to have the new attribute
    */
  function setAttribute(string memory _attributeType, string memory _attributeName, uint256 _count) public onlyOwner {
    attributesAllowed[_attributeType].push(_attributeName);
    attributesAssigned[_attributeType][_attributeName] = 0;
    attributesTotals[_attributeType][_attributeName] = _count;
  }

  /**
    * @dev Gets total number of existing tokens
    * @param _attributeType Type of attribute being added
    * @param _attributeName Identifier used to track attribute assignments
    */
  function attributesTotalsForType(string memory _attributeType, string memory _attributeName) public view returns (uint256) {
    require(isRevealed, "Attributes not revealed");

    return attributesTotals[_attributeType][_attributeName];
  }

  /**
    * @dev Gets total number of existing tokens
    * @param _attributeType Type of attribute being added
    */
  function attributesAllowedForType(string memory _attributeType) public view returns (string[] memory) {
    require(isRevealed, "Attributes not revealed");

    return attributesAllowed[_attributeType];
  }

  /**
    * @dev Gets total number of existing tokens
    * @param _tokenId Unique token identifier
    * @param _attributeType Type of attribute being added
    */
  function attributeForToken(uint256 _tokenId, string memory _attributeType) public view returns (string memory) {
    require(isRevealed, "Attributes not revealed");

    return attributesForToken[_tokenId][_attributeType];
  }

  /**
    * @dev Sets the file signature for a new token
    * @param requestId Chainlink VRF request identifer
    * @param randomWords Chainlink VRF subscription words
    */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    string memory attributeType = requestIdForAttributeType[requestId];
    uint256 tokenId = requestIdForTokenId[requestId];
    getRandomAttribute(randomWords[0], attributeType, tokenId, 0);
  }

  /**
    * @dev Gets random attribute if it is available
    * @param _randomWord Chainlink VRF subscription words
    * @param _attributeType Type of the attribute to randomly assign
    * @param _tokenId Unique token identifier
    * @param _i Incrementing recursive counter
    */
  function getRandomAttribute(uint256 _randomWord, string memory _attributeType, uint256 _tokenId, uint256 _i) private {
    require(attributesAllowed[_attributeType].length > 0, "Attribute does not exist");

    uint256 randomIndex = (uint256(keccak256(abi.encode(_randomWord, _i))) % attributesAllowed[_attributeType].length);
    string memory randomName = attributesAllowed[_attributeType][randomIndex];

    if (attributesAssigned[_attributeType][randomName] < attributesTotals[_attributeType][randomName]) {
      attributesForToken[_tokenId][_attributeType] = randomName;
      attributeExistsForToken[_tokenId][_attributeType] = true;
      attributesAssigned[_attributeType][randomName] += 1;
    }
    else {
      getRandomAttribute(_randomWord, _attributeType, _tokenId, _i + 1);
    }
  }

  /**
    * @dev Get the random word for randomly select a single attribute 
    * @param _attributeType Type of the attribute to randomly assign
    * @param _tokenId Unique token identifier
    */
  function requestRandomWordForAttribute(string memory _attributeType, uint256 _tokenId) external onlyOwner {
    require(totalTokens() > _tokenId, "Token does not exist");
    require(!attributeExistsForToken[_tokenId][_attributeType], "Token already has an assigned attribute for this type");

    uint256 requestId = COORDINATOR.requestRandomWords(
      s_keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    requestIdForAttributeType[requestId] = _attributeType;
    requestIdForTokenId[requestId] = _tokenId;
  }

  /**
    * @dev Mints a new token into a new group. Can only be called by approved onboarded user
    * @param _signingName The token or asset name
    * @param _signingMetadataHash The Sha3 hash of the metadata object
    * @param _signingDataId The reference id that is used for metadata reference and physical asset verification
    * @param _signature Off chain web3 wallet signature approving the attached files checksums
    */
  function mint(string memory _signingName, string memory _signingMetadataHash, string memory _signingDataId, bytes calldata _signature) public payable nonReentrant verifyFileSignature(_signature, msg.sender, _signingName, _signingMetadataHash, _signingDataId) {
    require(saleIsActive, "Sale not active");
    require(msg.value >= MINT_PRICE, "Insufficient payment");
    require(totalTokens() < MAX_SUPPLY, "Exceeds max supply");

    setTokensForOwner();
    setFilesSignatureForToken(_signature);

    _safeMint(msg.sender, totalTokens());

    payable(SPLITTER).transfer(msg.value);

    emit HasMinted(totalTokens(), _signature, _signingDataId);

    tokenCounter.increment();
  }

  /**
    * @dev Gets the token uri and appends .json
    * @param _tokenId Unique token identifier
    */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), "URI query for nonexistent token");
      string memory baseURI = _baseURI();
      string memory tokenURI_ = super.tokenURI(_tokenId);

      return bytes(baseURI).length > 0
          ? string(abi.encodePacked(tokenURI_, '.json'))
          : '';
  }

  /**
    * @dev Sets the custom contract metadata
    * @param contractURI_ File path under base URI without the .json file extension
    */
  function setContractURI(string memory contractURI_) external onlyOwner {
    customContractURI = contractURI_;
  }

  /**
    * @dev Gets the contract uri and appends .json
    */
  function contractURI() public view virtual returns (string memory) {
    string memory baseURI = _baseURI();

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, customContractURI, '.json')) : '';
  }

  /**
    * @dev Gets the base uri for metadata storage
    */
  function baseTokenURI() public view returns (string memory) {
    return isRevealed ? customRevealedBaseURI : customBaseURI;
  }

  /**
    * @dev Updates the base uri
    * @param _customBaseURI The uri that is prefixed for all token ids
    */
  function setBaseURI(string memory _customBaseURI) external onlyOwner {
    customBaseURI = _customBaseURI;
  }

  /**
    * @dev Updates the base uri
    * @param _customRevealedBaseURI The uri that is prefixed for all token ids
    */
  function setRevealedBaseURI(string memory _customRevealedBaseURI) external onlyOwner {
    customRevealedBaseURI = _customRevealedBaseURI;
  }

  /**
    * @dev Gets the base uri for metadata storage
    */
  function _baseURI() internal view virtual override returns (string memory) {
    return isRevealed ? customRevealedBaseURI : customBaseURI;
  }

  /**
    * @dev Gets the wallet signature for a token's attached files
    * @param _signingName The token or asset name
    * @param _signingMetadataHash The Sha3 hash of the metadata object
    * @param _signingDataId The reference id that is used for metadata reference and physical asset verification
    * @param _signature Unique token identifier
    */
  function verifyTokenFileSigner(string memory _signingName, string memory _signingMetadataHash, string memory _signingDataId, bytes calldata _signature) public view verifyFileSignature(_signature, msg.sender, _signingName, _signingMetadataHash, _signingDataId) returns (bool) {
    return true;
  }

  /**
    * @dev Sends distribution to a shareholder wallet
    * @param account The wallet to payout their owned shares
    */
  function release(address payable account) public virtual onlyOwner {
    SPLITTER.release(account);
  }
}