// SPDX-License-Identifier: MIT

// ProtonB.sol -- Part of the Charged Particles Protocol
// Copyright (c) 2021 Firma Lux, Inc. <https://charged.fi>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../lib/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IBaseProton.sol";
import "../lib/TokenInfo.sol";
import "../lib/BlackholePrevention.sol";
import "../lib/RelayRecipient.sol";

/// @title Base Proton Contract for Charged Particles compatible ERC721 NFTs
/// @dev MUST NOT be Upgradeable, as Upgradeable NFTs are incompatible with Charged Particles.
contract BaseProton is 
  IBaseProton, 
  ERC721, 
  Ownable, 
  RelayRecipient, 
  ReentrancyGuard, 
  BlackholePrevention 
{
  using SafeMath for uint256;
  using TokenInfo for address payable;
  using Counters for Counters.Counter;

  event Received(address, uint);

  uint256 constant internal PERCENTAGE_SCALE = 1e4;   // 10000  (100%)

  /// @dev Sequential Token IDs storage
  Counters.Counter internal _tokenIds;

  /// @dev NFT Token Creator settings
  mapping (uint256 => address) internal _tokenCreator;
  mapping (uint256 => uint256) internal _tokenCreatorRoyaltiesPct;
  mapping (uint256 => address) internal _tokenCreatorRoyaltiesRedirect;
  mapping (address => uint256) internal _tokenCreatorClaimableRoyalties;

  /// @dev NFT Token Sale settings
  mapping (uint256 => uint256) internal _tokenSalePrice;
  mapping (uint256 => uint256) internal _tokenLastSellPrice;

  /// @dev Whether of not the Contract is Paused
  bool internal _paused;


  /***********************************|
  |          Initialization           |
  |__________________________________*/

  /// @dev Inherit from ERC721 standard
  constructor(string memory _name, string memory _symbol) public ERC721(_name, _symbol) {}


  /***********************************|
  |              Public               |
  |__________________________________*/
  receive() external payable virtual {
    emit Received(msg.sender, msg.value);
  }

  /// Returns the Creator address of an NFT by Token ID
  /// @param tokenId The ID of the NFT Token to lookup
  /// @return The address of the Creator account
  function creatorOf(uint256 tokenId) external view virtual override returns (address) {
    return _tokenCreator[tokenId];
  }

  /// Returns the Sale Price of an NFT by Token ID
  /// @param tokenId The ID of the NFT Token to lookup
  /// @return The sale price of the NFT
  function getSalePrice(uint256 tokenId) external view virtual override returns (uint256) {
    return _tokenSalePrice[tokenId];
  }

  /// Returns the Last Sale Price of an NFT by Token ID
  /// @notice This is used to determine any increase in sale price used in royalties calculations
  /// @param tokenId The ID of the NFT Token to lookup
  /// @return The last sale price of the NFT
  function getLastSellPrice(uint256 tokenId) external view virtual override returns (uint256) {
    return _tokenLastSellPrice[tokenId];
  }

  /// Returns the Claimable Royalties for the NFT Creator
  /// @param account The address of the Creator account to lookup
  /// @return The amount of earned royalties for the creator account
  function getCreatorRoyalties(address account) external view virtual override returns (uint256) {
    return _tokenCreatorClaimableRoyalties[account];
  }

  /// Returns the Percentage of Royalties reserved for the NFT Creator
  /// @param tokenId The ID of the NFT Token to lookup
  /// @return The percentage of royalties reserved for the creator
  function getCreatorRoyaltiesPct(uint256 tokenId) external view virtual override returns (uint256) {
    return _tokenCreatorRoyaltiesPct[tokenId];
  }

  /// Returns the Receiving address of the Creator Royalties (or Creator if not set)
  /// @dev Returns the creator address if a receiving address has not been configured
  /// @param tokenId The ID of the NFT Token to lookup
  /// @return The Receiving address of the Creator Royalties
  function getCreatorRoyaltiesReceiver(uint256 tokenId) external view virtual override returns (address) {
    return _creatorRoyaltiesReceiver(tokenId);
  }

  /// Allows an NFT Creator to Claim any Royalties that have been earned from NFT sales
  /// @dev Must be called by the royalties receiver account (not neccessarily the creator)
  /// @return The amout of creator royalties claimed
  function claimCreatorRoyalties()
    external
    virtual
    override
    nonReentrant
    whenNotPaused
    returns (uint256)
  {
    return _claimCreatorRoyalties(_msgSender());
  }


  /***********************************|
  |       Create Single Protons       |
  |__________________________________*/

  /// Creates a Basic NFT with no Royalties and no initial Sale Price
  /// @dev Royalties and Sale Price can be configured later
  /// @param creator The address of the NFT Creator (can be different from the caller)
  /// @param receiver The receiving address of the NFT (can be different from the caller)
  /// @param tokenMetaUri The unique metadata URI for the NFT
  /// @return newTokenId The newly minted NFT Token ID
  function createProton(
    address creator,
    address receiver,
    string memory tokenMetaUri
  )
    external
    virtual
    override
    whenNotPaused
    returns (uint256 newTokenId)
  {
    newTokenId = _createProton(
      creator,
      receiver,
      tokenMetaUri,
      0, // royaltiesPercent
      0  // salePrice
    );
  }


  /***********************************|
  |      Create Multiple Protons      |
  |__________________________________*/

  function createProtons(
    address creator,
    address receiver,
    string[] calldata tokenMetaUris
  )
    external
    virtual
    override
    whenNotPaused
    returns (bool)
  {
    _createProtons(
      creator,
      receiver,
      0,  // royaltiesPercent
      tokenMetaUris
    );
    return true;
  }

  function createProtonsForSale(
    address creator,
    address receiver,
    uint256 royaltiesPercent,
    string[] calldata tokenMetaUris,
    uint256[] calldata salePrices
  )
    external
    virtual
    override
    whenNotPaused
    returns (bool)
  {
    _createProtonsForSale(
      creator,
      receiver,
      royaltiesPercent,
      tokenMetaUris,
      salePrices
    );
    return true;
  }


  /***********************************|
  |           Buy Protons             |
  |__________________________________*/

  function buyProton(uint256 tokenId, uint256 gasLimit)
    external
    payable
    virtual
    override
    nonReentrant
    whenNotPaused
    returns (bool)
  {
    _buyProton(tokenId, gasLimit);
    return true;
  }

  /***********************************|
  |     Only Token Creator/Owner      |
  |__________________________________*/

  function setSalePrice(uint256 tokenId, uint256 salePrice)
    external
    virtual
    override
    whenNotPaused
    onlyTokenOwnerOrApproved(tokenId)
  {
    _setSalePrice(tokenId, salePrice);
  }

  function setRoyaltiesPct(uint256 tokenId, uint256 royaltiesPct)
    external
    virtual
    override
    whenNotPaused
    onlyTokenCreator(tokenId)
    onlyTokenOwnerOrApproved(tokenId)
  {
    _setRoyaltiesPct(tokenId, royaltiesPct);
  }

  function setCreatorRoyaltiesReceiver(uint256 tokenId, address receiver)
    external
    virtual
    override
    whenNotPaused
    onlyTokenCreator(tokenId)
  {
    _tokenCreatorRoyaltiesRedirect[tokenId] = receiver;
  }


  /***********************************|
  |          Only Admin/DAO           |
  |__________________________________*/

  function setPausedState(bool state) external virtual onlyOwner {
    _paused = state;
    emit PausedStateSet(state);
  }

  function setTrustedForwarder(address _trustedForwarder) external virtual onlyOwner {
    trustedForwarder = _trustedForwarder;
  }


  /***********************************|
  |          Only Admin/DAO           |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external onlyOwner {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external onlyOwner {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external onlyOwner {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }


  /***********************************|
  |         Private Functions         |
  |__________________________________*/

  function _setSalePrice(uint256 tokenId, uint256 salePrice) internal virtual {
    _tokenSalePrice[tokenId] = salePrice;
    emit SalePriceSet(tokenId, salePrice);
  }

  function _setRoyaltiesPct(uint256 tokenId, uint256 royaltiesPct) internal virtual {
    require(royaltiesPct <= PERCENTAGE_SCALE, "PRT:E-421");
    _tokenCreatorRoyaltiesPct[tokenId] = royaltiesPct;
    emit CreatorRoyaltiesSet(tokenId, royaltiesPct);
  }

  function _creatorRoyaltiesReceiver(uint256 tokenId) internal view virtual returns (address) {
    address receiver = _tokenCreatorRoyaltiesRedirect[tokenId];
    if (receiver == address(0x0)) {
      receiver = _tokenCreator[tokenId];
    }
    return receiver;
  }

  function _createProton(
    address creator,
    address receiver,
    string memory tokenMetaUri,
    uint256 royaltiesPercent,
    uint256 salePrice
  )
    internal
    virtual
    returns (uint256 newTokenId)
  {
    _tokenIds.increment();

    newTokenId = _tokenIds.current();
    _safeMint(receiver, newTokenId, "");
    _tokenCreator[newTokenId] = creator;

    _setTokenURI(newTokenId, tokenMetaUri);

    if (royaltiesPercent > 0) {
      _setRoyaltiesPct(newTokenId, royaltiesPercent);
    }

    if (salePrice > 0) {
      _setSalePrice(newTokenId, salePrice);
    }
  }

  function _createProtons(
    address creator,
    address receiver,
    uint256 royaltiesPercent,
    string[] calldata tokenMetaUris
  )
    internal
    virtual
  {
    uint256 count = tokenMetaUris.length;
    for (uint256 i; i < count; i++) {
      _createProton(creator, receiver, tokenMetaUris[i], royaltiesPercent, 0);
    }
  }

  function _createProtonsForSale(
    address creator,
    address receiver,
    uint256 royaltiesPercent,
    string[] calldata tokenMetaUris,
    uint256[] calldata salePrices
  )
    internal
    virtual
  {
    require(tokenMetaUris.length == salePrices.length, "PRT:E-202");

    uint256 count = tokenMetaUris.length;
    for (uint256 i; i < count; i++) {
      _createProton(creator, receiver, tokenMetaUris[i], royaltiesPercent, salePrices[i]);
    }
  }

  function _buyProton(uint256 _tokenId, uint256 _gasLimit)
    internal
    virtual
    returns (
      address contractAddress,
      uint256 tokenId,
      address oldOwner,
      address newOwner,
      uint256 salePrice,
      address royaltiesReceiver,
      uint256 creatorAmount
    )
  {
    contractAddress = address(this);
    tokenId = _tokenId;
    salePrice = _tokenSalePrice[_tokenId];
    require(salePrice > 0, "PRT:E-416");
    require(msg.value >= salePrice, "PRT:E-414");

    uint256 ownerAmount = salePrice;
    creatorAmount;
    oldOwner = ownerOf(_tokenId);
    newOwner = _msgSender();

    // Creator Royalties
    royaltiesReceiver = _creatorRoyaltiesReceiver(_tokenId);
    uint256 royaltiesPct = _tokenCreatorRoyaltiesPct[_tokenId];
    uint256 lastSellPrice = _tokenLastSellPrice[_tokenId];
    if (royaltiesPct > 0 && lastSellPrice > 0 && salePrice > lastSellPrice) {
      creatorAmount = (salePrice - lastSellPrice).mul(royaltiesPct).div(PERCENTAGE_SCALE);
      ownerAmount = ownerAmount.sub(creatorAmount);
    }
    _tokenLastSellPrice[_tokenId] = salePrice;

    // Reserve Royalties for Creator
    if (creatorAmount > 0) {
      _tokenCreatorClaimableRoyalties[royaltiesReceiver] = _tokenCreatorClaimableRoyalties[royaltiesReceiver].add(creatorAmount);
    }

    // Transfer Token
    _transfer(oldOwner, newOwner, _tokenId);

    // Transfer Payment
    if (ownerAmount > 0) {
      payable(oldOwner).sendValue(ownerAmount, _gasLimit);
    }

    emit ProtonSold(_tokenId, oldOwner, newOwner, salePrice, royaltiesReceiver, creatorAmount);

    _refundOverpayment(salePrice, _gasLimit);
  }

  /**
    * @dev Pays out the Creator Royalties of the calling account
    * @param receiver  The receiver of the claimable royalties
    * @return          The amount of Creator Royalties claimed
    */
  function _claimCreatorRoyalties(address receiver) internal virtual returns (uint256) {
    uint256 claimableAmount = _tokenCreatorClaimableRoyalties[receiver];
    require(claimableAmount > 0, "PRT:E-411");

    delete _tokenCreatorClaimableRoyalties[receiver];
    payable(receiver).sendValue(claimableAmount, 0);

    emit RoyaltiesClaimed(receiver, claimableAmount);
  }

  /**
    * @dev Collects the Required Asset Token from the users wallet
    * @param from         The owner address to collect the Assets from
    * @param assetAmount  The Amount of Asset Tokens to Collect
    */
  function _collectAssetToken(address from, address assetToken, uint256 assetAmount) internal virtual {
    uint256 _userAssetBalance = IERC20(assetToken).balanceOf(from);
    require(assetAmount <= _userAssetBalance, "PRT:E-411");
    // Be sure to Approve this Contract to transfer your Asset Token
    require(IERC20(assetToken).transferFrom(from, address(this), assetAmount), "PRT:E-401");
  }

  function _refundOverpayment(uint256 threshold, uint256 gasLimit) internal virtual {
    uint256 overage = msg.value.sub(threshold);
    if (overage > 0) {
      payable(_msgSender()).sendValue(overage, gasLimit);
    }
  }

  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    _tokenSalePrice[tokenId] = 0;
    super._transfer(from, to, tokenId);
  }


  /***********************************|
  |          GSN/MetaTx Relay         |
  |__________________________________*/

  /// @dev See {BaseRelayRecipient-_msgSender}.
  function _msgSender()
    internal
    view
    virtual
    override(BaseRelayRecipient, Context)
    returns (address payable)
  {
    return BaseRelayRecipient._msgSender();
  }

  /// @dev See {BaseRelayRecipient-_msgData}.
  function _msgData()
    internal
    view
    virtual
    override(BaseRelayRecipient, Context)
    returns (bytes memory)
  {
    return BaseRelayRecipient._msgData();
  }


  /***********************************|
  |             Modifiers             |
  |__________________________________*/

  modifier whenNotPaused() {
      require(!_paused, "PRT:E-101");
      _;
  }

  modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "PRT:E-105");
    _;
  }

  modifier onlyTokenCreator(uint256 tokenId) {
    require(_tokenCreator[tokenId] == _msgSender(), "PRT:E-104");
    _;
  }
}