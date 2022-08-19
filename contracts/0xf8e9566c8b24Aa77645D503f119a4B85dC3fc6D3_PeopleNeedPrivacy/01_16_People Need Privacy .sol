// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract PeopleNeedPrivacy is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  string private _baseTokenURI;
  string private _defaultTokenURI;
  uint256 public constant MAX_SUPPLY = 5022;
  uint256 public constant WHITELIST_DELEY = 1 hours;
  uint256 public constant PUBLIC_DELAY = 2 hours;
  uint256 public constant OG_MINT_MAX_QUANTITY = 25;
  uint256 public constant CONTRIBUTE_MINT_MAX_QUANTITY = 2;
  uint256 public constant MINT_MAX_QUANTITY = 1;
  address public constant TS_ADDRESS = 0x458D4e2C959A7A5dF88304Df396078E3BE038748;
  address public constant TEAM_ADDRESS = 0x5793083B30Ca639b924126CdF0EC96219d8a056E;
  bytes32 public ogRoot;
  bytes32 public contributeRoot;
  bytes32 public whiteListRoot;
  uint256 public OG_STARTING_AT;
  uint256 public WHITELIST_STARTING_AT;
  uint256 public PUBLIC_STARTING_AT;
  
  mapping(address => uint256) public minted;

  constructor(string memory URI) ERC721A("People Need Privacy", "PNP") {
    _safeMint(TS_ADDRESS, 500);
    _safeMint(TEAM_ADDRESS, 300);
    _baseTokenURI = URI;
    OG_STARTING_AT = 1660858200;
    WHITELIST_STARTING_AT = OG_STARTING_AT + WHITELIST_DELEY;
    PUBLIC_STARTING_AT = OG_STARTING_AT + PUBLIC_DELAY;
  }

  function setOgRoot(bytes32 merkleroot) external onlyOwner {
    ogRoot = merkleroot;
  }

  function setContributeRoot(bytes32 merkleroot) external onlyOwner {
    contributeRoot = merkleroot;
  }

  function setWhiteListRoot(bytes32 merkleroot) external onlyOwner {
    whiteListRoot = merkleroot;
  }

  function ogMint(address to, bytes32[] calldata proof) external nonReentrant{
    require(OG_STARTING_AT <= block.timestamp, "Ogmint not ready");
    require(minted[to] < OG_MINT_MAX_QUANTITY, "Already minted");
    require(totalSupply() + OG_MINT_MAX_QUANTITY <= MAX_SUPPLY, "Exceed alloc");
    bytes32 leaf = keccak256(abi.encodePacked(to));
    bool isValidLeaf = MerkleProof.verify(proof, ogRoot, leaf);
    require(isValidLeaf == true, "Not in merkle");
    minted[to] = OG_MINT_MAX_QUANTITY;
    _safeMint(to, OG_MINT_MAX_QUANTITY);
  }

  function contributeMint( address to, bytes32[] calldata proof) external nonReentrant{
    require(OG_STARTING_AT <= block.timestamp, "Contribute not ready");
    require(minted[to] < CONTRIBUTE_MINT_MAX_QUANTITY, "Already minted");
    require(totalSupply() + CONTRIBUTE_MINT_MAX_QUANTITY <= MAX_SUPPLY, "Exceed alloc");
    bytes32 leaf = keccak256(abi.encodePacked(to));
    bool isValidLeaf = MerkleProof.verify(proof, contributeRoot, leaf);
    require(isValidLeaf == true, "Not in merkle");
    minted[to] = CONTRIBUTE_MINT_MAX_QUANTITY;
    _safeMint(to, CONTRIBUTE_MINT_MAX_QUANTITY);
  }

  function whitelistMint( address to, bytes32[] calldata proof) external nonReentrant{
    require(WHITELIST_STARTING_AT <= block.timestamp, "Whitelist not ready");
    require(minted[to] < MINT_MAX_QUANTITY, "Already minted");
    require(totalSupply() + MINT_MAX_QUANTITY <= MAX_SUPPLY, "Exceed alloc");
    bytes32 leaf = keccak256(abi.encodePacked(to));
    bool isValidLeaf = MerkleProof.verify(proof, whiteListRoot, leaf);
    require(isValidLeaf == true, "Not in merkle");
    minted[to] = MINT_MAX_QUANTITY;
    _safeMint(to, MINT_MAX_QUANTITY);
  }

  function publicMint( address to) external nonReentrant{
    require(PUBLIC_STARTING_AT <= block.timestamp, "Public sale haven't start");
    require(totalSupply() + MINT_MAX_QUANTITY <= MAX_SUPPLY, "Exceed alloc");
    require(minted[to] < MINT_MAX_QUANTITY, "Already minted");
    minted[to] = MINT_MAX_QUANTITY;
    _safeMint(to, MINT_MAX_QUANTITY);
  }

  function setPresaleMint(uint256 presaleTime) external onlyOwner{
    OG_STARTING_AT = presaleTime;
    WHITELIST_STARTING_AT = OG_STARTING_AT + WHITELIST_DELEY;
    PUBLIC_STARTING_AT = OG_STARTING_AT + PUBLIC_DELAY;
  }

  function setBaseURI(string calldata URI) external onlyOwner {
    _baseTokenURI = URI;
  }

  function setDefaultTokenURI(string calldata URI) external onlyOwner {
    _defaultTokenURI = URI;
  }

  function baseURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId) public override view returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory _baseURI = baseURI();
    return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : _defaultTokenURI;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }



}