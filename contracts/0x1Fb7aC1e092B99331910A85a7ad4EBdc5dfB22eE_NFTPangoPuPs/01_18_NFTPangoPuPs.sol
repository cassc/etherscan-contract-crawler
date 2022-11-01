// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NFTPangoPuPs contract
 * @dev Extends ERC721A Non-Fungible Token Standard basic implementation
 */
contract NFTPangoPuPs is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard{
  /*
    _   ______________   ____                          ____        ____      
   / | / / ____/_  __/  / __ \____ _____  ____ _____  / __ \__  __/ __ \_____
  /  |/ / /_    / /    / /_/ / __ `/ __ \/ __ `/ __ \/ /_/ / / / / /_/ / ___/
 / /|  / __/   / /    / ____/ /_/ / / / / /_/ / /_/ / ____/ /_/ / ____(__  ) 
/_/ |_/_/     /_/    /_/    \__,_/_/ /_/\__, /\____/_/    \__,_/_/   /____/  
                                       /____/                                
⠀⣀⠀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀Created by Phygital Gems
⠀⣿⡀⢻⣿⣿⣿⣿⣿⣶⠀⣤⣄⣀⠀⠀⠀1st Gemstone Community On The Blockchain
⠀⠛⠓⠀⢻⣿⡿⠋⣉⣀⣀⢘⣿⣿⣿⡇⢠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣾⣿⣿⣿⣿⠀⣾⣿⣿⣿⣿⡿⠟⠛⠧⠈⢿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣿⣿⣿⡿⠿⠄⠹⣿⣿⣿⡃⢰⣶⣶⣶⣦⣴⣿⣿⠇⣀⠀⠀⠀⠀⠀⠀⠀⠀     
⠀⣿⡏⢠⣴⣶⣦⣤⣼⣿⣿⡷⠄⠉⠉⣉⡉⠛⢿⡏⢰⣿⣦⡀⠀⠀⠀⠀⠀⠀
⠀⣿⡀⢿⣿⣿⣿⣿⣿⣿⠋⣠⣶⣧⡈⠛⠻⣷⣄⠁⠘⣿⣿⣷⡀⠀⠀⠀⠀⠀      
⠀⢉⠁⠘⢿⣿⣿⣿⣿⡇⢰⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠈⠛⢿⣷⡀⠀⠀⠀⠀
⠀⣿⣿⣷⣿⡿⠛⣉⡉⠁⢸⠃⠈⠙⠻⢿⣿⣿⣿⣷⣶⣾⣷⣄⠙⠳⠀⠀⠀⠀
⠀⣿⣿⣿⣿⡀⢾⣿⣿⡇⠘⠀⠀⠀⠀⠀⠈⠉⠛⠻⠿⣿⣿⣿⣿⣦⡀⠀⠀⠀
⠀⠿⠋⣉⣉⡁⠈⠻⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀
⠀⠀⣾⣿⣿⣿⣷⣶⣿⡏⢡⣤⣤⠀⢀⣤⣄⡐⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠙⢿⣿⣿⡿⠛⣉⣁⣀⣿⠃⠐⠛⠿⣿⣷⠀⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠈⠉⠃⠘⠿⠟⠛⠋⠀⠀⠀⠀⢹⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
                   ~~~~~~~~ Important Information ~~~~~~~~⠀
  1) NFT 2D PangoPuPs holders will maintain access to the Phygital Gems Community.

  2) The Terms and Conditions disclosure can be found at NFTPangoPuPs.com and/or
     linked on this smart contract as "TOSUri".
     
     By purchasing, transferring, selling or participating in any and all Phygital
     Gems digital and/or physical products and services you're agreeing to all 
     Phygital Gems Terms and Conditions.

  */
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  bytes32 public merkleRoot;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  string public TOSUri; //Terms of Service and Privacy Policy
  
  uint256 public cost; 
  uint256 public WLcost; 
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false; 
  bool public revealed = false;

  mapping(uint256 => bytes32) private pangoNames;
  mapping(bytes32 => bool) private namesUsed;
  bytes32 private defaultName;
  string private defaultPrefix;
  

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    address[] memory payeeAddrs, 
    uint256[] memory payeeShares_
  ) ERC721A(_tokenName, _tokenSymbol) PaymentSplitter(payeeAddrs,payeeShares_){
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
    defaultName = 0x0;
    setNameDefaultPrefix("PangoPup #");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!"); 
    require(_currentIndex  + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }
  modifier mintWhitelistPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= WLcost * _mintAmount, "Insufficient funds!");
    _;
  }

  modifier nameCompliance(uint256 _mintAmount, string[] calldata newNames) {
    require(_mintAmount == newNames.length, "Invalid amount of names given!");
    _;
  }
 
  /**
  * Mint NFT PangoPups during the whitelisted mint sale
  */
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof, string[] calldata newNames) public payable mintCompliance(_mintAmount) mintWhitelistPriceCompliance(_mintAmount) nameCompliance(_mintAmount, newNames) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
    
    setNames(_currentIndex, newNames);
    _safeMint(msg.sender, _mintAmount);

  }

  /**
  * Mint NFT PangoPups during the public mint sale
  */
  function mint(uint256 _mintAmount, string[] calldata newNames) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nameCompliance(_mintAmount, newNames){
    require(!paused, "The contract is paused!");

    setNames(_currentIndex, newNames);
    _safeMint(msg.sender, _mintAmount);

  }
  
  /**
  * Admin - Mint NFT PangoPups to specified addresses
  */
  function mintForAddresses(uint256[] calldata _mintAmounts , address[] calldata _receivers ) public onlyOwner {
    for (uint i=0; i<_receivers.length; i++) {
      _safeMint(_receivers[i], _mintAmounts[i]);
    }
  }

  /**
  * View all tokens that belong to a specified address
  */
  function walletOfOwner(address _owner) public view returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 0;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  /**
  * View a specified token's metadata link
  */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
  {
    require( _exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  /**
  * Admin - Set a specified page to be revealed
  */
  function setRevealed(bool _state) public onlyOwner {
    require(revealed != _state, "Can't set to the same state!");
    revealed = _state;
  }

  /**
  * Admin - Set cost for public sale minting
  */
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  /**
  * Admin - Set cost for whitelist sale minting
  */
  function setCostWL(uint256 _WLcost) public onlyOwner {
    WLcost = _WLcost;
  }

  /**
  * Admin - Set limit of NFTs able to be minted in a single transaction
  */
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  /**
  * Admin - Set hidden reveal metadata
  */
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  /**
  * Admin - Set metadata link
  */
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  /**
  * Admin - Set metadata link suffix
  */
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  /**
  * Admin - Set link to Terms of Service  
  */
  function setTOSUri(string memory _uri) public onlyOwner {
    TOSUri = _uri;
  }

  /**
  * Admin - Start/Pause public sale
  */
  function setPaused(bool _state) public onlyOwner {
    require(paused != _state, "Can't set to the same state!");
    paused = _state;
  }

  /**
  * Admin - Start/Pause whitelist sale
  */
  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    require(whitelistMintEnabled != _state, "Can't set to the same state!");
    whitelistMintEnabled = _state;
  }

  /**
  * Admin - Set which addresses are allowed to mint
  */
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  /**
  * Links NFTs to the metadata
  */
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
  
  /**
  * Names an NFT PangoPuP with a unique nickname 
  */
  function setName(uint256 id, string calldata newName) private {
    require(!namesUsed[stringToBytes32(newName)], "Name already in use!");
    pangoNames[id] = stringToBytes32(newName);
    namesUsed[stringToBytes32(newName)] = true;
  }

  /**
  * Sets nicknames for NFT PangoPups when they are minted
  */
  function setNames(uint256 startIndex, string[] calldata newNames) private {
    for (uint256 i=startIndex; i<(startIndex+newNames.length); i++) {
      if(stringToBytes32(newNames[i-startIndex]) != defaultName){
        setName(i,newNames[i-startIndex]);
      }
    }
  }
  
  /**
  * Admin - Set default name
  */
  function setNameDefaultPrefix(string memory newPrefix) public onlyOwner{
    defaultPrefix = newPrefix;
  }
  
  /**
  * Admin - Manually rename an NFT PangoPup
  */
  function setNameAdmin(uint256 id, string calldata newName) public onlyOwner {
    require( _exists(id), "Nonexistent token");
    require(!namesUsed[stringToBytes32(newName)], "Name already in use!");
    namesUsed[pangoNames[id]] = false;
    pangoNames[id] = stringToBytes32(newName);
    namesUsed[stringToBytes32(newName)] = true;
  }

  /**
  * Lookup the nickname for a NFT PangoPup by specifying a token ID
  */
  function getName(uint256 id) public view virtual returns (string memory) {
    require( _exists(id), "Nonexistent token");
    if(pangoNames[id] == defaultName){
      return string.concat(defaultPrefix, Strings.toString(id));
    }
    return bytes32ToString(pangoNames[id]);
  }
  
  /**
  * Check if a nickname for a NFT PangoPup has already been claimed
  */
  function checkNameUsed(string calldata name) public view virtual returns (bool) {
    return namesUsed[stringToBytes32(name)];
  }

  /**
  * Helper function to convert bytes32 datatype to string datatype
  */
  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    uint8 i = 0;
    while(i < 32 && _bytes32[i] != 0) {
        i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  /**
  * Helper function to convert string datatype to bytes32 datatype
  */
  function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
  }

}