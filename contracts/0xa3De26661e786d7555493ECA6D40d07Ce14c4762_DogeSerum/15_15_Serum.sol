//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DogeSerum is ERC1155, Ownable, ReentrancyGuard, ERC1155Burnable {
  using Strings for uint256;

  string public baseURI;

  mapping(uint8 => bool) public mintState;
  mapping(uint8 => bool) public publicMintState;

  uint256[4] public totalSupply = [0, 0, 0, 0];

  // doge serum types
  uint8 public constant M1_SERUM = 0;
  uint8 public constant M2_SERUM = 1;
  uint8 public constant M3_SERUM = 2;
  uint8 public constant MEGA_SERUM = 3;
  // max supply
  uint256[4] public maxSupply = [10000, 10000, 10000, 10000];

  uint256 public price = 0; // free mint by default

  bytes32 public merkleRoot;

  mapping(address => bool)[3] public claimed;

  event SetBaseURI(string indexed _baseURI);

  constructor(string memory _baseURI, bytes32 _merkleRoot) ERC1155(_baseURI) {
    baseURI = _baseURI;
    mintState[M1_SERUM] = false;
    mintState[M2_SERUM] = false;
    mintState[M3_SERUM] = false;
    mintState[MEGA_SERUM] = false;

    publicMintState[M1_SERUM] = false;
    publicMintState[M2_SERUM] = false;
    publicMintState[M3_SERUM] = false;
    publicMintState[MEGA_SERUM] = false;

    merkleRoot = _merkleRoot;
  }

  function contractURI() public pure returns (string memory) {
    return "https://ipfs.filebase.io/ipfs/QmWLj32V8gv6h1SoRDfCdhc7GEWhBwN9EmzXfspV57NzFp";
  }

  function uri(uint256 _typeId) public view override returns (string memory) {
    require(
      _typeId == M1_SERUM || _typeId == M2_SERUM || _typeId == M3_SERUM || _typeId == MEGA_SERUM,
      "URI requested for invalid serum type"
    );
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _typeId.toString()))
        : baseURI;
  }

  function mintBatch(uint256 _amount, bytes32[] calldata _merkleProof, uint8 _serumType)
    external
    payable
    nonReentrant
  {
    require(_serumType >= M1_SERUM && _serumType <= M3_SERUM, "Invalid serum type");
    require(mintState[_serumType], "Exclusive mint haven't start");
    require(totalSupply[_serumType] + _amount <= maxSupply[_serumType], "Insufficient remains");
    require(msg.value >= price * _amount, "Insufficient payment");
    require(!claimed[_serumType][msg.sender], "Already claimed");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

    if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
      claimed[_serumType][msg.sender] = true;
      _mint(msg.sender, _serumType, _amount, "");
      totalSupply[_serumType] = totalSupply[_serumType] + _amount;
    }
  }

  function publicMint(uint256 _amount, uint8 _serumType) external payable nonReentrant {
    require(_serumType >= M1_SERUM && _serumType <= MEGA_SERUM, "Invalid serum type");
    require(publicMintState[_serumType], "Public mint haven't started");
    require(
      totalSupply[_serumType] + _amount <= maxSupply[_serumType],
      "Insufficient remains"
    );
    require(msg.value >= price * _amount, "Insufficient payment");

    _mint(msg.sender, _serumType, _amount, "");
    totalSupply[_serumType] = totalSupply[_serumType] + _amount;
  }

  function airdrop(
    address _to,
    uint8 _type,
    uint256 _amount
  ) external onlyOwner {
    require(
      totalSupply[_type] + _amount <= maxSupply[_type],
      "Insufficient tokens left"
    );
    _mint(_to, _type, _amount, "");
    totalSupply[_type] = totalSupply[_type] + _amount;
  }

  function airdropMany(address[] memory _to, uint8 _type) external onlyOwner {
    require(
      totalSupply[_type] + _to.length < maxSupply[_type],
      "Insufficient tokens left"
    );
    for (uint256 i = 0; i < _to.length; i++) {
      _mint(_to[i], _type, 1, "");
    }

    totalSupply[_type] = totalSupply[_type] + _to.length;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function flipMintState(uint8 _serumType) external onlyOwner {
    mintState[_serumType] = !mintState[_serumType];
  }

  function flipPublicState(uint8 _serumType) external onlyOwner {
    publicMintState[_serumType] = !publicMintState[_serumType];
  }

  function setMegaMaxSupply(uint256 _amount) external onlyOwner {
    maxSupply[MEGA_SERUM] = _amount;
  }

  function updateBaseUri(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
    emit SetBaseURI(baseURI);
  }

  // rescue
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawToken(address _tokenContract) external onlyOwner {
    IERC20 tokenContract = IERC20(_tokenContract);

    // transfer the token from address of this contract
    // to address of the user (executing the withdrawToken() function)
    bool success = tokenContract.transfer(
      msg.sender,
      tokenContract.balanceOf(address(this))
    );
    require(success, "Transfer failed.");
  }
}