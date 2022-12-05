// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Anubis is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public tokenName = "Anubis NFT";
  string public tokenSymbol = "ANUBISNFT";
  uint256 public maxSupply = 4444;
  uint256 public maxReservedSupply = 888;

  uint256 public maxOGMintAddress = 3;
  uint256 public maxWLMintAddress = 3;
  uint256 public maxPublicMintAddress = 3;

  bytes32 public ogMerkleRoot;
  bytes32 public wlMerkleRoot;
  mapping(address => bool) public mintClaimed; 

  mapping(uint256 => uint256) public nftTrait;

  bool public paused = false;
  bool public whitelistMintEnabled = true;
  bool public revealed = true;

  string public uriPrefix = '';
  string public uriSuffix = '.json';

  string public hiddenMetadataUri = "";
  string public trait1MetadataUri = "ipfs://QmcpUFDj9xdrCZMiTGw4S5ek3G6DhiC7A7KjZcfjYgrCZe/";
  string public trait2MetadataUri = "ipfs://QmdmpDK2y79P8zcEgGqUp3m8NSfHxZApZXpxiUzo4qWe67/";

  uint256 public ogMintUnixTimestamp = 1670164200;
  uint256 public wlMintUnixTimestamp = 1670166000;
  uint256 public publicMintUnixTimestamp = 1670173200;

  uint256 public ogCost = 0.015 ether;
  uint256 public wlCost = 0.018 ether;
  uint256 public publicCost = 0.024 ether;

  constructor() ERC721A(tokenName, tokenSymbol) {
  
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= updateMintCost(_mintAmount), 'Insufficient funds!');
    _;
  }

  function mint(uint256 _mintAmount, uint256 traitType, bytes32[] calldata _merkleProof) public payable mintPriceCompliance(_mintAmount) {

    uint stage = mintStage();

    require(stage > 0, 'Mint not start');

    if (stage == 1) {
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, ogMerkleRoot, leaf), 'Invalid proof!');
    } else if (stage == 2) {
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf), 'Invalid proof!');
    }
		
		require(!paused, 'The contract is paused!');

    if (stage == 1) {
      require(_mintAmount > 0 && _mintAmount <= maxOGMintAddress, 'Invalid mint amount!');
    } else if (stage == 2) {
      require(_mintAmount > 0 && _mintAmount <= maxWLMintAddress, 'Invalid mint amount!');
    } else {
      require(_mintAmount > 0 && _mintAmount <= maxPublicMintAddress, 'Invalid mint amount!');
    }
		
    require(totalSupply() + _mintAmount <= (maxSupply - maxReservedSupply), 'Max supply exceeded!');
		require(!mintClaimed[_msgSender()], 'Address already claimed!');

    if (traitType == 1) {
      uint tokenIdx = totalSupply() + 1;
      nftTrait[tokenIdx] = 1;
      nftTrait[tokenIdx + _mintAmount - 1] = 1;
    } else {
      uint tokenIdx = totalSupply() + 1;
      nftTrait[tokenIdx] = 2;
      nftTrait[tokenIdx + _mintAmount - 1] = 2;
    }

    mintClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintOwner(uint256 _mintAmount, address _receiver, uint256 traitType) public onlyOwner {
		require((totalSupply() + _mintAmount) <= maxSupply, 'Max supply exceeded!');

    if (traitType == 1) {
      uint tokenIdx = totalSupply() + 1;
      nftTrait[tokenIdx] = 1;
      nftTrait[tokenIdx + _mintAmount - 1] = 1;
    } else {
      uint tokenIdx = totalSupply() + 1;
      nftTrait[tokenIdx] = 2;
      nftTrait[tokenIdx + _mintAmount - 1] = 2;
    }

    _safeMint(_receiver, _mintAmount);
  }

  function mintStage() public view returns (uint) {
    
    if (block.timestamp > publicMintUnixTimestamp) {
      return 3;
    }

    if (block.timestamp > wlMintUnixTimestamp) {
      return 2;
    }


    if (block.timestamp > ogMintUnixTimestamp) {
      return 1;
    }

    return 0;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    uint256 traitType = nftTrait[_tokenId];
    if (traitType == 0) {
      for (uint i = _tokenId; i > 0; i--) {
        if (nftTrait[i] != 0) {
          traitType = nftTrait[i];
          break;
        }
      }
    }

    if (traitType == 1) {
     return bytes(trait1MetadataUri).length > 0
        ? string(abi.encodePacked(trait1MetadataUri, _tokenId.toString(), uriSuffix))
        : ''; 
    } else if (traitType == 2) {
      return bytes(trait2MetadataUri).length > 0
        ? string(abi.encodePacked(trait2MetadataUri, _tokenId.toString(), uriSuffix))
        : '';  
    }

    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

	function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost, uint256 stage) public onlyOwner {
    if (stage == 1) {
      ogCost = _cost;
    } else if (stage == 2) {
      wlCost = _cost;
    } else {
      publicCost = _cost;
    }
  }

  function setMaxReservedSupply(uint256 _newMaxReservedSupply) public onlyOwner {
    require(_newMaxReservedSupply <= (maxSupply - totalSupply()));
    maxReservedSupply = _newMaxReservedSupply;
  }

  function setMaxOGMintAddress(uint256 _maxMintAddress) public onlyOwner {
    maxOGMintAddress = _maxMintAddress;
  }

  function setMaxWLMintAddress(uint256 _maxMintAddress) public onlyOwner {
    maxWLMintAddress = _maxMintAddress;
  }

  function setMaxPublicMintAddress(uint256 _maxMintAddress) public onlyOwner {
    maxPublicMintAddress = _maxMintAddress;
  }
  
  function setogMintUnixTimestamp(uint256 _ogMintUnixTimestamp) public onlyOwner {
    ogMintUnixTimestamp = _ogMintUnixTimestamp;
  }

  function setwlMintUnixTimestamp(uint256 _wlMintUnixTimestamp) public onlyOwner {
    wlMintUnixTimestamp = _wlMintUnixTimestamp;
  }

  function setpublicMintUnixTimestamp(uint256 _publicMintUnixTimestamp) public onlyOwner {
    publicMintUnixTimestamp = _publicMintUnixTimestamp;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

   function setTraitMetadataUri(string memory _uriPrefix, uint traitType) public onlyOwner {
     if (traitType == 1) {
       trait1MetadataUri = _uriPrefix;
     } else if (traitType == 2) {
       trait2MetadataUri = _uriPrefix;
     }
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setMerkleRoot(bytes32 _merkleRoot, uint stage) public onlyOwner {
    if (stage == 1) {
      ogMerkleRoot = _merkleRoot;
    } else if (stage == 2) {
      wlMerkleRoot = _merkleRoot;
    }
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

	// A function of hope -> 
  function withdraw() public onlyOwner nonReentrant {
   (bool os, ) = payable(owner()).call{value: address(this).balance}('');
   require(os);
  }

  // Internal ->
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function updateMintCost(uint256 _amount) internal view returns (uint256 _cost) {

    uint256 cost;
    uint stage = mintStage();
    
    if (stage == 1) {
      cost = ogCost;
    } else if (stage == 2) {
      cost = wlCost;
    } else {
      cost = publicCost;
    }

    return cost * _amount;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}