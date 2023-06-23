// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EnterTheVoid is ERC721A, Ownable, ReentrancyGuard {

  // CONSTANTS
  uint256 public wlPrice = 0.02 ether;
  uint256 public publicPrice = 0.02 ether;
  uint256 public maxSupply = 555;
  uint256 public maxPerWallet = 1;

  enum MintingState {
    INACTIVE,
    WLSALE,
    PUBLICSALE   
  }

  MintingState private MINTING_STATE = MintingState.INACTIVE;
  
  bool public revealed = false;
  string private baseURI = "";
  
  bytes32 wlRoot;

  address public constant DEV_ADDRESS = 0x89b17117f85d379fdd4Fb98Ca186AF5FBFc3Dd74;
  address public constant ARTIST_ADDRESS = 0x6369d8AcbFEfd7cC223D1C3D439c9a7fdEDDc9Ee; 
  address public constant TEAM_ADDRESS = 0xc0d1a5AcD43Ed70623c05CAB45C313c10E4D95B6; 


  constructor() ERC721A("Enter the void", "ETV") {
    _mint(msg.sender, 1);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(tx.origin == msg.sender,"ETV: CONTRACT_NOT_ALLOWED");
    require(_mintAmount > 0, "ETV: MINT_AMOUNT_INCORRECT");
    require(_numberMinted(_msgSender()) + _mintAmount <= maxPerWallet, "ETV: MAX_PER_WALLET_LIMIT");
    require(totalSupply() + _mintAmount <= maxSupply, "ETV: MAX_SUPPLY_LIMIT");
    _;
  }

  function wlMint(bytes32[] memory proof, uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
    require(MINTING_STATE == MintingState.WLSALE, "ETV: WL_MINT_INACTIVE");
    require(MerkleProof.verify(proof, wlRoot, keccak256(abi.encodePacked(msg.sender))), "ETV: NOT_WHITELISTED");
    require(msg.value >= wlPrice * _mintAmount, "ETV: NOT_ENOUGH_ETH");
    _safeMint(msg.sender, _mintAmount);
  }

  function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
    require(MINTING_STATE == MintingState.PUBLICSALE, "ETV: PUBLIC_MINT_INACTIVE");
    require(msg.value >= publicPrice * _mintAmount, "ETV: NOT_ENOUGH_ETH");
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _to) external onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "ETV: MAX_SUPPLY_LIMIT");
    _mint(_to, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed) {
      return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    } else {
      return string(abi.encodePacked(baseURI));
    }
  }
 
   // OWNER ONLY FUNCTIONS
  function setWLSaleRoot(bytes32 _wlRoot) external onlyOwner {
    wlRoot = _wlRoot;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setPublicPrice(uint256 _price) external onlyOwner {
    publicPrice = _price;
  }

  function setWlPrice(uint256 _price) external onlyOwner {
    wlPrice = _price;
  }

  function getWlMintPrice() public view returns (uint256) {
    return wlPrice;
  }

  function getPublicPrice() public view returns (uint256) {
    return publicPrice;
  }
  
  function turnPublicLive() external onlyOwner {
    MINTING_STATE = MintingState.PUBLICSALE;
  }

  function turnWlLive() external onlyOwner {
    MINTING_STATE = MintingState.WLSALE;
  }

  function pauseMint() external onlyOwner {
    MINTING_STATE = MintingState.INACTIVE;
  }

  function getMintingState() public view returns (MintingState) {
    return MINTING_STATE;
  }

  function setBaseURI(string calldata URI) external onlyOwner {
    baseURI = URI;
  }

  function reveal(bool _revealed, string calldata _uri) external onlyOwner {
    revealed = _revealed;
    baseURI = _uri;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "ETV: NOTHING_TO_WITHDRAW");
    uint256 acc_art = (balance * 333) / 1000;
    uint256 acc_team = (balance * 333) / 1000;
    payable(ARTIST_ADDRESS).transfer(acc_art);
    payable(TEAM_ADDRESS).transfer(acc_team);
    payable(DEV_ADDRESS).transfer(address(this).balance);
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}