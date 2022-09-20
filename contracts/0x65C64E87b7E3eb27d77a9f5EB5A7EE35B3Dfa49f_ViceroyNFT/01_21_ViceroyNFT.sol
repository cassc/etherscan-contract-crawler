//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./MerkleProof.sol";

contract ViceroyNFT is ERC721, ERC721Enumerable, IERC2981, ERC165Storage, Ownable {

  struct Tier {
    string name;
    uint256 price;
    uint256 presalePrice;
    uint256 maxSupply;
    uint256 maxMintsPerWallet;
    uint256 maxMintsPerWalletOnPreSale;
    uint256 sold;
    uint256 startTokenId;
  }

  string public baseTokenUri;
  bool public isPublicMinting;
  address public royaltyAddress;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd; // ERC165 interface ID for ERC721.
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = type(ERC721Enumerable).interfaceId; // ERC721Enumerable interface ID for ERC721.

  bytes32 public merkleRoot;
  uint256 public tiersCount;
  uint256 public royaltyFeePercentage;

  mapping(uint8 => Tier) public tiers;
  mapping(uint256 => uint8) public tokenTiers;
  mapping(address => mapping(uint8 => uint256)) public ownedTokenCountByTier;

  constructor(
    uint256 _royaltyFeePercentage,
    string memory _baseTokenUri,
    string memory _contractName,
    string memory _contractSymbol,
    Tier[] memory _tiersDefaultValues,
    uint8  _tiersCount
  )
    ERC721(_contractName, _contractSymbol)
  {
    _registerInterface(_INTERFACE_ID_ERC2981);
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);

    baseTokenUri = _baseTokenUri;
    royaltyAddress = owner();
    royaltyFeePercentage = _royaltyFeePercentage;
    
    for (uint8 i = 0; i < _tiersCount; i++) {
      tiers[i] = Tier({
        name: _tiersDefaultValues[i].name,
        price: _tiersDefaultValues[i].price,
        presalePrice: _tiersDefaultValues[i].presalePrice,
        maxSupply: _tiersDefaultValues[i].maxSupply,
        maxMintsPerWallet: _tiersDefaultValues[i].maxMintsPerWallet,
        maxMintsPerWalletOnPreSale: _tiersDefaultValues[i].maxMintsPerWalletOnPreSale,
        sold: 0,
        startTokenId: _tiersDefaultValues[i].startTokenId
        });
     }
     tiersCount = _tiersCount;
  }

  function mint(uint8 _tierId, bytes32[] calldata _merkleProof)
    external
    payable
  {
    require(
      isPublicMinting ||
        MerkleProof.verify(
          _merkleProof,
          merkleRoot,
          keccak256(abi.encodePacked(msg.sender))
        ),
      "SC: wallet not whitelisted"
    );
    require(_tierId < tiersCount, "SC: selected tier is out of bound");
    require(
      ownedTokenCountByTier[msg.sender][_tierId] + 1 <=
        tiers[_tierId].maxMintsPerWallet && isPublicMinting || !isPublicMinting,
      "SC: Max mints per wallet reached"
    );
    require(
      (((ownedTokenCountByTier[msg.sender][_tierId] + 1 <=
        tiers[_tierId].maxMintsPerWalletOnPreSale) && !isPublicMinting) ||
        isPublicMinting),
      "SC: Max mints per wallet on pre-sale reached"
    );
    require(
      (((msg.value == tiers[_tierId].presalePrice) && !isPublicMinting) ||
        isPublicMinting),
      "SC: Incorrect presale price "
    );

    require(
      (msg.value == tiers[_tierId].price) || !isPublicMinting,
      "SC: Incorrect price"
    );

    _internalMint(msg.sender, _tierId);
  }

  function reserveMint(address _to, uint8 _tierId) external onlyOwner {
    _internalMint(_to, _tierId);
  }

  function _internalMint(address _to, uint8 _tierId) internal {
    require(
      tiers[_tierId].sold + 1 <= tiers[_tierId].maxSupply,
      "SC: Max supply reached"
    );
    assert(tiers[_tierId].startTokenId + tiers[_tierId].sold >= tiers[_tierId].startTokenId && tiers[_tierId].startTokenId + tiers[_tierId].sold < tiers[_tierId].startTokenId + tiers[_tierId].maxSupply);
    uint256 tokenId = tiers[_tierId].startTokenId + tiers[_tierId].sold; 
    ownedTokenCountByTier[msg.sender][_tierId] += 1;
    tiers[_tierId].sold += 1;
    tokenTiers[tokenId] = _tierId;
    _safeMint(_to, tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenUri;
  }

  function setTokenUri(string memory _baseTokenUri) external onlyOwner {
    baseTokenUri = _baseTokenUri;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "SC: Token does not exist");
    return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId)));
  }

  function togglePublicMinting() external onlyOwner {
    isPublicMinting = !isPublicMinting;
  }

  function withdrawERC20(IERC20 token, address to) external onlyOwner {
    SafeERC20.safeTransfer(token, to, token.balanceOf(address(this)));
  }

  function withdrawNative() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, bytes memory data) = msg.sender.call{value: balance}("");
    require(sent, "Failed to send");
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable, IERC165, ERC165Storage)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (royaltyAddress, (_salePrice * royaltyFeePercentage) / 10000);
  }

  function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
    royaltyAddress = _royaltyAddress;
  }

  function setRoyaltyFeePercentage(uint256 _royaltyFeePercentage) external onlyOwner {
    royaltyFeePercentage = _royaltyFeePercentage;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setTier(
    uint8 _tierId,
    uint256 _price,
    uint256 _presalePrice,
    uint256 _maxMintsPerWallet,
    uint256 _maxMintsPerWalletOnPreSale
  ) external onlyOwner {
    tiers[_tierId].price = _price;
    tiers[_tierId].presalePrice = _presalePrice;
    tiers[_tierId].maxMintsPerWallet = _maxMintsPerWallet;
    tiers[_tierId].maxMintsPerWalletOnPreSale = _maxMintsPerWalletOnPreSale;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from != address(0)) {
      require(to != from, "SC: You cannot transfer a NFT to yourself!");
      uint8 tierId = tokenTiers[tokenId];
      ownedTokenCountByTier[from][tierId] -= 1;
      ownedTokenCountByTier[to][tierId] += 1;
    }
  }
}