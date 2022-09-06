// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract OasisNFT is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  uint256 public withdrawPool;
  uint256 public refundPool;
  uint256 public revenuePool;

  uint public refundEndTime;
  uint public firstMintTime;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }


  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    withdrawPool = withdrawPool + msg.value * 7 / 10;
    refundPool = refundPool +  msg.value * 3 / 10;
    _safeMint(_msgSender(), _mintAmount);
    if (firstMintTime == 0) {
      firstMintTime = block.timestamp;
      //add 2 year
      refundEndTime = block.timestamp + 93312000; 
    }
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    withdrawPool = withdrawPool + msg.value * 7 / 10;
    refundPool = refundPool +  msg.value * 3 / 10;
    _safeMint(_msgSender(), _mintAmount);
    if (firstMintTime == 0) {
      firstMintTime = block.timestamp;
      //add 2 year
      refundEndTime = block.timestamp + 93312000; 
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function addRevenue() public payable {
    revenuePool = revenuePool + msg.value;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setRefundTime(uint256 _refundTime) public onlyOwner {
    require(_refundTime > refundEndTime,"new refund time should be later than orgin");
    refundEndTime = _refundTime;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    if (block.timestamp < refundEndTime) {
      (bool os, ) = payable(owner()).call{value: withdrawPool}('');
      withdrawPool = 0;
      require(os);
    } else {
      (bool os, ) = payable(owner()).call{value: address(this).balance}('');
      withdrawPool = 0;
      refundPool = 0;
      revenuePool = 0;
      require(os);
    }
  
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }


  function refund(uint256[] calldata tokenIds)  external {
     require(block.timestamp <= refundEndTime, "Refund expired");
     require(tokenIds.length > 0, "must input token id");

     for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "Not token owner");
      }

      
      uint256 _refundBase = refundPool / totalSupply() * tokenIds.length;
      uint256 _refundRevenue = revenuePool / totalSupply() * tokenIds.length;

      if (block.timestamp > firstMintTime + 31104000) {
        //after 1 year
        _refundRevenue = _refundRevenue * 1;
      } else if (block.timestamp > firstMintTime + 23328000) {
        //after 9 month
        _refundRevenue = _refundRevenue * 75 / 100;
      } else if (block.timestamp > firstMintTime + 15552000) {
        //after 6 month
        _refundRevenue = _refundRevenue * 50 / 100;
      } else if (block.timestamp > firstMintTime + 7776000) {
        //after 3 month
        _refundRevenue = _refundRevenue * 25 / 100;
      } else if (block.timestamp > firstMintTime + 2592000) {
        //after 1 month
        _refundRevenue = _refundRevenue * 10 / 100;
      } else {
        _refundRevenue = 0;
      }

      refundPool = refundPool - _refundBase;
      revenuePool = revenuePool - _refundRevenue;

      
      for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
      }

      Address.sendValue(payable(msg.sender), _refundBase+_refundRevenue);
  } 
}