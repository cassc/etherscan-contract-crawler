// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract goblinCats is ERC721A, Ownable, ReentrancyGuard {


  bytes32 public merkleRoot;
  mapping(address => bool) public freePublicMinted;
  mapping(address => uint) public freeWLMinted;


  string private _baseTokenURI;
  uint public wlMax = 2;
  uint public price = 0.005 ether;
  uint public maxSupply = 6969;
  uint public maxMintAmountPerTx = 3;

  bool public publicPaused = true;
  bool public whitelistMintEnabled = false;


  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {}


  modifier mintRequirements(uint256 _mintAmount) {
    require(tx.origin == msg.sender, "Goblin Cats do not like bots...");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external mintRequirements(_mintAmount) {
    require(whitelistMintEnabled, "The whitelist sale is not live!");
    require(freeWLMinted[_msgSender()] + _mintAmount <= wlMax, "You can't mint that much");
    require(_mintAmount > 0 && _mintAmount <= wlMax, "Invalid mint amount for WL!");

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    freeWLMinted[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);

  }

  function mint(uint256 _mintAmount) external payable mintRequirements(_mintAmount) {
    require(!publicPaused, "The public sale is paused!");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");

    if (freePublicMinted[_msgSender()]) {
        require(msg.value >= price * _mintAmount, "Insufficient funds!");
    } else{
        require(msg.value >= (price * _mintAmount) - price, "Insufficient funds!");
        freePublicMinted[_msgSender()] = true;
    }

    _safeMint(_msgSender(), _mintAmount);

  }

  
  function mintTo(uint256 _mintAmount, address _receiver) external onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function changeSupply(uint256 _maxSupply) public onlyOwner {
    require((maxSupply - _maxSupply) > 0, "No needed");
    maxSupply = _maxSupply;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setPausedForPublicSale(bool _state) external onlyOwner {
    publicPaused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) external onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdrawFunds() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Failed to withdraw payment");
  }

  function devMint() external onlyOwner {
    require(totalSupply() == 0, "NFT alredy minted!");
    _safeMint(msg.sender, 100);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}