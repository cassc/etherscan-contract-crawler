// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *       ______                ____                 
 *      / ____/_  ______ ___  / __ )_________  _____
 *     / / __/ / / / __ `__ \/ __  / ___/ __ \/ ___/
 *    / /_/ / /_/ / / / / / / /_/ / /  / /_/ (__  ) 
 *    \____/\__, /_/ /_/ /_/_____/_/   \____/____/  
 *         /____/                                   
 *                    GymBros | 2021  
 *             @author Josh Stow (jstow.com)
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract GymBros is ERC721Enumerable, Ownable {
  using Address for address payable;

  uint256 public constant GBRO_PREMINT = 50;
  uint256 public constant GBRO_MAX = 10000;
  uint256 public constant GBRO_MAX_PRESALE = 2000;
  uint256 public constant GBRO_PRICE = 0.07 ether;
  uint256 public constant GBRO_PER_WALLET = 20;
  uint256 public constant GBRO_PER_WALLET_PRESALE = 3;

  mapping(address => uint256) public addressToMinted;

  bytes32 public root;
  string public provenance;

  string private _baseTokenURI;
  string private _contractURI;

  bool public presaleLive;
  bool public saleLive;

  bool public locked;

  address private _devAddress = 0xbB61A5398EeF5707fa662F42B7fC1Ca32e76e747;

  constructor(
    string memory newBaseTokenURI,
    string memory newContractURI,
    bytes32 _root
  )
    ERC721("GYMBROs", "GBRO")
  {
    _baseTokenURI = newBaseTokenURI;
    _contractURI = newContractURI;
    root = _root;

    _preMint(GBRO_PREMINT);
  }

  /**
   * @dev Mints number of tokens specified to wallet during presale.
   * @param quantity uint256 Number of tokens to be minted
   * @param proof bytes32[] Merkle proof of wallet address
   */
  function presaleBuy(uint256 quantity, bytes32[] calldata proof) external payable {
    require(presaleLive && !saleLive, "GymBros: Presale not currently live");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(proof, root, leaf), "GymBros: Caller is not eligible for presale");

    require(totalSupply() + quantity <= GBRO_MAX_PRESALE, "GymBros: Quantity exceeds remaining tokens");
    require(quantity <= GBRO_PER_WALLET_PRESALE - addressToMinted[msg.sender], "GymBros: Wallet cannot mint any new tokens");
    require(quantity != 0, "GymBros: Cannot buy zero tokens");
    require(msg.value >= quantity * GBRO_PRICE, "GymBros: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      addressToMinted[msg.sender]++;
      _safeMint(msg.sender, totalSupply()+1);
    }
  }

  /**
   * @dev Mints number of tokens specified to wallet.
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(uint256 quantity) external payable {
    require(saleLive && !presaleLive, "GymBros: Sale is not currently live");
    require(totalSupply() + quantity <= GBRO_MAX, "GymBros: Quantity exceeds remaining tokens");
    require(quantity <= GBRO_PER_WALLET - addressToMinted[msg.sender], "GymBros: Wallet cannot mint any new tokens");
    require(quantity != 0, "GymBros: Cannot buy zero tokens");
    require(msg.value >= quantity * GBRO_PRICE, "GymBros: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      addressToMinted[msg.sender]++;
      _safeMint(msg.sender, totalSupply()+1);
    }
  }

  /**
   * @dev Checks if wallet address is whitelisted.
   * @param wallet address Ethereum wallet to be checked
   * @param proof bytes32[] Merkle proof of wallet address
   * @return bool Presale eligibility of address
   */
  function isWhitelisted(address wallet, bytes32[] calldata proof) external view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(wallet));
    
    return MerkleProof.verify(proof, root, leaf);
  }

  /**
   * @dev Sets Merkle tree root.
   * @param _root bytes32 New root
   */
  function setRoot(bytes32 _root) external onlyOwner {
    root = _root;
  }

  /**
   * @dev Set base token URI.
   * @param newBaseURI string New URI to set
   */
  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    require(!locked, "GymBros: Contract metadata is locked");
    _baseTokenURI = newBaseURI;
  }
  
  /**
   * @dev Set contract URI.
   * @param newContractURI string New URI to set
   */
  function setContractURI(string calldata newContractURI) external onlyOwner {
    require(!locked, "GymBros: Contract metadata is locked");
    _contractURI = newContractURI;
  }

  /**
   * @dev Set provenance hash.
   * @param hash string Provenance hash
   */
  function setProvenanceHash(string calldata hash) external onlyOwner {
    require(!locked, "GymBros: Contract metadata is locked");
    provenance = hash;
  }

  /**
   * @dev Returns token URI of token with given tokenId.
   * @param tokenId uint256 Id of token
   * @return string Specific token URI
   */
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "GymBros: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
  }

  /**
   * @dev Returns contract URI.
   * @return string Contract URI
   */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Toggles status of token presale. Only callable by owner.
   */
  function togglePresale() external onlyOwner {
    presaleLive = !presaleLive;
  }

  /**
   * @dev Toggles status of token sale. Only callable by owner.
   */
  function toggleSale() external onlyOwner {
    saleLive = !saleLive;
  }

  /**
   * @dev Locks contract metadata. Only callable by owner.
   */
  function lockMetadata() external onlyOwner {
    locked = true;
  }

  /**
   * @dev Withdraw funds from contract. Only callable by owner.
   */
  function withdraw() public onlyOwner {
    payable(_devAddress).sendValue(address(this).balance * 15 / 1000);  // 1.5%
    payable(msg.sender).sendValue(address(this).balance);
  }

  /**
   * @dev Pre mint n tokens to owner address.
   * @param n uint256 Number of tokens to be minted
   */
  function _preMint(uint256 n) private {
    for (uint256 i=0; i<n; i++) {
      _safeMint(owner(), totalSupply()+1);
    }
  }
}