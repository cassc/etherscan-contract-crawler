// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './Revealable.sol';
import './ERC721FDEnumerable.sol';

contract CatRescue is ERC721FDEnumerable, Revealable, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;

  event SaleMint(address receiver, uint256 mintedCount);

  // immutable inventory
  uint256 private immutable _saleMintInventory;
  // immutable claimable count per address
  uint256 private immutable _presaleClaimableCountPerAddress;

  uint256 private _saleMintMaxBatchSize;
  Counters.Counter private _saleMintedCount;

  struct SaleConfig {
    // uint256 packing {{{
    uint64 presalePrice;
    uint32 presaleStartTimestamp;
    uint32 presaleFinishTimestamp;
    uint64 publicSalePrice;
    uint32 publicSaleStartTimestamp;
    uint32 publicSaleFinishTimestamp;
    // }}}
  }
  SaleConfig private _saleConfig;

  bytes32 private _presaleAllowlistMerkleRoot;
  mapping(address => uint256) private _presaleClaimedCountPerAddress;

  constructor(
    uint256 devMintInventory_,
    uint256 saleMintInventory_,
    uint256 presaleMaxClaimableCountPerAddress_,
    uint256 saleMintMaxBatchSize_
  )
    ERC721FDEnumerable(
      'CatRescue',
      'CATRESCUE',
      devMintInventory_,
      saleMintInventory_
    )
  {
    _saleMintMaxBatchSize = saleMintMaxBatchSize_;
    _saleMintInventory = saleMintInventory_;
    _presaleClaimableCountPerAddress = presaleMaxClaimableCountPerAddress_;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );
    return Revealable._tokenURI(tokenId);
  }

  function baseURI() public view virtual returns (string memory) {
    return Revealable.r_baseURI();
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    Revealable._setBaseURI(_baseURI);
  }

  function withdrawETH() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}('');
    require(success, 'Transfer failed.');
  }

  function devMint(address to) external onlyOwner {
    _setDevMintAddress(to);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, 'The caller is another contract');
    _;
  }

  function setPresaleAllowlistMerkleRoot(bytes32 presaleAllowlistMerkleRoot_)
    external
    onlyOwner
  {
    _presaleAllowlistMerkleRoot = presaleAllowlistMerkleRoot_;
  }

  function presaleStartTimestamp() public view virtual returns (uint32) {
    return _saleConfig.presaleStartTimestamp;
  }

  function setPresaleStartTimestamp(uint32 presaleStartTimestamp_)
    external
    onlyOwner
  {
    _saleConfig.presaleStartTimestamp = presaleStartTimestamp_;
  }

  function presaleFinishTimestamp() public view virtual returns (uint32) {
    return _saleConfig.presaleFinishTimestamp;
  }

  function setPresaleFinishTimestamp(uint32 presaleFinishTimestamp_)
    external
    onlyOwner
  {
    _saleConfig.presaleFinishTimestamp = presaleFinishTimestamp_;
  }

  function saleMintInventory() public view virtual returns (uint256) {
    return _saleMintInventory;
  }

  function saleMintedCount() public view virtual returns (uint256) {
    return _saleMintedCount.current();
  }

  function saleMintMaxBatchSize() public view virtual returns (uint256) {
    return _saleMintMaxBatchSize;
  }

  function presaleClaimableCountPerAddress()
    public
    view
    virtual
    returns (uint256)
  {
    return _presaleClaimableCountPerAddress;
  }

  function presaleClaimedCount(address addr)
    public
    view
    virtual
    returns (uint256)
  {
    return _presaleClaimedCountPerAddress[addr];
  }

  function setPresalePrice(uint64 presaleMintPrice_) external onlyOwner {
    _saleConfig.presalePrice = presaleMintPrice_;
  }

  function presalePrice() public view virtual returns (uint64) {
    return _saleConfig.presalePrice;
  }

  function presaleMint(bytes32[] memory merkleProof, uint256 quantity)
    external
    payable
    callerIsUser
  {
    require(_saleConfig.presalePrice != 0, 'Pressale price is not settled.');
    require(
      _saleConfig.presaleStartTimestamp != 0,
      'Pressale start date is not settled.'
    );
    require(
      block.timestamp >= _saleConfig.presaleStartTimestamp,
      'Pressale has not started.'
    );
    require(
      _saleConfig.presaleFinishTimestamp == 0 ||
        block.timestamp < _saleConfig.presaleFinishTimestamp,
      'Pressale has finished.'
    );

    // check allowlist
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProof.verify(merkleProof, _presaleAllowlistMerkleRoot, leaf),
      'Not found in presale allowlist.'
    );

    // check claimable count
    require(
      quantity <=
        _presaleClaimableCountPerAddress -
          _presaleClaimedCountPerAddress[msg.sender],
      'Insufficient claimable count.'
    );
    _presaleClaimedCountPerAddress[msg.sender] += quantity;

    // check inventory
    require(
      _saleMintedCount.current() + quantity <= _saleMintInventory,
      'Insufficient inventory.'
    );

    // check msg.value
    require(
      msg.value >= _saleConfig.presalePrice * quantity,
      'Insufficient ETH.'
    );

    // mint
    for (uint256 i = 0; i < quantity; i++) {
      _saleMintedCount.increment();
      uint256 count = _saleMintedCount.current();
      _mint(msg.sender, devMintInventory() + count);
    }

    // refund if msg.value is too large
    if (msg.value > _saleConfig.presalePrice * quantity) {
      payable(msg.sender).transfer(
        msg.value - _saleConfig.presalePrice * quantity
      );
    }

    emit SaleMint(msg.sender, _saleMintedCount.current());
  }

  function publicSaleStartTimestamp() public view virtual returns (uint32) {
    return _saleConfig.publicSaleStartTimestamp;
  }

  function setPublicSaleStartTimestamp(uint32 publicSaleStartTimestamp_)
    external
    onlyOwner
  {
    _saleConfig.publicSaleStartTimestamp = publicSaleStartTimestamp_;
  }

  function publicSaleFinishTimestamp() public view virtual returns (uint32) {
    return _saleConfig.publicSaleFinishTimestamp;
  }

  function setPublicSaleFinishTimestamp(uint32 publicSaleFinishTimestamp_)
    external
    onlyOwner
  {
    _saleConfig.publicSaleFinishTimestamp = publicSaleFinishTimestamp_;
  }

  function publicSalePrice() public view virtual returns (uint64) {
    return _saleConfig.publicSalePrice;
  }

  function setPublicSalePrice(uint64 publicSaleMintPrice_) external onlyOwner {
    _saleConfig.publicSalePrice = publicSaleMintPrice_;
  }

  function publicSaleMint(uint256 quantity) external payable callerIsUser {
    require(
      _saleConfig.publicSalePrice != 0,
      'PublicSale price is not settled.'
    );
    require(
      _saleConfig.publicSaleStartTimestamp != 0,
      'PublicSale start date is not settled.'
    );
    require(
      block.timestamp >= _saleConfig.publicSaleStartTimestamp,
      'PublicSale has not started.'
    );
    require(
      _saleConfig.publicSaleFinishTimestamp == 0 ||
        block.timestamp < _saleConfig.publicSaleFinishTimestamp,
      'PublicSale has finished.'
    );

    // check quantity
    require(
      quantity <= _saleMintMaxBatchSize,
      'Quantity must be less than max batch size.'
    );
    _presaleClaimedCountPerAddress[msg.sender] += quantity;
    // check inventory
    require(
      _saleMintedCount.current() + quantity <= _saleMintInventory,
      'Insufficient inventory.'
    );
    // check msg.value
    require(
      msg.value >= _saleConfig.publicSalePrice * quantity,
      'Insufficient ETH.'
    );

    // mint
    for (uint256 i = 0; i < quantity; i++) {
      _saleMintedCount.increment();
      uint256 count = _saleMintedCount.current();
      uint256 id = devMintInventory() + count;
      _mint(msg.sender, id);
    }

    // refund if msg.value is too large
    if (msg.value > _saleConfig.publicSalePrice * quantity) {
      payable(msg.sender).transfer(
        msg.value - _saleConfig.publicSalePrice * quantity
      );
    }

    emit SaleMint(msg.sender, _saleMintedCount.current());
  }

  function devMintAfterSale(uint256 quantity) external onlyOwner {
    require(
      _saleConfig.presaleFinishTimestamp != 0 &&
        block.timestamp >= _saleConfig.presaleFinishTimestamp,
      'Presale has not finished.'
    );
    require(
      _saleConfig.publicSaleFinishTimestamp != 0 &&
        block.timestamp >= _saleConfig.publicSaleFinishTimestamp,
      'Public has not finished.'
    );

    // check claimable count
    require(quantity <= 50, 'afterSaleDevMint maxBatchSize is 50.');

    // check inventory
    require(
      _saleMintedCount.current() + quantity <= _saleMintInventory,
      'Insufficient inventory.'
    );

    address addr = devMintAddress_();
    require(addr != address(0), 'devMint address is not set');

    // mint
    for (uint256 i = 0; i < quantity; i++) {
      _saleMintedCount.increment();
      uint256 count = _saleMintedCount.current();
      _mint(addr, devMintInventory() + count);
    }

    emit SaleMint(addr, _saleMintedCount.current());
  }
}