// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./utils/ERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
                                                                    
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension and Enumerable extension.
*/
contract LovelessCityMetropass is Context, VRFConsumerBase, ERC721Enumerable, Ownable, ReentrancyGuard  {
  using Strings for uint256;
  using ECDSA for bytes32;

  /// Provenance hash
  string public PROVENANCE_HASH;

  /// Base URI
  string private _metropassBaseURI;

  /// Starting Index
  uint256 public startingIndex;

  /// Max number of NFTs and restrictions per wallet
  uint256 public constant MAX_SUPPLY = 3333;
  uint256 public constant TEAM_TOKENS = 66;
  uint256 private _maxPerWallet;
  uint256 public tokenPrice;

  /// Sale settings
  bool public saleIsActive;
  bool public metadataFinalised;
  bool public revealed;
  bool public whitelistOnly;
  bool private startingIndexSet;

  /// Address to validate WL
  address public signerAddress;
  address public constant TEAM_WALLET = 0xf71a729fd5C58Fa1096CcE576690d0cd4dEB4eb8;

  /// Royalty info
  address public royaltyAddress;
  uint256 private ROYALTY_SIZE = 1000;
  uint256 private ROYALTY_DENOMINATOR = 10000;
  mapping(uint256 => address) private _royaltyReceivers;

  /// Stores the number of minted tokens by user
  mapping(address => uint256) public _mintedByAddress;

  /// VRF chainlink
  bytes32 internal keyHash;
  uint256 internal fee;

  /// Contract Events
  event TokensMinted(address indexed mintedBy,uint256 indexed tokensNumber);
  event StartingIndexFinalized(uint256 indexed startingIndex);
  event BaseUriUpdated(string oldBaseUri,string newBaseUri);

  constructor(address _royaltyAddress, address _signer, string memory _baseURI)
  ERC721("Loveless City Metropass", "$LOVE")
  VRFConsumerBase(
    0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
    0x514910771AF9Ca656af840dff83E8264EcF986CA // LINK Token
  )
  {
    royaltyAddress = _royaltyAddress;
    signerAddress = _signer;

    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    fee = 2 * 10 ** 18;

    _metropassBaseURI = _baseURI;

    _maxPerWallet = 1;
    tokenPrice = 0.1111 ether;
    whitelistOnly = true;
  }

  /// Public function to purchase $LOVE tokens
  function purchase(uint256 tokensNumber, bytes calldata signature) public payable {
    require(tokensNumber > 0, "Wrong amount requested");
    require(totalSupply() + tokensNumber <= MAX_SUPPLY, "You tried to mint more than the max allowed");

    if (_msgSender() != owner()) {
      require(saleIsActive, "The mint is not active");
      require(_mintedByAddress[_msgSender()] + tokensNumber <= _maxPerWallet, "You have hit the max tokens per wallet");
      require(tokensNumber * tokenPrice == msg.value, "You have not sent enough ETH");
      _mintedByAddress[_msgSender()] += tokensNumber;
    }

    if (whitelistOnly && _msgSender() != owner()) {
      require(_validateSignature(signature, _msgSender()), "Your wallet is not whitelisted");
    }

    for(uint256 i = 0; i < tokensNumber; i++) {
      _safeMint(_msgSender(), totalSupply());
    }
    emit TokensMinted(_msgSender(), tokensNumber);
  }

  /// Public function to validate whether user witelisted agains contract
  function checkIfWhitelisted(bytes calldata signature, address caller) public view returns (bool) {
      return (_validateSignature(signature, caller));
  }

  /// Internal function to validate whether user witelisted
  function _validateSignature(bytes calldata signature, address caller) internal view returns (bool) {
    bytes32 dataHash = keccak256(abi.encodePacked(caller));
    bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

    address receivedAddress = ECDSA.recover(message, signature);
    return (receivedAddress != address(0) && receivedAddress == signerAddress);
  }

  /// EIP-2981: NFT Royalty Standard
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    uint256 amount = _salePrice * ROYALTY_SIZE / ROYALTY_DENOMINATOR;
    address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0) ? _royaltyReceivers[_tokenId] : royaltyAddress;
    return (royaltyReceiver, amount);
  }

  /// EIP-2981: NFT Royalty Standard
  function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId) public onlyOwner {
    _royaltyReceivers[tokenId] = receiver;
  }

  /// EIP-2981: NFT Royalty Standard
  function updateSaleStatus(bool status) public onlyOwner {
    saleIsActive = status;
  }

  /// Callback function used by VRF Coordinator
  function fulfillRandomness(bytes32, uint256 randomness) internal override {
      startingIndex = (randomness % MAX_SUPPLY);
      startingIndexSet = true;
      emit StartingIndexFinalized(startingIndex);
  }
  /// Public function that returns token URI
  function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if (!revealed) return _metropassBaseURI;
    return string(abi.encodePacked(_metropassBaseURI, tokenId.toString(), ".json"));
  }

  /*
  * ADMIN FUNCTIONS
  */
  
  /// Function to mint 66 tokens for the team
  function teamMint() public onlyOwner {
    require(totalSupply() + TEAM_TOKENS <= MAX_SUPPLY, "You tried to mint more than the max allowed");

     for(uint256 i = 0; i < TEAM_TOKENS; i++) {
      _safeMint(TEAM_WALLET, totalSupply());
    }
    emit TokensMinted(TEAM_WALLET, TEAM_TOKENS);
  }

  /// Updates token sale price
  function updateTokenPrice(uint256 _newPrice) public onlyOwner {
    require(!saleIsActive, "Pause sale before price update");
    tokenPrice = _newPrice;
  }

  /// Sets provenance hash
  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    require(bytes(PROVENANCE_HASH).length == 0, "Provenance hash has already been set");
    PROVENANCE_HASH = provenanceHash;
  }

  /// Sets base URI
  function setBaseURI(string memory newBaseURI) public onlyOwner {
    require(!metadataFinalised, "Metadata already finalised");

    string memory currentURI = _metropassBaseURI;
    _metropassBaseURI = newBaseURI;
    emit BaseUriUpdated(currentURI, newBaseURI);
  }
  
  /// Finalises Starting Index for the collection
  function finalizeStartingIndex() public onlyOwner returns (bytes32 requestId) {
    require(!startingIndexSet, 'startingIndex already set');

    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
    return requestRandomness(keyHash, fee);
  }

  /// Freezes metadata, i.e. makes it impossible to change baseURI
  function finalizeMetadata() public onlyOwner {
    require(!metadataFinalised, "Metadata already finalised");
    metadataFinalised = true;
  }

  /// Reveals metadata, after calling returns not just baseURI, but baseURI + Token ID
  function revealMetadata() public onlyOwner {
    revealed = true;
  }

  /// Updates limit for mint per wallet (by deafult it's 1)
  function updateMaxToMint(uint256 _max) public onlyOwner {
    _maxPerWallet = _max;
  }

  /// Allows to switch between public sale and whitelist-only sale (by default whitelist-only)
  function triggerWhitelist(bool _whitelistOnly) public onlyOwner {
    whitelistOnly = _whitelistOnly;
  }

  /// Withdraws collected ether from the contract to the owner address
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}