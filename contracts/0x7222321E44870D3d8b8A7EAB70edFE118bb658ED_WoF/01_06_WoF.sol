//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract WoF is ERC721A, Ownable {
  // events
  event WhitelistMint(address sender, uint256 count);
  event Mint(address sender, uint256 count);
  event SetMerkleRoot(bytes32 merkleRoot);
  event SetBaseURI(string baseURI);
  event SetPrice(uint256 price);
  event Pause();
  event Unpause();
  event ToggleSale(bool saleIsOpen);
  event Withdraw(uint256 balance);
  event SetMaxPerMint(uint256 maxPerMint);

  string public _baseTokenURI;

  bool public saleIsOpen;
  bool public paused;
  uint256 public _price = 0;
  uint256 public maxPerMint = 1;
  uint256 public reservedCount = 8000;
  bytes32 public merkleRoot;
  mapping(address => uint256) public whitelistClaimed;

  uint256 public constant START_TOKEN_ID = 1;
  uint256 public constant MAX_SUPPLY = 10000; // max supply 10,000

  modifier notPaused() {
    if (_msgSender() != owner()) {
      require(!paused, 'Pausable: paused');
    }
    _;
  }

  modifier onlySaleOpen() {
    require(saleIsOpen, 'Public sale is not started yet');

    _;
  }

  modifier onlyWhitelistedUser(bytes32[] calldata _merkleProof) {
    address _caller = _msgSender();
    bytes32 leaf = keccak256(abi.encodePacked(_caller));

    require(whitelistClaimed[_caller] < maxPerMint + 1, 'Address has already claimed');
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof');
    _;
  }

  constructor(string memory baseTokenURI_)
    ERC721A('OneCool Collective: Warriors of Future', 'WOF')
  {
    _baseTokenURI = baseTokenURI_;
    merkleRoot = 0xc18741ab4c567250f3d28a2c77b4b8a0415db7546da20b8a07a1260f40d1e77b;
    address reserved = 0xf0D53D6917776E5d14fdFa2AC22062744Fee1773;

    _safeMint(reserved, reservedCount);

    emit Mint(reserved, reservedCount);
    emit SetMerkleRoot(merkleRoot);
  }

  function mint(uint256 _count) external payable onlySaleOpen notPaused {
    address _caller = _msgSender();

    require(balanceOf(_caller) + _count < maxPerMint + 1, 'You are not allowed to mint this many!');

    _mint(_count);

    emit Mint(_msgSender(), _count);
  }

  function whitelistMint(uint256 _count, bytes32[] calldata _merkleProof)
    external
    payable
    notPaused
    onlyWhitelistedUser(_merkleProof)
  {
    address _caller = _msgSender();

    require(whitelistClaimed[_caller] + _count < maxPerMint + 1, 'Address has already claimed');

    _mint(_count);

    whitelistClaimed[_caller] += _count;

    emit WhitelistMint(_msgSender(), _count);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    emit SetMerkleRoot(_merkleRoot);

    merkleRoot = _merkleRoot;
  }

  function price(uint256 _count) public view returns (uint256) {
    return _price * _count;
  }

  function setPrice(uint256 updatedPrice) external onlyOwner {
    _price = updatedPrice;

    emit SetPrice(updatedPrice);
  }

  function setMaxPerMint(uint256 updatedMaxPerMint) external onlyOwner {
    maxPerMint = updatedMaxPerMint;

    emit SetMaxPerMint(updatedMaxPerMint);
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;

    emit SetBaseURI(baseURI);
  }

  // https://docs.opensea.io/docs/1-structuring-your-smart-contract#creature-erc721-contract
  function baseTokenURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function pause() public onlyOwner {
    paused = true;

    emit Pause();
  }

  function unpause() public onlyOwner {
    paused = false;

    emit Unpause();
  }

  function enablePublicSale() external onlyOwner {
    saleIsOpen = true;
    _price = 0.18 ether;
    maxPerMint = 5;

    emit SetPrice(_price);
    emit SetMaxPerMint(maxPerMint);
    emit ToggleSale(saleIsOpen);
  }

  function enablePrivateSale() external onlyOwner {
    saleIsOpen = false;
    _price = 0.15 ether;
    maxPerMint = 3;
    merkleRoot = 0x36e12b264e5424d617337da6a9b6e10d74901af8e8b7be3ee206a285944d7860;

    emit ToggleSale(saleIsOpen);
    emit SetPrice(_price);
    emit SetMaxPerMint(maxPerMint);
    emit SetMerkleRoot(merkleRoot);
  }

  // widthdraw fund from the contract
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;

    require(balance > 0, 'Balance is 0');

    (bool sent, ) = payable(owner()).call{ value: balance }('');

    require(sent, 'Failed to send Ether');

    emit Withdraw(balance);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return START_TOKEN_ID;
  }

  function _mint(uint256 _count) private {
    address _caller = _msgSender();
    uint256 maxItemId = MAX_SUPPLY + START_TOKEN_ID;
    uint256 currentIndex = _nextTokenId();

    require(currentIndex + _count < maxItemId + 1, 'Exceeds max supply');
    require(msg.value >= price(_count), 'Value below price');
    require(_count > 0, 'No 0 mints');
    require(tx.origin == _caller, 'No contracts');

    _safeMint(_caller, _count);
  }
}