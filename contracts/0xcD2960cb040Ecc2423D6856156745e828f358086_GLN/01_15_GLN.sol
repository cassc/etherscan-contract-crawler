// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract GLN is ERC1155, ERC2981, Ownable, ReentrancyGuard {
  // Sale stage
  enum SaleStages {
    CLOSED,
    PRESALE,
    PUBLIC
  }

  // Token info
  struct Token {
    uint256 id;
    uint256 price;
    uint256 supply;
    uint256 minted;
    uint256 maxPerTx;
    uint256 maxPerAddr;
    bytes32 merkleRoot;
    mapping(address => uint256) addrMinted;
    uint256 saleStage;
    string tokenUri;
    bool onlyOwner;
  }
  mapping(uint256 => Token) public tokens;
  uint256 public tokenIdCounter = 0;

  constructor() ERC1155("") {}

  function mint(
    uint256 _tokenId,
    uint256 _amount,
    bytes32[] calldata _proof
  ) public payable nonReentrant {
    require(msg.sender == tx.origin, "Smart contract interaction is not supported");
    require(_tokenId < tokenIdCounter, "Token does not exist");

    Token storage token = tokens[_tokenId];
    require(!token.onlyOwner, "Not allowed");
    require(_amount + token.minted <= token.supply, "Amount not available");
    require(token.saleStage > uint256(SaleStages.CLOSED), "Token sale is closed");
    require(_amount * token.price == msg.value, "Insufficient founds");

    if (token.merkleRoot != 0 && token.saleStage == uint256(SaleStages.PRESALE)) {
      _checkProof(_proof, token.merkleRoot);
    }
    if (token.maxPerAddr != 0) {
      require(_amount + token.addrMinted[msg.sender] <= token.maxPerAddr, "Max per address exceeded");
    }

    if (token.maxPerTx != 0) {
      require(_amount <= token.maxPerTx, "Max per transaction exceeded");
    }

    token.minted += _amount;
    token.addrMinted[msg.sender] += _amount;
    _mint(msg.sender, _tokenId, _amount, "");
  }

  function ownerMint(
    uint256 _tokenId,
    uint256 _amount,
    address _receiver
  ) external onlyOwner {
    require(_tokenId < tokenIdCounter, "Token does not exist");
    Token storage token = tokens[_tokenId];

    if (!token.onlyOwner) {
      require(_amount + token.minted <= token.supply, "Amount not available");
    } else {
      token.supply += _amount;
    }

    token.minted += _amount;
    _mint(_receiver, _tokenId, _amount, "");
  }

  // Getters
  function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
    Token storage token = tokens[_id];
    return token.tokenUri;
  }

  function hasMintedToken(address _account, uint256 _id) public view returns (uint256) {
    Token storage token = tokens[_id];
    return token.addrMinted[_account];
  }

  // Create token
  function createToken(
    uint256 _price,
    uint256 _supply,
    uint256 _maxPerTx,
    uint256 _maxPerAddr,
    bytes32 _merkleRoot,
    string memory _tokenUri,
    bool _onlyOwner
  ) public onlyOwner {
    Token storage token = tokens[tokenIdCounter];
    token.id = tokenIdCounter;
    token.saleStage = uint256(SaleStages.CLOSED);
    token.onlyOwner = _onlyOwner;
    tokenIdCounter++;

    if (_onlyOwner) {
      setTokenInfo(token.id, 0, 0, 0, 0, bytes32(0), _tokenUri);
    } else {
      setTokenInfo(token.id, _price, _supply, _maxPerTx, _maxPerAddr, _merkleRoot, _tokenUri);
    }
  }

  // Setters
  function setTokenInfo(
    uint256 _tokenId,
    uint256 _price,
    uint256 _supply,
    uint256 _maxPerTx,
    uint256 _maxPerAddr,
    bytes32 _merkleRoot,
    string memory _tokenUri
  ) public onlyOwner {
    require(_tokenId < tokenIdCounter, "Token does not exist");
    Token storage token = tokens[_tokenId];
    token.price = _price;
    token.supply = _supply;
    token.maxPerTx = _maxPerTx;
    token.maxPerAddr = _maxPerAddr;
    token.merkleRoot = _merkleRoot;
    token.tokenUri = _tokenUri;
  }

  function setSaleStage(uint256[] calldata _ids, uint256[] calldata _stages) external onlyOwner {
    require(_ids.length == _stages.length, "Arrays of differet sizes are not supported");
    for (uint256 i = 0; i < _ids.length; ++i) {
      uint256 id = _ids[i];
      require(id < tokenIdCounter, "Token does not exist");
      Token storage token = tokens[id];
      token.saleStage = _stages[i];
    }
  }

  function setDefaultRoyalty(address receiver, uint96 feeBasisPoints) external onlyOwner {
    _setDefaultRoyalty(receiver, feeBasisPoints);
  }

  // Withdraw
  function withdraw(address payable _receiver) external nonReentrant onlyOwner {
    require(_receiver != address(0), "Receiver address cannot be zero");
    require(address(this).balance > 0, "Balance is zero");
    payable(_receiver).transfer(address(this).balance);
  }

  // Utils
  function _checkProof(bytes32[] calldata _proof, bytes32 _merkleRoot) private view {
    require(MerkleProof.verify(_proof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not allowed");
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
    return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}