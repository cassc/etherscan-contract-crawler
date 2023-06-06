// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./utils/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
                                                                    
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension and Enumerable extension.
*/
contract AbnormalJean is Context, ERC721Enumerable, Ownable, ReentrancyGuard  {
  using Strings for uint256;
  using ECDSA for bytes32;

  // Base URI
  string private _jeanBaseURI;

  // Max number of NFTs and restrictions per wallet
  uint256 public constant MAX_SUPPLY = 8888;
  uint256 public constant RESERVED_TOKENS = 4444;
  uint256 public constant TEAM_TOKENS = 28;
  uint256 public maxPerWallet;
  uint256 public tokenPrice;

  // Sale settings
  bool public metadataFinalised;
  bool public revealed;

  // Address to validate WL
  address public signerAddress;
  address public constant TEAM_WALLET = 0xf71a729fd5C58Fa1096CcE576690d0cd4dEB4eb8;

  // Mint pass contracts
  IERC721 public MetroPass;
  IERC721 public Passport;

  // Royalty info
  address public royaltyAddress;
  uint256 private ROYALTY_SIZE = 1000;
  uint256 private ROYALTY_DENOMINATOR = 10000;
  mapping(uint256 => address) private _royaltyReceivers;

  // Stores the tokenIds used for minting JEAN
  mapping(address => mapping(uint256 => bool)) public mintPassUsed;
  uint256 public totalMintPassesUsed;

  // Stores the number of minted tokens by user
  mapping(address => uint256) public _mintedByAddress;

  enum Statuses {
    Inactive,
    Claim,
    Whitelist,
    Public
  }

  Statuses public currentStatus;

  // Contract Events
  event TokensMinted(address indexed mintedBy,uint256 indexed tokensNumber);
  event BaseUriUpdated(string oldBaseUri,string newBaseUri);
  event Claim(address indexed claimedBy,address mintPassAddress,uint256 tokenId);

  constructor(address _royaltyAddress, address _signer, string memory _baseURI)
  ERC721("Abnormal Jean", "JEAN")
  {
    royaltyAddress = _royaltyAddress;
    signerAddress = _signer;
    _jeanBaseURI = _baseURI;

    MetroPass = IERC721(0x8338D085aAe3aC048b9e1DE285fDef508CE73E45);
    Passport = IERC721(0xfB97f535d5bEF03599861929324ad019203aE617);

    currentStatus = Statuses.Inactive;

    maxPerWallet = 3;
    tokenPrice = 0.1666 ether;
  }


  function claim(
    uint256[] calldata metroPassIds,
    uint256[] calldata passportIds,
    uint256 paidTokensToMint
  ) public payable nonReentrant {
    require(currentStatus == Statuses.Claim || currentStatus == Statuses.Whitelist, "Sale is not active");
    require(metroPassIds.length > 0 || passportIds.length > 0, "Should provide at least one token ID to claim");
    require(paidTokensToMint <= metroPassIds.length + passportIds.length, "You can only mint one additional token per mintpass");

    if (metroPassIds.length > 0) {
      _mintForMintPass(metroPassIds, address(MetroPass));
    }
    if (passportIds.length > 0) {
      _mintForMintPass(passportIds, address(Passport));
    }

    if (paidTokensToMint > 0 && currentStatus == Statuses.Claim) {
      require(totalSupply() + paidTokensToMint <= MAX_SUPPLY - (RESERVED_TOKENS - totalMintPassesUsed), "Try to mint more than max allowed");
      require(msg.value == paidTokensToMint * tokenPrice, "Incorrect value provided");
      for (uint256 i; i < paidTokensToMint; i++) {
        _mint(_msgSender(), totalSupply());
      }
    }
  }

  // Public function to purchase JEAN tokens
  function purchase(uint256 tokensNumber, bytes calldata signature) public payable nonReentrant {
    require(tokensNumber > 0, "Wrong amount requested");
    require(currentStatus == Statuses.Whitelist || currentStatus == Statuses.Public, "Sale is not active");
    
    if (currentStatus == Statuses.Whitelist) {
      require(_validateSignature(signature, _msgSender()), "Your wallet is not whitelisted");
      require(totalSupply() + tokensNumber <= MAX_SUPPLY - (RESERVED_TOKENS - totalMintPassesUsed), "Try to mint more than max allowed");
    }
    if (currentStatus == Statuses.Public) {
      require(totalSupply() + tokensNumber <= MAX_SUPPLY, "You tried to mint more than the max allowed");
    }

    if (_msgSender() != owner()) {
      require(_mintedByAddress[_msgSender()] + tokensNumber <= maxPerWallet, "You have hit the max tokens per wallet");
      require(tokensNumber * tokenPrice == msg.value, "You have not sent enough ETH");
      _mintedByAddress[_msgSender()] += tokensNumber;
    }

    for(uint256 i = 0; i < tokensNumber; i++) {
      _safeMint(_msgSender(), totalSupply());
    }

    emit TokensMinted(_msgSender(), tokensNumber);
  }

  function _mintForMintPass (uint256[] calldata tokenIds, address mintPass) internal {
    for (uint256 i; i < tokenIds.length; i++) {
      require(IERC721(mintPass).ownerOf(tokenIds[i]) == _msgSender(), "Not the owner");
      require(!mintPassUsed[mintPass][tokenIds[i]], "Token has already been used");
      mintPassUsed[mintPass][tokenIds[i]] = true;
      totalMintPassesUsed++;
      _mint(_msgSender(), totalSupply());
      emit Claim(_msgSender(), mintPass, tokenIds[i]);
    }
  }

  // Public function to validate whether user witelisted agains contract
  function checkIfWhitelisted(bytes calldata signature, address caller) public view returns (bool) {
      return (_validateSignature(signature, caller));
  }

  // Internal function to validate whether user witelisted
  function _validateSignature(bytes calldata signature, address caller) internal view returns (bool) {
    bytes32 dataHash = keccak256(abi.encodePacked(caller));
    bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

    address receivedAddress = ECDSA.recover(message, signature);
    return (receivedAddress != address(0) && receivedAddress == signerAddress);
  }

  // EIP-2981: NFT Royalty Standard
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    uint256 amount = _salePrice * ROYALTY_SIZE / ROYALTY_DENOMINATOR;
    address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0) ? _royaltyReceivers[_tokenId] : royaltyAddress;
    return (royaltyReceiver, amount);
  }

  // EIP-2981: NFT Royalty Standard
  function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId) public onlyOwner {
    _royaltyReceivers[tokenId] = receiver;
  }

  /// Admin function to update sale status. 0 - Inactive, 1 - Claim, 2 - Whitelist, 3 - Public
  function updateSaleStatus(uint256 saleStatus) public onlyOwner {
    currentStatus = Statuses(saleStatus);
  }

  // Publc funcition that returns token URI
  function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if (!revealed) return _jeanBaseURI;
    return string(abi.encodePacked(_jeanBaseURI, tokenId.toString(), ".json"));
  }

  /*
  * ADMIN FUNCTIONS
  */

  // Function to mint 28 tokens for the team
  function teamMint() public onlyOwner {
    require(totalSupply() + TEAM_TOKENS <= MAX_SUPPLY, "You tried to mint more than the max allowed");

    for(uint256 i = 0; i < TEAM_TOKENS; i++) {
      _safeMint(TEAM_WALLET, totalSupply());
    }
    emit TokensMinted(TEAM_WALLET, TEAM_TOKENS);
  }
  
  // Updates token sale price
  function updateTokenPrice(uint256 _newPrice) public onlyOwner {
    require(currentStatus == Statuses.Inactive, "Pause sale before price update");
    tokenPrice = _newPrice;
  }

  // Sets base URI
  function setBaseURI(string memory newBaseURI) public onlyOwner {
    require(!metadataFinalised, "Metadata already finalised");

    string memory currentURI = _jeanBaseURI;
    _jeanBaseURI = newBaseURI;
    emit BaseUriUpdated(currentURI, newBaseURI);
  }

  // Freezes metadata, i.e. makes it impossible to change baseURI
  function finalizeMetadata() public onlyOwner {
    require(!metadataFinalised, "Metadata already finalised");
    metadataFinalised = true;
  }

  // Reveals metadata, after calling returns not just baseURI, but baseURI + Token ID
  function revealMetadata() public onlyOwner {
    revealed = true;
  }

  // Updates limit for mint per wallet (by deafult it's 1)
  function updateMaxToMint(uint256 _max) public onlyOwner {
    maxPerWallet = _max;
  }

  // Updates metropass address
  function setMetropassAddress(address _address) public onlyOwner {
    MetroPass = IERC721(_address);
  }
  
  // Updates passport address
  function setPassportAddress(address _address) public onlyOwner {
    Passport = IERC721(_address);
  }

  // Withdraws collected ether from the contract to the owner address
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}