// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Compiler.sol";
import "./Base64.sol";
import "./IMetaDataURI.sol";

contract OnchainCheckGas is ERC721AQueryable, Ownable {
  uint256 public cost = 0.0042 ether;
  uint8 public maxMint = 20;
  bool public publicSaleActive = false; 
  uint256 private immutable MAX_MINT_GAS_PRICE = 1000000; // 1000 gwei mint would show all checks
  IMetaDataURI private immutable metaDataURI;
  IERC721A private immutable ownThisNftForFreeClaim;
  mapping(uint256 => bool) public claimed;

  constructor(
    address renderer,
    address freeClaimNft
  ) ERC721A("OnChainCheckGas", "CHECKGAS") {
    metaDataURI = IMetaDataURI(renderer);
    ownThisNftForFreeClaim = IERC721A(freeClaimNft);
  }

  function setMintActive(bool _newMintActive) public onlyOwner {
    publicSaleActive = _newMintActive;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function claim(uint256[] calldata tokenIds) external {
    require(tokenIds.length > 0, "mint <= 0");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(ownThisNftForFreeClaim.ownerOf(tokenIds[i]) == msg.sender, "Not owner of token");
      require(!claimed[tokenIds[i]], "Token already claimed");
      claimed[tokenIds[i]] = true;
    }
    _safeMint(msg.sender, tokenIds.length);
  }

  function claimAndMint(uint256[] calldata tokenIds, uint256 mintAmount) external payable {
    require(publicSaleActive, "disabled");
    require(
      _numberMinted(msg.sender) + mintAmount <= maxMint,
      "mint >= maxmint"
    );
    require(msg.value >= cost * mintAmount, "Not enough ETH");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(ownThisNftForFreeClaim.ownerOf(tokenIds[i]) == msg.sender, "Not owner of token");
      require(!claimed[tokenIds[i]], "Token already claimed");
      claimed[tokenIds[i]] = true;
    }
    _safeMint(msg.sender, mintAmount + tokenIds.length);
  }

  function mint(address to, uint256 mintAmount) external payable {
    require(publicSaleActive, "disabled");
    require(mintAmount > 0, "mint <= 0");
    require(
      _numberMinted(msg.sender) + mintAmount <= maxMint,
      "mint >= maxmint"
    );
    require(msg.value >= cost * mintAmount, "Not enough ETH");
    _safeMint(to, mintAmount);
  }

  function gift(address to, uint256 mintAmount) external onlyOwner {
    require(mintAmount > 0, "mint <= 0");
    _safeMint(to, mintAmount);
  }

  function availableMint(address to) public view returns (uint256) {
    return maxMint - _numberMinted(to);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    uint256 seed = getTokenSeed(tokenId);
    uint24 gasPrice = getGasPriceAtMint(tokenId);
    return metaDataURI.tokenURI(tokenId, seed, gasPrice);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /**
   * @dev stores the gas price at mint and some entropy to create the batch seed
   * 20 bits for gas price, 4 bits for entropy
   */
  function _extraData(
    address from,
    address, /* to */
    uint24 previousExtraData
  ) internal view override returns (uint24) {
    if (from == address(0)) {
      uint24 gasPrice = uint24(block.basefee / 1000000);
      uint24 entropy = uint24(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1)))) % 16);
      return gasPrice << 4 | entropy;
    }
    return previousExtraData;
  }

  function getGasPriceAtMint(uint256 tokenId) public view returns (uint24) {
    return _ownershipOf(tokenId).extraData >> 4;
  }

  function getTokenSeed(uint256 tokenId) public view returns (uint256) {
    uint24 batchSeed = _ownershipOf(tokenId).extraData;
    return uint256(keccak256(abi.encodePacked(batchSeed, tokenId)));
  }
}