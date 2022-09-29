// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.9 < 0.9.0;
// MOON WOLVES 4.20
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract MoonWolves420 is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

    mapping(address => uint256) public WalletMint;
  string public baseURI = "ipfs://Qma4rowLPYmrjrcz7g1FqxMPjeCdBJAAea6Hm9XKhQoi3X/";
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public freeMaxSupply;
  uint256 public maxMintAmountPerTx = 5;
  bool public freeMintpaused = true;
  bool public paused = true;
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = 0.0042 ether;
    freeMaxSupply = 420;
    maxSupply = 1420;
  }

  modifier checkMint(uint256 _mintAmount) {
    require(WalletMint[msg.sender] <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }
  function mintFree(uint256 _mintAmount) public payable checkMint(_mintAmount){
    require(!freeMintpaused, 'The contract is paused!');
    require(totalSupply() + _mintAmount <= freeMaxSupply, "Mint supply exceeded!");
    WalletMint[msg.sender] += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }
  function mint(uint256 _mintAmount) public payable checkMint(_mintAmount){
    require(!paused, 'The contract is paused!');
    require(msg.value >= _mintAmount * cost, "Notice: Fund not enough");
    WalletMint[msg.sender] += _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }


  function _startTokenId() internal view virtual override returns(uint256) {
    return 1;
  }
  function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), '.json'))
      : '';
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }


  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setFreeMintPaused(bool _state) public onlyOwner {
    freeMintpaused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{ value: address(this).balance } ('');
    require(os);
  }
  function _baseURI() internal view virtual override returns(string memory) {
    return baseURI;
  }
}