// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Marketplace is IERC721Receiver, Ownable, Pausable, ReentrancyGuard {

  struct Order {
    bytes32 id; // Order ID
    address seller; // Owner of the NFT
    address currencyAddress; // Currency
    address nftAddress; // NFT registry address
    uint256 price; // Price (in wei) for the published item
  }
  mapping(address => bool) public currencyAddresses;
  mapping(address => bool) public nftAddresses;
  // From ERC721 registry assetId to Order (to avoid asset collision)
  mapping (address => mapping(uint256 => Order)) public orderByAssetId;
  address feeAddress;

  uint256 public ownerCutPerMillion;
  uint256 public publicationFeeInWei;

  bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);

  // EVENTS
  event OrderCreated(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress,
    address currencyAddress,
    uint256 priceInWei
  );
  event OrderSuccessful(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress,
    address currencyAddress,
    uint256 priceInWei,
    address indexed buyer
  );
  event OrderCancelled(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress
  );
  event ChangeFeeAddress(address indexed feeAddress);
  event ChangedOwnerCutPerMillion(uint256 ownerCutPerMillion);
  event AddNFT(address nftAddress);
  event RemoveNFT(address nftAddress);
  event AddCurrency(address currencyAddress);
  event RemoveCurrency(address currencyAddress);

  using SafeMath for uint256;
  using Address for address;

  constructor (
    uint256 _ownerCutPerMillion
  )
  {
    // Fee init
    setOwnerCutPerMillion(_ownerCutPerMillion);
    setFeeAddress(msg.sender);
  }

  function setFeeAddress(address _newFeeAddress) public onlyOwner {
    feeAddress = _newFeeAddress;
    emit ChangeFeeAddress(_newFeeAddress);
  }

  function addCurrency(address _currency) external onlyOwner {
    require(
      _currency.isContract(),
      "Marketplace: the currency address must be a deployed contract"
    );
    require(!currencyAddresses[_currency], "Marketplace:: already added");
    currencyAddresses[_currency] = true;
    emit AddCurrency(_currency);
  }

  function removeCurrency(address _currency) external onlyOwner {
    require(currencyAddresses[_currency], "Marketplace:: not existing");
    delete currencyAddresses[_currency];
    emit RemoveCurrency(_currency);
  }

  function addNFT(address _nftAddress) external onlyOwner {
    _requireERC721(_nftAddress);
    require(!nftAddresses[_nftAddress], "Marketplace: already added");
    nftAddresses[_nftAddress] = true;
    emit AddNFT(_nftAddress);
  }

  function removeNFT(address _nftAddress) external onlyOwner {
    require(nftAddresses[_nftAddress], "Marketplace: not existing");
    delete nftAddresses[_nftAddress];
    emit RemoveNFT(_nftAddress);
  }

  function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) public onlyOwner {
    require(_ownerCutPerMillion <= 1000000, "The owner cut should be between 0 and 999,999");

    ownerCutPerMillion = _ownerCutPerMillion;
    emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
  }

  function createOrder(
    address nftAddress,
    address currencyAddress,
    uint256 assetId,
    uint256 priceInWei
  )
    public whenNotPaused nonReentrant
  {
    _createOrder(
      nftAddress,
      currencyAddress,
      assetId,
      priceInWei
    );
  }

  function cancelOrder(address nftAddress, uint256 assetId) public whenNotPaused {
    _cancelOrder(nftAddress, assetId);
  }

  function executeOrder(
    address nftAddress,
    uint256 assetId,
    uint256 priceInWei
  )
   public whenNotPaused nonReentrant
  {
    _executeOrder(
      nftAddress,
      assetId,
      priceInWei
    );
  }

  function _createOrder(
    address nftAddress,
    address currencyAddress,
    uint256 assetId,
    uint256 priceInWei
  )
    internal
  {
    _requireERC721(nftAddress);
    require(nftAddresses[nftAddress], "Marketplace: NFT is not support");
    require(
      currencyAddresses[currencyAddress],
      "Marketplace: Currency is not support"
    );
    address sender = _msgSender();

    // Check if there's a publication fee and
    // transfer the amount to marketplace owner
    if (publicationFeeInWei > 0) {
      require(msg.value == publicationFeeInWei, "Should be equals publication fee");
    }

    IERC721 nftRegistry = IERC721(nftAddress);
    address assetOwner = nftRegistry.ownerOf(assetId);

    require(sender == assetOwner, "Only the owner can create orders");

    // NOTE: transfer to this contract
    nftRegistry.safeTransferFrom(sender, address(this), assetId);

    require(priceInWei > 0, "Price should be bigger than 0");

    bytes32 orderId = keccak256(
      abi.encodePacked(
        block.timestamp,
        assetOwner,
        assetId,
        nftAddress,
        currencyAddress,
        priceInWei
      )
    );

    orderByAssetId[nftAddress][assetId] = Order({
      id: orderId,
      seller: assetOwner,
      nftAddress: nftAddress,
      currencyAddress: currencyAddress,
      price: priceInWei
    });

    emit OrderCreated(
      orderId,
      assetId,
      assetOwner,
      nftAddress,
      currencyAddress,
      priceInWei
    );
  }

  function _cancelOrder(address nftAddress, uint256 assetId) internal {
    address sender = _msgSender();
    Order memory order = orderByAssetId[nftAddress][assetId];

    require(order.id != 0, "Asset not published");
    require(order.seller == sender || sender == owner(), "Unauthorized user");

    bytes32 orderId = order.id;
    address orderSeller = order.seller;
    delete orderByAssetId[nftAddress][assetId];

    IERC721 _nftContract = IERC721(nftAddress);
    _nftContract.safeTransferFrom(address(this), orderSeller, assetId);

    emit OrderCancelled(
      orderId, assetId, orderSeller, nftAddress
    );
  }

  function _executeOrder(
    address nftAddress,
    uint256 assetId,
    uint256 priceInWei
  )
   internal
  {
    _requireERC721(nftAddress);
    require(nftAddresses[nftAddress], "Marketplace: NFT is not support");
    address sender = _msgSender();

    IERC721 nftRegistry = IERC721(nftAddress);

    Order memory order = orderByAssetId[nftAddress][assetId];

    require(order.id != 0, "Marketplace: Asset not published");

    address seller = order.seller;

    require(seller != address(0), "Marketplace: Invalid address");
    require(seller != sender, "Marketplace: Unauthorized user");
    require(order.price == priceInWei, "Marketplace: The price is not correct");

    bytes32 orderId = order.id;
    delete orderByAssetId[nftAddress][assetId];
    uint saleShareAmount = 0;
    address currencyAddress = order.currencyAddress;
    IERC20 currency = IERC20(currencyAddress);

    if (ownerCutPerMillion > 0) {
      // Calculate sale share
      saleShareAmount = priceInWei.mul(ownerCutPerMillion).div(1000000);

      // Transfer share amount to marketplace owner
      require(
        currency.transferFrom(msg.sender, feeAddress, saleShareAmount),
        "Marketplace: transfering the cut the the marketplace owner failed"
      );
    }

    // Transfer sale amount to seller
    require(
      currency.transferFrom(
        sender,
        seller,
          priceInWei - saleShareAmount
      ),
      "Marketplace: transfering the sale amount to the seller failed"
    );

    // Transfer asset owner
    nftRegistry.safeTransferFrom(
      address(this),
      sender,
      assetId
    );

    emit OrderSuccessful(
      orderId,
      assetId,
      seller,
      nftAddress,
      currencyAddress,
      priceInWei,
      sender
    );
  }

  function _requireERC721(address nftAddress) internal view {
    require(nftAddress.isContract(), "The NFT Address should be a contract");

    IERC721 nftRegistry = IERC721(nftAddress);
    require(
      nftRegistry.supportsInterface(ERC721_Interface),
      "The NFT contract has an invalid ERC721 implementation"
    );
  }

  function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function getOrder(
    address _nftAddress,
    uint256 _assetId
  )
  public
  view
  returns (
    bytes32 id,
    address seller,
    address nftAddress,
    address currencyAddress,
    uint256 price
  )
  {
    Order memory _order = orderByAssetId[_nftAddress][_assetId];

    if(_order.id != 0)
      return (
      _order.id,
      _order.seller,
      _order.nftAddress,
      _order.currencyAddress,
      _order.price
      );
  }

  function pause() public onlyOwner whenNotPaused {
    _pause();
  }

  function unpause() public onlyOwner whenPaused {
    _unpause();
  }
}