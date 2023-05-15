// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Joke is ERC721A, Ownable {
  uint256 public publicMintPrice = 0.14 ether;
  uint256 public MAX_SUPPLY = 52;
  uint256 public MAX_SIGNATURE = 45;
  uint256 public MAX_SILVER = 5;
  uint256 public MAX_GOLD = 2;
  uint256 private reserveAtATime = 66;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 66;
  uint256 public saleType = 0;
  bytes32 private allowWhitelistMerkleRoot = 0xacd396ee820d0ee8da94e54ed6effb5862c652963affbedbae67d8caf8be5e1a;

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  struct TokenType {
    uint256 id;
    uint256 price;
    uint256 maxSupply;
    uint256 totalMinted;
    string tokenUri;
  }

  TokenType public signature = TokenType(1, 0.12 ether, 45, 0, "");
  TokenType public silver = TokenType(2, 0.65 ether, 5, 0, "");
  TokenType public gold = TokenType(3, 13 ether, 2, 0, "");

  mapping(uint256 => uint256) private _tokenIdsToTokenTypes;

  constructor(string memory signatureTokenUri, string memory silverTokenUri, string memory goldTokenUri) ERC721A("Joke", "JOKE") {
    signature.tokenUri = signatureTokenUri;
    silver.tokenUri = silverTokenUri;
    gold.tokenUri = goldTokenUri;
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  function setSaleType(uint256 _type) external onlyOwner {
    saleType = _type;
  }

  function setSignaturePrice(uint256 _price) public onlyAuthorized {
    signature.price = _price;
  }

  function setSilverPrice(uint256 _price) public onlyAuthorized {
    silver.price = _price;
  }

  function setGoldPrice(uint256 _price) public onlyAuthorized {
    gold.price = _price;
  }

  function setPublicMintPrice(uint256 _price) public onlyAuthorized {
    publicMintPrice = _price;
  }

  function getCurrentPrice(uint256 tokenType) public view returns (uint256) {
    if (saleType == 1) {
      if (tokenType == 1) {
        return signature.price;
      } else if (tokenType == 2) {
        return silver.price;
      } else if (tokenType == 3) {
        return gold.price;
      }
    }

    return publicMintPrice;
  }

  function setSignatureTokenUri(string memory uri) external onlyOwner {
    signature.tokenUri = uri;
  }

  function setSilverTokenUri(string memory uri) external onlyOwner {
    silver.tokenUri = uri;
  }

  function setGoldTokenUri(string memory uri) external onlyOwner {
    gold.tokenUri = uri;
  }

  function setReserveAtATime(uint256 val) public onlyAuthorized {
    reserveAtATime = val;
  }

  function setMaxReserve(uint256 val) public onlyAuthorized {
    maxReserveCount = val;
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyAuthorized {
    MAX_SUPPLY = maxMintSupply;
  }

  function setMaxSignatureSupply(uint256 maxMintSupply) external  onlyAuthorized {
    signature.maxSupply = maxMintSupply;
  }

  function setMaxSilverSupply(uint256 maxMintSupply) external  onlyAuthorized {
    silver.maxSupply = maxMintSupply;
  }

  function setMaxGoldSupply(uint256 maxMintSupply) external  onlyAuthorized {
    gold.maxSupply = maxMintSupply;
  }

  function setAllowWhitelistMerkleRoot(bytes32 merkleRootHash) public onlyAuthorized {
    allowWhitelistMerkleRoot = merkleRootHash;
  }

  function reserveNft() public onlyAuthorized {
    require(reservedCount <= maxReserveCount, "Max Reserves taken already!");
    _safeMint(msg.sender, reserveAtATime);
  }

  function batchAirdrop(uint256 _count, address[] calldata addresses) external onlyAuthorized {
    uint256 supply = totalSupply();

    require(supply <= MAX_SUPPLY, "Total supply spent.");
    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");

    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _safeMint(addresses[i],_count);
    }
  }

  function _setTokenIdToTokenType(uint256 tokenId, uint256 tokenType) internal {
    require(_exists(tokenId), "token type mapping set of nonexistent token");
    _tokenIdsToTokenTypes[tokenId] = tokenType;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Token Id Non-existent");
    uint256 tokenType = _tokenIdsToTokenTypes[_tokenId];
    if (tokenType == signature.id) {
      return bytes(signature.tokenUri).length > 0 ? string(abi.encodePacked(signature.tokenUri, Strings.toString(_tokenId), ".json")) : "";
    } else if (tokenType == silver.id) {
      return bytes(silver.tokenUri).length > 0 ? string(abi.encodePacked(silver.tokenUri, Strings.toString(_tokenId), ".json")) : "";
    } else if (tokenType == gold.id) {
      return bytes(gold.tokenUri).length > 0 ? string(abi.encodePacked(gold.tokenUri, Strings.toString(_tokenId), ".json")) : "";
    }

    return '';
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function mint(uint256 _count, bytes32[] calldata _merkleProof, uint256 tokenType, address _address) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();
    uint256 mintPrice;

    if (_address != owner()) {
      require(saleType != 0, "Sale is not active currently.");
      require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
      require(_count < 5, "Maximum Mint per wallet exceeded.");
      if (saleType == 1) {
        require(_verifyAddressInAllowWhiteList(_merkleProof, _address), "NFT:Sender is not whitelisted.");
        if (tokenType == 1) {
          require(mintIndex + _count <= MAX_SIGNATURE, "Total supply exceeded.");
          mintPrice = signature.price;
        } else if (tokenType == 2) {
          require(mintIndex + _count <= MAX_SILVER, "Total supply exceeded.");
          mintPrice = silver.price;
        } else if (tokenType == 3) {
          require(mintIndex + _count <= MAX_GOLD, "Total supply exceeded.");
          mintPrice = gold.price;
        }
        require(msg.value >= mintPrice * _count, "Insufficient ETH amount sent.");
      } else if (saleType == 2) {
        require(msg.value >= publicMintPrice * _count, "Insufficient ETH amount sent.");
      }
      
      uint256 amount = msg.value;
      payable(owner()).transfer(amount);
    }

    for (uint256 i = 1; i <= _count; i++) {
      _tokenIds.increment();
      uint256 newTokenId = _tokenIds.current();
      _safeMint(_address, newTokenId);
      _setTokenIdToTokenType(newTokenId, tokenType);

      if (tokenType == signature.id) {
          signature.totalMinted++;
      } else if (tokenType == silver.id) {
          silver.totalMinted++;
      } else if (tokenType == gold.id) {
          gold.totalMinted++;
      }
    }
  }

  function _verifyAddressInAllowWhiteList(bytes32[] calldata merkleProof, address toAddress) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(toAddress));
    return MerkleProof.verify(merkleProof, allowWhitelistMerkleRoot, leaf);
  }
}