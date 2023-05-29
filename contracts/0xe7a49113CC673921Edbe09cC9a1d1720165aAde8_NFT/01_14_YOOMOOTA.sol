// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NFT is Ownable, ERC721A, Pausable, ReentrancyGuard {
  bool public isRevealed = false;
  uint256 public collectionSize;
  uint256 public maxBatchSize;
  uint256 public amountForDevs;

  struct WhitelistSaleConfig {
    bytes32 merkleRoot;
    uint32 startTime;
    uint64 price;
    uint64 maxPerAddress;
  }

  WhitelistSaleConfig public whitelistSaleConfig;

  struct PublicSaleConfig {
    uint32 startTime;
    uint64 price;
    uint64 maxPerAddress;
  }

  PublicSaleConfig public publicSaleConfig;

  string private _baseTokenURI;
  string private _defaultTokenURI;

  constructor(
    uint256 collectionSize_,
    uint256 maxBatchSize_,
    uint256 amountForDevs_
  ) ERC721A("YOOMOOTA x WAGMI Team", "YOOMOOTA") {
    collectionSize = collectionSize_;
    maxBatchSize = maxBatchSize_;
    amountForDevs = amountForDevs_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "need to send more ETH");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  /**
   * @dev Triggers emergency stop mechanism.
   */
  function pause() external onlyOwner
  {
    _pause();
  }

  /**
   * @dev Returns contract to normal state.
   */
  function unpause() external onlyOwner
  {
    _unpause();
  }

  /**
    * @dev Hook that is called before minting and burning one token.
  */
  function _beforeTokenTransfers(
      address from,
      address to,
      uint256 startTokenId,
      uint256 quantity
  ) internal virtual whenNotPaused override {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  function setupWhitelistSale(
    bytes32 merkleRoot,
    uint32 whitelistSaleStartTime,
    uint64 whitelistSalePriceWei,
    uint64 maxPerAddressDuringWhitelistSaleMint
  ) external onlyOwner {
    whitelistSaleConfig.merkleRoot = merkleRoot;
    whitelistSaleConfig.startTime = whitelistSaleStartTime;
    whitelistSaleConfig.price = whitelistSalePriceWei;
    whitelistSaleConfig.maxPerAddress = maxPerAddressDuringWhitelistSaleMint;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner {
    whitelistSaleConfig.merkleRoot = root;
  }

  function whitelistSaleMint(bytes32[] calldata proof, uint64 quantity)
    external
    payable
    callerIsUser
    nonReentrant
  {
    uint256 price = uint256(whitelistSaleConfig.price);
    uint256 saleStartTime = uint256(whitelistSaleConfig.startTime);
    uint64 maxPerAddress = whitelistSaleConfig.maxPerAddress;
    require(price != 0, "whitelist sale has not begun yet");
    require(
      saleStartTime != 0 && block.timestamp >= saleStartTime,
      "whitelist sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(
      MerkleProof.verify(proof, whitelistSaleConfig.merkleRoot, leaf),
      "invalid whitelist proof"
    );
    require(
      _getAux(_msgSender()) + quantity <= maxPerAddress,
      "can not mint this many"
    );
    _safeMint(_msgSender(), quantity);
    _setAux(_msgSender(), _getAux(_msgSender()) + quantity); 
    refundIfOver(price * quantity);
  }

  function endWhitelistSaleAndSetupPublicSale(
    uint32 publicSaleStartTime,
    uint64 publicSalePriceWei,
    uint64 maxPerAddressDuringPublicSaleMint
  ) external onlyOwner {
    whitelistSaleConfig.startTime = 0;

    publicSaleConfig.startTime = publicSaleStartTime;
    publicSaleConfig.price = publicSalePriceWei;
    publicSaleConfig.maxPerAddress = maxPerAddressDuringPublicSaleMint;
  }

  function publicSaleMint(uint64 quantity)
    external
    payable
    callerIsUser
    nonReentrant
  {
    uint256 price = uint256(publicSaleConfig.price);
    uint256 startTime = uint256(publicSaleConfig.startTime);
    uint64 maxPerAddress = publicSaleConfig.maxPerAddress;
    require(price != 0, "public sale has not begun yet");
    require(
      startTime != 0 && block.timestamp >= startTime,
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      _numberMinted(_msgSender()) - _getAux(_msgSender()) + quantity
        <= maxPerAddress,
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(price * quantity);
  }

  function setIsRevealed(bool val) external onlyOwner {
    isRevealed = val;
  }

  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for(uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
  {
    if (isRevealed) {
      return super.tokenURI(tokenId);
    }

    require(tokenId <= totalSupply(), "token not exist");
    return _defaultTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setDefaultTokenURI(string calldata uri) external onlyOwner {
    _defaultTokenURI = uri;
  }

  function setCollectionSize(uint256 size) external onlyOwner {
    collectionSize = size;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "transfer failed");
  }
}