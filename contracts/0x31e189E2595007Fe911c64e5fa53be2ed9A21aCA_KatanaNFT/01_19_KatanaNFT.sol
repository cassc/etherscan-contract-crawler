// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@grexie/signable/contracts/Signable.sol';
import './Ownable.sol';
import './Withdrawable.sol';

contract KatanaNFT is
  ERC721,
  ERC721Enumerable,
  Pausable,
  Ownable,
  Signable,
  Withdrawable
{
  using Counters for Counters.Counter;
  using Strings for uint256;

  address private _signer;

  Counters.Counter private _tokenIdCounter;

  struct ConstructorParams {
    address signer;
    address owner;
    string name;
    string symbol;
    uint256 maxSupply;
    uint256 price;
    uint256 maxMintAmount;
    uint256 whitelistSaleTime;
    uint256 publicSaleTime;
    string hiddenBaseURI;
    string hiddenExtension;
    string revealBaseURI;
    string revealExtension;
    bool revealed;
    bool transfersPaused;
  }

  struct Whitelist {
    address account;
    uint256 allocation;
    uint256 price;
  }

  string private _hiddenBaseURI;
  string private _hiddenExtension;
  string private _revealBaseURI;
  string private _revealExtension;
  bool private _revealed;

  uint256 private _maxSupply;
  uint256 private _price;
  uint256 private _maxMintAmount;

  uint256 private _whitelistSaleTime;
  uint256 private _publicSaleTime;

  bool private _transfersPaused;

  mapping(address => uint256) private _whitelist;

  constructor(ConstructorParams memory params)
    ERC721(params.name, params.symbol)
    Ownable(params.owner)
  {
    _signer = params.signer;
    _maxSupply = params.maxSupply;
    _price = params.price;
    _maxMintAmount = params.maxMintAmount;
    _whitelistSaleTime = params.whitelistSaleTime;
    _publicSaleTime = params.publicSaleTime;
    _hiddenBaseURI = params.hiddenBaseURI;
    _hiddenExtension = params.hiddenExtension;
    _revealBaseURI = params.revealBaseURI;
    _revealExtension = params.revealExtension;
    _revealed = params.revealed;
    _transfersPaused = params.transfersPaused;

    _tokenIdCounter.increment();
  }

  function signer() public view virtual override(ISignable) returns (address) {
    return _signer;
  }

  function setSigner(address signer_) external onlyOwner {
    _signer = signer_;
  }

  function maxSupply() public view returns (uint256) {
    return _maxSupply;
  }

  function price() public view returns (uint256) {
    return _price;
  }

  function maxMintAmount() public view returns (uint256) {
    return _maxMintAmount;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(uint256 amount) external payable whenNotPaused {
    require(amount >= 0, 'KatanaNFT: token amount is zero');
    require(
      balanceOf(msg.sender) + amount <= _maxMintAmount,
      'KatanaNFT: exceeds max mint limit'
    );
    require(_price * amount == msg.value, 'KatanaNFT: Invalid eth amount');
    require(
      totalSupply() + amount <= _maxSupply,
      'KatanaNFT: exceeds max supply'
    );
    if (block.timestamp < _publicSaleTime) {
      revert("KatanaNFT: public sale hasn't started");
    }

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender);
    }
  }

  function mintWhitelist(
    uint256 amount,
    Whitelist calldata whitelist,
    Signature calldata signature
  )
    external
    payable
    whenNotPaused
    verifySignature(
      abi.encode(this.mintWhitelist.selector, amount, whitelist),
      signature
    )
  {
    require(
      msg.sender == whitelist.account,
      'KatanaNFT: sender not whitelisted'
    );
    require(amount >= 0, 'KatanaNFT: token amount is zero');
    require(
      _whitelist[msg.sender] + amount <= whitelist.allocation,
      'KatanaNFT: exceeds max mint limit'
    );
    require(
      whitelist.price * amount == msg.value,
      'KatanaNFT: invalid eth amount'
    );
    require(
      totalSupply() + amount <= _maxSupply,
      'KatanaNFT: exceeds max supply'
    );
    if (block.timestamp < _whitelistSaleTime) {
      revert("KatanaNFT: whitelist sale hasn't started");
    }

    _whitelist[msg.sender] += amount;
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender);
    }
  }

  function mintOwner(address to, uint256 amount) external onlyOwner {
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to);
    }
  }

  function _safeMint(address to) internal {
    uint256 tokenId = _tokenIdCounter.current();
    require(tokenId <= _maxSupply, 'KatanaNFT: exceeds max supply');

    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );

    if (_revealed) {
      return
        string(
          abi.encodePacked(_revealBaseURI, tokenId.toString(), _revealExtension)
        );
    } else {
      return
        string(
          abi.encodePacked(_hiddenBaseURI, tokenId.toString(), _hiddenExtension)
        );
    }
  }

  function transfersPaused() public view returns (bool) {
    return _transfersPaused;
  }

  function setTransfersPaused(bool transfersPaused_) external onlyOwner {
    _transfersPaused = transfersPaused_;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    require(
      !_transfersPaused || from == address(0),
      'KatanaNFT: transfers are paused'
    );

    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return
      ERC721.supportsInterface(interfaceId) ||
      ERC721Enumerable.supportsInterface(interfaceId);
  }

  function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    _maxSupply = maxSupply_;
  }

  function setPrice(uint256 price_) external onlyOwner {
    _price = price_;
  }

  function setMaxMintAmount(uint256 maxMintAmount_) external onlyOwner {
    _maxMintAmount = maxMintAmount_;
  }

  function setHiddenURI(string memory baseURI, string memory extension)
    external
    onlyOwner
  {
    _hiddenBaseURI = baseURI;
    _hiddenExtension = extension;
  }

  function reveal(string memory baseURI, string memory extension)
    external
    onlyOwner
  {
    _revealBaseURI = baseURI;
    _revealExtension = extension;
    _revealed = true;
  }

  function hide() external onlyOwner {
    _revealBaseURI = '';
    _revealExtension = '';
    _revealed = false;
  }

  function whitelistSaleTime() public view returns (uint256) {
    return _whitelistSaleTime;
  }

  function setWhitelistSaleTime(uint256 whitelistSaleTime_) external onlyOwner {
    _whitelistSaleTime = whitelistSaleTime_;
  }

  function publicSaleTime() public view returns (uint256) {
    return _publicSaleTime;
  }

  function setPublicSaleTime(uint256 publicSaleTime_) external onlyOwner {
    _publicSaleTime = publicSaleTime_;
  }
}