//SPDX-License-Identifier: Unlicense

/*   
*    __                           _                          
*   / /  ___  __ _  ___ _ __   __| |   /\/\   __ _ _ __  ___ 
*  / /  / _ \/ _` |/ _ \ '_ \ / _` |  /    \ / _` | '_ \/ __|
* / /__|  __/ (_| |  __/ | | | (_| | / /\/\ \ (_| | |_) \__ \
* \____/\___|\__, |\___|_| |_|\__,_| \/    \/\__,_| .__/|___/
*            |___/                                |_|        
*    _____       .___                    __                                     
*   /  _  \    __| _/__  __ ____   _____/  |_ __ _________   ___________  ______
*  /  /_\  \  / __ |\  \/ // __ \ /    \   __\  |  \_  __ \_/ __ \_  __ \/  ___/
* /    |    \/ /_/ | \   /\  ___/|   |  \  | |  |  /|  | \/\  ___/|  | \/\___ \ 
* \____|__  /\____ |  \_/  \___  >___|  /__| |____/ |__|    \___  >__|  /____  >
*         \/      \/           \/     \/                        \/           \/ 
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721A.sol";

contract LMAdventurers is Ownable, ERC721A, IERC2981, ReentrancyGuard {
  using Strings for uint256;
  address private openSeaProxyRegistryAddress;
  bool private isOpenSeaProxyActive = true;

  uint256 public constant LMA_SUPPLY = 8787;
  uint256 public constant LMA_PRICE = 0.04 ether;

  string private _contractURI;
  string private _tokenBaseURI;
  address private _royaltyReceiver = 0x5ed63846531dB1efc08F7FBa9c795007980f4AbD;

  bytes32 public merkleRoot;

  bool public whitelistLive;
  bool public saleLive;

  mapping(address => uint256) public whiteListPurchases;

  constructor(address openSeaProxyRegistryAddress_)
    ERC721A("Legend Maps Adventurers", "LMA", 250)
  {
    openSeaProxyRegistryAddress = openSeaProxyRegistryAddress_;
  }

  function setRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function toggleWhitelist() external onlyOwner {
    whitelistLive = !whitelistLive;
  }

  function toggleSale() external onlyOwner {
    saleLive = !saleLive;
  }

  function getMintsRemaining(address addr, uint256 maxMints)
    external
    view
    returns (uint256)
  {
    return maxMints - whiteListPurchases[addr];
  }

  function _leaf(address account, uint256 maxMints)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(account, maxMints));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }

  function mint(uint256 mintsRequested) external payable {
    require(saleLive, "SALE_CLOSED");
    require(!whitelistLive, "WHITELIST_ONLY");
    require(LMA_PRICE * mintsRequested <= msg.value, "INSUFFICIENT_ETH");
    require(totalSupply() + mintsRequested <= LMA_SUPPLY, "EXCEEDS_SUPPLY");

    _safeMint(msg.sender, mintsRequested);
  }

  function whitelistMint(
    uint256 mintsRequested,
    uint256 maxMints,
    bytes32[] calldata proof
  ) external payable {
    uint256 remainingMints = maxMints - whiteListPurchases[msg.sender];
    require(!saleLive && whitelistLive, "WHITELIST_CLOSED");
    require(_verify(_leaf(msg.sender, maxMints), proof), "UNAUTHORIZED");
    require(totalSupply() + mintsRequested <= LMA_SUPPLY, "EXCEEDS_SUPPLY");
    require(LMA_PRICE * mintsRequested <= msg.value, "INSUFFICIENT_ETH");
    require(mintsRequested <= remainingMints, "EXCEEDS_ALLOCATION");
    require(remainingMints > 0, "MINTS_CONSUMED");

    whiteListPurchases[msg.sender] += mintsRequested;

    _safeMint(msg.sender, mintsRequested);
  }

  function withdraw() external onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function reserve(uint256 count) external onlyOwner {
    _safeMint(msg.sender, count);
  }

  function setContractURI(string calldata uri) external onlyOwner {
    _contractURI = uri;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _tokenBaseURI = baseURI_;
  }

  function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
    external
    onlyOwner
  {
    isOpenSeaProxyActive = _isOpenSeaProxyActive;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenBaseURI;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    public
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");

    return (_royaltyReceiver, SafeMath.div(SafeMath.mul(salePrice, 5), 100));
  }

  function updateRoyaltyReceiver(address receiver) public onlyOwner {
    _royaltyReceiver = receiver;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(openSeaProxyRegistryAddress);
    if (
      isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator
    ) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}