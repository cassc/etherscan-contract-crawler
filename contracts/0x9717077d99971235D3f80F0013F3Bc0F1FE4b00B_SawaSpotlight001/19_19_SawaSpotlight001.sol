// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SawaSpotlight001 is ERC721, IERC2981, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;
  using ECDSA for bytes32;

  Counters.Counter private currentTokenId;

  string private baseURI;

  uint256 public constant MAX_TOKENS_PER_WALLET = 5;
  uint256 collectionSize = 2000;

  bool public isPublicSaleActive;
  bool public isAllowlistSaleActive;
  address public signer;
  mapping(bytes => bool) public allowlistSignatureUsed;

  // ============ MODIFIERS ============

  modifier publicSaleActive() {
    require(isPublicSaleActive, "Public sale is not open");
    _;
  }

  modifier allowlistSaleActive() {
    require(isAllowlistSaleActive, "Allowlist sale is not open");
    _;
  }

  modifier maxTokensPerWallet(uint256 numberOfTokensToAdd) {
    require(
      balanceOf(msg.sender) + numberOfTokensToAdd <= MAX_TOKENS_PER_WALLET,
      "Max tokens already minted to this wallet"
    );
    _;
  }

  modifier canMintTokens(uint256 numberOfTokensToAdd) {
    require(
      currentTokenId.current() + numberOfTokensToAdd <= collectionSize,
      "Not enough tokens remaining to mint"
    );
    _;
  }

  modifier signatureVerified(address _addr, bytes calldata _signature) {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encode(_addr))
      )
    );
    require(
      signer == digest.recover(_signature),
      "Unable to verify allowlist signature"
    );
    _;
  }

  modifier hasNotClaimedAllowlist(bytes memory signature) {
    require(
      !allowlistSignatureUsed[signature],
      "Allowlist signature has already been used"
    );
    _;
  }

  constructor() ERC721("Sawa Spotlight x Rayouf", "SAWA") {}

  // ============ MINTING ============

  function mint()
    external
    payable
    nonReentrant
    publicSaleActive
    canMintTokens(1)
    maxTokensPerWallet(1)
  {   
    _safeMint(msg.sender, nextTokenId());
  }

  function allowlistMint(bytes calldata _signature)
    external
    payable
    nonReentrant
    allowlistSaleActive
    canMintTokens(1)
    maxTokensPerWallet(1)
    signatureVerified(msg.sender, _signature)
    hasNotClaimedAllowlist(_signature)
  {
     _safeMint(msg.sender, nextTokenId());
     allowlistSignatureUsed[_signature] = true;
  }

  // ============ GETTERS ============

  function getBaseURI() external view returns (string memory) {
    return baseURI;
  }

  function getCurrentTokenId() external view returns (uint256) {
    return currentTokenId.current();
  }

  // ============ SETTERS ============

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function setIsPublicSaleActive(bool _isPublicSaleActive) external onlyOwner { 
    isPublicSaleActive = _isPublicSaleActive;
  }

  function setIsAllowlistSaleActive(bool _isAllowlistSaleActive) external onlyOwner {
    isAllowlistSaleActive = _isAllowlistSaleActive;
  }

  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  // ============ WITHDRAWL ============

  function withdraw() public onlyOwner nonReentrant {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawTokens(IERC20 token) public onlyOwner nonReentrant {
    uint amount = token.balanceOf(address(this));
    token.transfer(msg.sender, amount);
  }

  // ============ HELPERS ============

  function nextTokenId() private returns (uint256) {
    currentTokenId.increment();
    return currentTokenId.current();
  }

  // ============ OVERRIDES ============

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, IERC165)
    returns (bool)
  {
    return
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
  }
  
  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
  {
      require(_exists(tokenId), "Nonexistent token");

      return
          string(abi.encodePacked(baseURI, "/", tokenId.toString()));
  }

  /**
   * @dev See {IERC165-royaltyInfo}.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");

    return (address(this), SafeMath.div(SafeMath.mul(salePrice, 10), 100));
  }
}