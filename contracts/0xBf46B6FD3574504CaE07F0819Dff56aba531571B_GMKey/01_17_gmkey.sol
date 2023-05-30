// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GMKey is ERC721A, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using ECDSA for bytes32;
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public constant MAX_GM_KEY = 777;
  uint256 public MAX_GM_KEY_PER_PURCHASE = 7;
  uint256 public MAX_GM_KEY_WHITELIST_CAP = 1;
  uint256 public constant GM_KEY_PRICE = 0.14 ether;
  uint256 public constant GM_KEY_PRESALE_PRICE = 0.07 ether;
  uint256 public constant RESERVED_GM_KEY = 30;
  
  bytes32 public merkleroot;
  string public tokenBaseURI;
  bool public presaleActive = false;
  bool public mintActive = false;
  bool public reservesMinted = false;
  bool public reveal = false;

  mapping(address => uint256) private whitelistAddressMintCount;

  /**
   * @dev Contract Methods
   */
  constructor(
    uint256 _maxGMKeyPerPurchase
  ) ERC721A("GM Key", "GMK", _maxGMKeyPerPurchase, MAX_GM_KEY) {}
  /********
   * Mint *
   ********/
  function presaleMint(uint256 _quantity, bytes32[] calldata _merkleProof) external payable nonReentrant {
    require(verifyMerkleProof(keccak256(abi.encodePacked(msg.sender)), _merkleProof), "Invalid whitelist signature");
    require(presaleActive, "Presale is not active");
    require(_quantity <= MAX_GM_KEY_WHITELIST_CAP, "This is above the max allowed mints for presale");
    require(msg.value >= GM_KEY_PRESALE_PRICE.mul(_quantity), "The ether value sent is not correct");
    require(whitelistAddressMintCount[msg.sender].add(_quantity) <= MAX_GM_KEY_WHITELIST_CAP, "This purchase would exceed the maximum you are allowed to mint in the presale");
    require(totalSupply().add(_quantity) <= MAX_GM_KEY - RESERVED_GM_KEY, "This purchase would exceed max supply for presale");

    whitelistAddressMintCount[msg.sender] += _quantity;
    _safeMintGMKey(_quantity);
  }

  function publicMint(uint256 _quantity) external payable {
    require(mintActive, "Sale is not active.");
    require(_quantity <= MAX_GM_KEY_PER_PURCHASE, "Quantity is more than allowed per transaction.");
    require(msg.value >= GM_KEY_PRICE.mul(_quantity), "The ether value sent is not correct");

    _safeMintGMKey(_quantity);
  }

  function _safeMintGMKey(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 gm key nft");
    require(totalSupply().add(_quantity) <= MAX_GM_KEY, "This purchase would exceed max supply");
    _safeMint(msg.sender, _quantity);
  }

  /*
   * Note: Mint reserved gm key.
   */

  function mintReservedGMKey() external onlyOwner {
    require(!reservesMinted, "Reserves have already been minted.");
    require(totalSupply().add(RESERVED_GM_KEY) <= MAX_GM_KEY, "This mint would exceed max supply");
    _safeMint(msg.sender, RESERVED_GM_KEY);

    reservesMinted = true;
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
  }

  function setMerkleRoot(bytes32 MR) external onlyOwner {
    merkleroot = MR;
  }

  function setReveal(bool _reveal) external onlyOwner {
    reveal = _reveal;
  }

  function setWhitelistCap(uint256 _cap) external onlyOwner {
    MAX_GM_KEY_WHITELIST_CAP = _cap;
  }

  function setTokenBaseURI(string memory _baseURI) external onlyOwner {
    tokenBaseURI = _baseURI;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    if (!reveal) {
      return string(abi.encodePacked(tokenBaseURI));
    }

    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
  }

  /**************
   * Withdrawal *
   **************/

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /************
   * Security *
   ************/

  function verifyMerkleProof(bytes32 leaf, bytes32[] memory _merkleProof) private view returns(bool) {
    return MerkleProof.verify(_merkleProof, merkleroot, leaf);
  }
}