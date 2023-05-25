// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GrayBoys is ERC721, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using ECDSA for bytes32;
  using Counters for Counters.Counter;
  using Strings for uint256;

  /**
   * @dev Aliens Incoming
   * */

  string public GRAY_BOYS_PROVENANCE = "";

  uint256 public MAX_GRAY_BOYS;
  uint256 public MAX_GRAY_BOYS_PER_PURCHASE;
  uint256 public MAX_GRAY_BOYS_WHITELIST_CAP;
  uint256 public constant GRAY_BOY_PRICE = 0.07 ether;
  uint256 public constant RESERVED_GRAY_BOYS = 100;

  string public tokenBaseURI;
  string public unrevealedURI;
  bool public presaleActive = false;
  bool public mintActive = false;
  bool public reservesMinted = false;

  mapping(address => uint256) private whitelistAddressMintCount;

  Counters.Counter public tokenSupply;

  /**
   * @dev Contract Methods
   */

  constructor(
    uint256 _maxGrayBoys,
    uint256 _maxGrayBoysPerPurchase,
    uint256 _maxGrayBoysWhitelistCap
  ) ERC721("Gray Boys", "GRAY") {
    MAX_GRAY_BOYS = _maxGrayBoys;
    MAX_GRAY_BOYS_PER_PURCHASE = _maxGrayBoysPerPurchase;
    MAX_GRAY_BOYS_WHITELIST_CAP = _maxGrayBoysWhitelistCap;
  }

  /************
   * Metadata *
   ************/

  /*
   * Provenance hash is the sha256 hash of the IPFS DAG root CID for gray boys.
   * It will be set prior to any minting and never changed thereafter.
   */

  function setProvenanceHash(string memory provenanceHash) external onlyOwner {
    GRAY_BOYS_PROVENANCE = provenanceHash;
  }

  /*
   * Note: Initial baseURI upon reveal will be a centralized server IF all gray boys haven't
   * been minted by December 1st, 2021 - The reveal date. This is to prevent releasing all metadata
   * and causing a sniping vulnerability prior to all gray boys being minted.
   * Once all gray boys have been minted, the baseURI will be swapped to the final IPFS DAG root CID.
   * For this reason, a watchdog is not set since the time of completed minting is undeterminable.
   * We intend to renounce contract ownership once minting is complete and the IPFS DAG is assigned
   * to serve metadata in order to prevent future calls against setTokenBaseURI or other owner functions.
   */

  function setTokenBaseURI(string memory _baseURI) external onlyOwner {
    tokenBaseURI = _baseURI;
  }

  function setUnrevealedURI(string memory _unrevealedUri) external onlyOwner {
    unrevealedURI = _unrevealedUri;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    bool revealed = bytes(tokenBaseURI).length > 0;

    if (!revealed) {
      return unrevealedURI;
    }

    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(tokenBaseURI, _tokenId.toString()));
  }

  /********
   * Mint *
   ********/

  function presaleMint(uint256 _quantity, bytes calldata _whitelistSignature) external payable nonReentrant {
    require(verifyOwnerSignature(keccak256(abi.encode(msg.sender)), _whitelistSignature), "Invalid whitelist signature");
    require(presaleActive, "Presale is not active");
    require(_quantity <= MAX_GRAY_BOYS_WHITELIST_CAP, "You can only mint a maximum of 3 for presale");
    require(whitelistAddressMintCount[msg.sender].add(_quantity) <= MAX_GRAY_BOYS_WHITELIST_CAP, "This purchase would exceed the maximum Gray Boys you are allowed to mint in the presale");

    whitelistAddressMintCount[msg.sender] += _quantity;
    _safeMintGrayBoys(_quantity);
  }

  function publicMint(uint256 _quantity) external payable {
    require(mintActive, "Sale is not active.");
    require(_quantity <= MAX_GRAY_BOYS_PER_PURCHASE, "Quantity is more than allowed per transaction.");

    _safeMintGrayBoys(_quantity);
  }

  function _safeMintGrayBoys(uint256 _quantity) internal {
    require(_quantity > 0, "You must mint at least 1 gray boy");
    require(tokenSupply.current().add(_quantity) <= MAX_GRAY_BOYS, "This purchase would exceed max supply of Gray Boys");
    require(msg.value >= GRAY_BOY_PRICE.mul(_quantity), "The ether value sent is not correct");

    for (uint256 i = 0; i < _quantity; i++) {
      uint256 mintIndex = tokenSupply.current();

      if (mintIndex < MAX_GRAY_BOYS) {
        tokenSupply.increment();
        _safeMint(msg.sender, mintIndex);
      }
    }
  }

  /*
   * Note: Reserved gray boys will be minted immediately after the presale ends
   * but before the public sale begins. This ensures a randomized start tokenId
   * for the reserved mints.
   */

  function mintReservedGrayBoys() external onlyOwner {
    require(!reservesMinted, "Reserves have already been minted.");
    require(tokenSupply.current().add(RESERVED_GRAY_BOYS) <= MAX_GRAY_BOYS, "This mint would exceed max supply of Gray Boys");

    for (uint256 i = 0; i < RESERVED_GRAY_BOYS; i++) {
      uint256 mintIndex = tokenSupply.current();

      if (mintIndex < MAX_GRAY_BOYS) {
        tokenSupply.increment();
        _safeMint(msg.sender, mintIndex);
      }
    }

    reservesMinted = true;
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setMintActive(bool _active) external onlyOwner {
    mintActive = _active;
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

  function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
    return hash.toEthSignedMessageHash().recover(signature) == owner();
  }
}