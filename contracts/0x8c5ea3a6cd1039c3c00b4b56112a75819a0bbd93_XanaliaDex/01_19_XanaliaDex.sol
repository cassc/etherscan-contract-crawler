//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/IXanaliaDex.sol";
import "./interfaces/IMarketDex.sol";
import "./interfaces/IAuctionDex.sol";
import "./interfaces/IOfferDex.sol";
import "./interfaces/IXanaliaNFT.sol";
import "./interfaces/IXanaliaAddressesStorage.sol";
import "./interfaces/ICollectionDeployer.sol";
import "./interfaces/IDexProxy.sol";

/**
 * :> Xanalia Dex
 * :> This contract is a main dex of xanalia's system, responsible of creating & tracking collections, collectibles of user.
 */
contract Manager is Initializable, OwnableUpgradeable, PausableUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	using AddressUpgradeable for address payable;

	IXanaliaAddressesStorage public xanaliaAddressesStorage;

	uint256 public constant BASE_DENOMINATOR = 10_000;
	address public xanaliaAddressesStorageAddress;
	uint256 public platformFee;
	uint256 public collectionCount;
	bool internal processing;

	mapping(uint256 => address) public collectionAddresses;
	mapping(address => address[]) public collections;
	mapping(address => bool) public isUserCollection;
	mapping(address => bool) public isUserWhitelisted;
	mapping(address => bool) public isWhitelistApprover;
	mapping(address => bool) public paymentMethod;

	

	// events collection
	event CollectionCreated(address indexed creator, address indexed collection, string name, string symbol);
	event CollectibleCreated(address indexed owner, uint256 indexed collectibleId);

	// events fixed price
	event OrderCreated(uint256 _orderId, address _collectionAddress, uint256 _tokenId, uint256 _price);
	event Buy(uint256 _itemId, address _paymentToken, uint256 _paymentAmount);
	event OrderCancelled(uint256 indexed _orderId);
	event OrderEdited(uint256 indexed _orderId, uint256 indexed _oldOrderId, uint256 _price);

	// events auction
	event AuctionCreated(uint256 _auctionId, address _collectionAddress, uint256 _tokenId);
	event BidAuctionCreated(
		uint256 indexed _bidAuctionId,
		address _collectionAddress,
		uint256 indexed _tokenId,
		uint256 _price,
		address _paymentToken
	);
	event AuctionCanceled(uint256 indexed _auctionId);
	event BidAuctionCanceled(uint256 indexed _bidAuctionId);
	event BidAuctionClaimed(uint256 indexed _bidAuctionId);
	event AuctionReclaimed(uint256 indexed _auctionId);

	// events offer
	event OfferCreated(
		uint256 indexed _offerId,
		address _collectionAddress,
		uint256 indexed _tokenId,
		uint256 _price,
		address _paymentToken
	);
	event AcceptOffer(uint256 indexed _offerId);
	event OfferCancelled(uint256 indexed _offerId);

	// events setting
	event PlatformFeeChanged(uint256 _platformFee);
	event PaymentMethodChanged(address _paymentToken, bool _accepted);
	event FundsWithdrawed(address _collectionAddress, uint256 _amount);

	// events list
	event WhitelistAddressSet(address indexed admin, uint256 indexed numberAddress);
	event WhitelistApproverSet(address indexed approver, bool indexed status);

	function initialize(uint256 _platformFee, address _xanaliaAddressesStorage) public virtual initializer {
		PausableUpgradeable.__Pausable_init();
		OwnableUpgradeable.__Ownable_init();
		platformFee = _platformFee;
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
		xanaliaAddressesStorageAddress = _xanaliaAddressesStorage;
		processing = false;
	}

	receive() external payable {}

	modifier onlyNotProcessing() {
		require(!processing, "Invalid processing");
		processing = true;
		_;
		processing = false;
	}

	modifier onlyApprover() {
		require(isWhitelistApprover[msg.sender], "Not whitelist approver");
		_;
	}

	

	function pause() public onlyOwner {
		_pause();
	}

	function unPause() public onlyOwner {
		_unpause();
	}

	/**
	 * @notice withdrawFunds
	 */
	function withdrawFunds(address payable _beneficiary, address _tokenAddress) external onlyOwner whenPaused {
		uint256 _withdrawAmount;
		if (_tokenAddress == address(0)) {
			_beneficiary.transfer(address(this).balance);
			_withdrawAmount = address(this).balance;
		} else {
			_withdrawAmount = IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
			IERC20Upgradeable(_tokenAddress).safeTransfer(_beneficiary, _withdrawAmount);
		}
		emit FundsWithdrawed(_tokenAddress, _withdrawAmount);
	}

	function setApproveForAllERC721(address _collectionAddress, address _spender) external {
		IERC721Upgradeable(_collectionAddress).setApprovalForAll(_spender, true);
	}

	function setPlatformFee(uint256 _platformFee) external onlyOwner {
		require(_platformFee <= BASE_DENOMINATOR, "Invalid platform fee");
		platformFee = _platformFee;
		emit PlatformFeeChanged(_platformFee);
	}

	function setPaymentMethod(address _token, bool _status) external onlyOwner returns (bool) {
		require(paymentMethod[_token] != _status, "This status already set");
		paymentMethod[_token] = _status;
		emit PaymentMethodChanged(_token, _status);
		return true;
	}

	/**
	@notice Set approver for whitelist
	@param _user address of approver
	@param _status status of address
	*/
	function setWhitelistApproverRole(address _user, bool _status) external onlyOwner {
		require(isWhitelistApprover[_user] != _status, "This status aldready set");
		isWhitelistApprover[_user] = _status;
		emit WhitelistApproverSet(_user, _status);
	}

	function sendTokenToNewContract(address _token, address _newContract) external onlyOwner whenPaused {
		require(_newContract != address(0), "Invalid-address");
		uint256 amount;
		if (_token == address(0)) {
			amount = address(this).balance;
			payable(_newContract).sendValue(amount);
		} else {
			amount = IERC20Upgradeable(_token).balanceOf(address(this));
			IERC20Upgradeable(_token).safeTransfer(_newContract, amount);
		}

		emit FundsWithdrawed(_token, amount);
	}

	function setAddressesStorage(address _xanaliaAddressesStorage) external onlyOwner {
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
		xanaliaAddressesStorageAddress = _xanaliaAddressesStorage;
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes memory
	) public pure returns (bytes4) {
		return this.onERC721Received.selector;
	}

	function _getCreator(address _collectionAddress, uint256 _tokenId) internal view returns (address) {
		try IXanaliaNFT(_collectionAddress).getCreator(_tokenId) returns (address _creator) {
			return _creator;
		} catch {
			try IXanaliaNFT(_collectionAddress).getAuthor(_tokenId) returns (address _creator) {
				return _creator;
			} catch {}
		}
		return address(0);
	}

	function _getRoyaltyFee(address _collectionAddress, uint256 _tokenId) internal view returns (uint256) {
		try IXanaliaNFT(_collectionAddress).getRoyaltyFee(_tokenId) returns (uint256 _royaltyFee) {
			return _royaltyFee;
		} catch {
			IDexProxy dexProxy = IDexProxy(xanaliaAddressesStorage.oldXanaliaDexProxy());
			(, uint256 _royaltyFee, ) = dexProxy.getPercentages(_tokenId, _collectionAddress);
			return _royaltyFee * 10; // Old xanalia use base 1000, this contract use base 10_000
		}
	}

	function _paid(
		address _token,
		address _to,
		uint256 _amount
	) internal {
		if (_token == address(0)) {
			payable(_to).sendValue(_amount);
		} else {
			IERC20Upgradeable(_token).safeTransfer(_to, _amount);
		}
	}

	/**
	 * @dev Matching order mechanism for buy NFT and accept bid
	 * @param _buyer is address of buyer
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 * @param _orderOwner address of user who created auction or order
	 * @param _collectionAddress is address of collection that store NFT
	 * @param _tokenId is id of NFT
	 * @param _price is amount token to buy item
	 */

	function _match(
		address _buyer,
		address _paymentToken,
		address _orderOwner,
		address _collectionAddress,
		uint256 _tokenId,
		uint256 _price
	) internal returns (bool) {
		address payable creator = payable(_getCreator(_collectionAddress, _tokenId));

		uint256 royaltyFee = _getRoyaltyFee(_collectionAddress, _tokenId);

		uint256 _totalEarnings = _price;

		if (royaltyFee > 0 || platformFee > 0) {
			_totalEarnings = (_price * (BASE_DENOMINATOR - royaltyFee - platformFee)) / BASE_DENOMINATOR;
		}

		if (creator != address(0) && royaltyFee > 0) {
			_paid(_paymentToken, creator, (_price * royaltyFee) / BASE_DENOMINATOR);
		}

		if (platformFee > 0) {
			_paid(_paymentToken, xanaliaAddressesStorage.xanaliaTreasury(), (_price * platformFee) / BASE_DENOMINATOR);
		}

		_paid(_paymentToken, _orderOwner, _totalEarnings);

		_transferERC721(_collectionAddress, _tokenId, _buyer);

		return true;
	}

	function _transferERC721(
		address _collectionAddress,
		uint256 _tokenId,
		address _recipient
	) internal {
		IERC721Upgradeable(_collectionAddress).safeTransferFrom(address(this), _recipient, _tokenId);
	}

	function _transferAfterAcceptOffer(uint256 _offerId) internal {
		IOfferDex offerDex = IOfferDex(xanaliaAddressesStorage.offerDex());
		address buyer;
		address paymentToken;
		address collectionAddress;
		uint256 tokenId;
		uint256 totalPaymentAmount;

		(buyer, paymentToken, collectionAddress, tokenId, totalPaymentAmount) = offerDex.acceptOffer(_offerId);

		bool sent = _match(buyer, paymentToken, msg.sender, collectionAddress, tokenId, totalPaymentAmount);
		require(sent, "FAILED_NFT_TRANSFER");
	}
}

contract XanaliaDex is Manager, ReentrancyGuardUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	using AddressUpgradeable for address payable;

	function initialize(uint256 _platformFee, address _xanaliaAddressesStorage) public override initializer {
		Manager.initialize(_platformFee, _xanaliaAddressesStorage);
	}

	/***
	@notice this function is for user to create collections.
	@param name_ name of collection
	@param symbol_ symbol of collection
	@param _private is this collection belong to user or public for everyone
	*/
	function createXanaliaCollection(
		string memory name_,
		string memory symbol_,
		bool _private
	) external onlyNotProcessing {
		uint256 collectionCount_ = collectionCount;
		collectionCount += 1;
		address collectionAddress = ICollectionDeployer(xanaliaAddressesStorage.collectionDeployer()).deploy(
			name_,
			symbol_,
			msg.sender,
			xanaliaAddressesStorageAddress
		);
		collections[msg.sender].push(collectionAddress);
		collectionAddresses[collectionCount_] = collectionAddress;
		isUserCollection[collectionAddress] = _private;
		emit CollectionCreated(msg.sender, collectionAddress, name_, symbol_);
	}

	/***
	@notice this function is for user to mint NFT in a collection.
	@param _collectionAddress address of collection that store NFT
	@param _tokenURI URI of NFT
	@param _royaltyFee royalty fee to pay to author when sell NFT
	*/
	function mint(
		address _collectionAddress,
		string calldata _tokenURI,
		uint256 _royaltyFee
	) external onlyNotProcessing {
		IXanaliaNFT xanaliaNFT = IXanaliaNFT(_collectionAddress);
		if (isUserCollection[_collectionAddress]) {
			require(xanaliaNFT.getContractAuthor() == msg.sender, "Not-author-of-collection");
		}

		uint256 newTokenId = xanaliaNFT.create(_tokenURI, _royaltyFee, msg.sender);

		emit CollectibleCreated(msg.sender, newTokenId);
	}

	/***
	@notice this function is for user to mint NFT and put it on sale.
	@param _collectionAddress address of collection that store NFT
	@param _tokenURI URI of NFT
	@param _royaltyFee royalty fee to pay to author when sell NFT
	@param _paymentToken token address that is used for transaction
	@param _price price when put on sale of NFT
	*/
	function mintAndPutOnSale(
		address _collectionAddress,
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _paymentToken,
		uint256 _price
	) external onlyNotProcessing {
		require(paymentMethod[_paymentToken], "Payment-method-does-not-support");
		IXanaliaNFT xanaliaNFT = IXanaliaNFT(_collectionAddress);
		IMarketDex marketDex = IMarketDex(xanaliaAddressesStorage.marketDex());
		if (isUserCollection[_collectionAddress]) {
			require(xanaliaNFT.getContractAuthor() == msg.sender, "Not-author-of-collection");
		}
		uint256 newTokenId = xanaliaNFT.create(_tokenURI, _royaltyFee, msg.sender);

		emit CollectibleCreated(msg.sender, newTokenId);

		if (!xanaliaNFT.isApprovedForAll(msg.sender, address(this))) {
			xanaliaNFT.setApprovalForAll(msg.sender, address(this), true);
		}

		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, address(this), newTokenId);

		uint256 orderId = marketDex.createOrder(_collectionAddress, _paymentToken, msg.sender, newTokenId, _price);

		emit OrderCreated(orderId, _collectionAddress, newTokenId, _price);
	}

	/***
	@notice this function is for user to mint NFT and put it on auction.
	@param _collectionAddress address of collection that store NFT
	@param _tokenURI URI of NFT
	@param _royaltyFee royalty fee to pay to author when sell NFT
	@param _paymentToken token address that is used for transaction
	@param _startPrice minimum bid for the first bid
	@param _startTime time to start an auction
	@param _endTime time to end an auction
	*/
	function mintAndPutOnAuction(
		address _collectionAddress,
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _paymentToken,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external onlyNotProcessing {
		IXanaliaNFT xanaliaNFT = IXanaliaNFT(_collectionAddress);
		IAuctionDex auctionDex = IAuctionDex(xanaliaAddressesStorage.auctionDex());
		if (isUserCollection[_collectionAddress]) {
			require(xanaliaNFT.getContractAuthor() == msg.sender, "Not-author-of-collection");
		}
		require(paymentMethod[_paymentToken], "Payment-not-support");
		require(_startTime < _endTime, "Time-invalid");
		require(_paymentToken != address(0), "Auction-only-accept-ERC20-token");
		require(block.timestamp < _endTime, "End-time-must-be-greater-than-current-time");

		uint256 newTokenId = xanaliaNFT.create(_tokenURI, _royaltyFee, msg.sender);

		emit CollectibleCreated(msg.sender, newTokenId);

		if (!xanaliaNFT.isApprovedForAll(msg.sender, address(this))) {
			xanaliaNFT.setApprovalForAll(msg.sender, address(this), true);
		}
		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, address(this), newTokenId);

		uint256 auctionId = auctionDex.createAuction(
			_collectionAddress,
			_paymentToken,
			msg.sender,
			newTokenId,
			_startPrice,
			_startTime,
			_endTime
		);

		emit AuctionCreated(auctionId, _collectionAddress, newTokenId);
	}

	/**
	 * @dev Allow user create order on market
	 * @param _collectionAddress address of collection that store NFT
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 * @param _tokenId is id of NFTs
	 * @param _price is price per item in payment method (example 50 USDT)
	 */
	function createOrder(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _price
	) external {
		require(paymentMethod[_paymentToken], "Payment-method-does-not-support");
		IMarketDex marketDex = IMarketDex(xanaliaAddressesStorage.marketDex());

		require(IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) == msg.sender, "Not-item-owner");

		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

		uint256 orderId = marketDex.createOrder(_collectionAddress, _paymentToken, msg.sender, _tokenId, _price);

		emit OrderCreated(orderId, _collectionAddress, _tokenId, _price);
	}

	/**
	 * @dev Allow user to buy an NFT that are listed on sale
	 * @param _orderId is id of order
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 */
	function buy(uint256 _orderId, address _paymentToken) external payable whenNotPaused nonReentrant {
		require(paymentMethod[_paymentToken], "Payment-method-does-not-support");
		IMarketDex marketDex = IMarketDex(xanaliaAddressesStorage.marketDex());

		uint256 totalPaymentAmount;
		address collectionAddress;
		uint256 tokenId;
		address orderOwner;

		(totalPaymentAmount, collectionAddress, tokenId, orderOwner) = marketDex.buy(_orderId, _paymentToken);

		if (_paymentToken == address(0)) {
			require(msg.value >= totalPaymentAmount, "Payment-value-invalid");
		} else {
			IERC20Upgradeable(_paymentToken).safeTransferFrom(msg.sender, address(this), totalPaymentAmount);
		}
		bool sent = _match(msg.sender, _paymentToken, orderOwner, collectionAddress, tokenId, totalPaymentAmount);
		require(sent, "FAILED_NFT_TRANSFER");
		emit Buy(_orderId, _paymentToken, totalPaymentAmount);
	}

	/**
	 * @dev Allow user to edit previous order
	 * @param _orderId is id of order that need edited
	 * @param _price is price per item in payment method (example 50 USDT)
	 */
	function editOrder(uint256 _orderId, uint256 _price) external whenNotPaused {
		IMarketDex marketDex = IMarketDex(xanaliaAddressesStorage.marketDex());

		uint256 orderId;
		uint256 oldOrderId;

		(orderId, oldOrderId) = marketDex.editOrder(msg.sender, _orderId, _price);

		emit OrderEdited(orderId, oldOrderId, _price);
	}

	/**
	 * @dev Owner can cancel an order
	 * @param _orderId is id of sale order
	 */
	function cancelOrder(uint256 _orderId) external whenNotPaused {
		address collectionAddress;
		address orderOwner;
		uint256 tokenId;

		(collectionAddress, orderOwner, tokenId) = IMarketDex(xanaliaAddressesStorage.marketDex()).cancelOrder(
			_orderId,
			msg.sender
		);

		IERC721Upgradeable(collectionAddress).safeTransferFrom(address(this), orderOwner, tokenId);

		emit OrderCancelled(_orderId);
	}

	/**
	 * @dev Allow user create auction on market
	 * @param _collectionAddress address of collection that store NFT
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 * @param _tokenId is id of NFTs
	 * @param _startTime time to start an auction
	 * @param _endTime time to end an auction
	 */
	function createAuction(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external {
		require(paymentMethod[_paymentToken], "Payment-not-support");
		require(_startTime < _endTime, "Time-invalid");
		require(_paymentToken != address(0), "Auction-only-accept-ERC20-token");
		require(block.timestamp < _endTime, "End-time-must-be-greater-than-current-time");

		IAuctionDex auctionDex = IAuctionDex(xanaliaAddressesStorage.auctionDex());

		require(IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) == msg.sender, "Not-item-owner");

		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

		uint256 auctionId = auctionDex.createAuction(
			_collectionAddress,
			_paymentToken,
			msg.sender,
			_tokenId,
			_startPrice,
			_startTime,
			_endTime
		);

		emit AuctionCreated(auctionId, _collectionAddress, _tokenId);
	}

	/**
	@notice User create a bid for an auction item
	@param _collectionAddress address of collection that store NFT
	@param _paymentToken is payment method (USDT, ETH, ...)
	@param _tokenId is id of NFTs
	@param _auctionId id of an auction
	@param _price bid price
	@param _expireTime end time of this bid
	*/
	function bidAuction(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _auctionId,
		uint256 _price,
		uint256 _expireTime
	) external whenNotPaused {
		require(block.timestamp < _expireTime, "Invalid-expire-time");

		require(_paymentToken != address(0), "Bid-only-accept-ERC20-token");

		IAuctionDex auctionDex = IAuctionDex(xanaliaAddressesStorage.auctionDex());

		uint256 bidAuctionId = auctionDex.bidAuction(
			_collectionAddress,
			_paymentToken,
			msg.sender,
			_tokenId,
			_auctionId,
			_price,
			_expireTime
		);

		IERC20Upgradeable(_paymentToken).safeTransferFrom(msg.sender, address(this), _price);

		emit BidAuctionCreated(bidAuctionId, _collectionAddress, _tokenId, _price, _paymentToken);
	}

	/**
	@notice Owner of an auction can cancel an auction
	@param _auctionId id of an auction
	*/
	function cancelAuction(uint256 _auctionId) external whenNotPaused {
		uint256 auctionId = IAuctionDex(xanaliaAddressesStorage.auctionDex()).cancelAuction(
			_auctionId,
			msg.sender,
			false
		);

		emit AuctionCanceled(auctionId);
	}

	/**
	@notice Owner of an auction can cancel a previous bid
	@param _bidAuctionId id of a bid
	*/
	function cancelBidAuction(uint256 _bidAuctionId) external whenNotPaused {
		uint256 bidAuctionId;
		uint256 bidPrice;
		address paymentToken;

		(bidAuctionId, bidPrice, paymentToken) = IAuctionDex(xanaliaAddressesStorage.auctionDex()).cancelBidAuction(
			_bidAuctionId,
			msg.sender
		);

		require(paymentToken != address(0), "Invalid-auction");

		IERC20Upgradeable(paymentToken).safeTransfer(msg.sender, bidPrice);

		emit BidAuctionCanceled(bidAuctionId);
	}

	/**
	@notice Owner of an auction can reclaim an item when it's ended or cancelled
	@param _auctionId id of an auction
	*/
	function reclaimAuction(uint256 _auctionId) external whenNotPaused {
		address collectionAddress;
		uint256 tokenId;

		(collectionAddress, tokenId) = IAuctionDex(xanaliaAddressesStorage.auctionDex()).reclaimAuction(
			_auctionId,
			msg.sender
		);

		_transferERC721(collectionAddress, tokenId, msg.sender);

		emit AuctionReclaimed(_auctionId);
	}

	/**
	@notice Owner of an auction can accept a bid that has been placed and available
	@param _bidAuctionId id of a bid that owner want to accept
	*/
	function acceptBidAuction(uint256 _bidAuctionId) external whenNotPaused {
		IAuctionDex auctionDex = IAuctionDex(xanaliaAddressesStorage.auctionDex());

		uint256 totalPaymentAmount;
		address collectionAddress;
		address paymentToken;
		uint256 tokenId;
		address auctionOwner;
		address bidder;

		(totalPaymentAmount, collectionAddress, paymentToken, tokenId, auctionOwner, bidder) = auctionDex
			.acceptBidAuction(_bidAuctionId, msg.sender);

		bool sent = _match(bidder, paymentToken, auctionOwner, collectionAddress, tokenId, totalPaymentAmount);
		require(sent, "FAILED_NFT_TRANSFER");

		emit BidAuctionClaimed(_bidAuctionId);
	}

	/**
	 * @dev Allow user to make an offer for an NFT that are list on xanalia site
	 * @param _collectionAddress address of collection that store NFT
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 * @param _tokenId is id of NFTs
	 * @param _price the price that buyer want to offer
	 * @param _expireTime time for an offer to be valid
	 */
	function makeOffer(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _price,
		uint256 _expireTime
	) external payable nonReentrant whenNotPaused {
		IOfferDex offerDex = IOfferDex(xanaliaAddressesStorage.offerDex());
		require(paymentMethod[_paymentToken], "Payment-method-does-not-support");
		require(block.timestamp < _expireTime, "Invalid-expire-time");
		require(_paymentToken != address(0), "Can-only-make-offer-with-ERC-20");

		require(IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) != msg.sender, "Owner-can-not-make-an-offer");

		uint256 offerId = offerDex.makeOffer(
			_collectionAddress,
			_paymentToken,
			msg.sender,
			_tokenId,
			_price,
			_expireTime
		);

		IERC20Upgradeable(_paymentToken).safeTransferFrom(msg.sender, address(this), _price);

		emit OfferCreated(offerId, _collectionAddress, _tokenId, _price, _paymentToken);
	}

	/**
	 * @dev Allow owner of item accept an offer
	 * @param _offerId id of an offer
	 */
	function acceptOfferNotOnSale(
		uint256 _offerId,
		address _collectionAddress,
		uint256 _tokenId
	) external whenNotPaused {
		require(IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) == msg.sender, "Not-item-owner");

		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

		_transferAfterAcceptOffer(_offerId);

		emit AcceptOffer(_offerId);
	}

	function acceptOfferFixedPrice(uint256 _offerId, uint256 _orderId) external whenNotPaused {
		IMarketDex marketDex = IMarketDex(xanaliaAddressesStorage.marketDex());
		marketDex.cancelOrder(_orderId, msg.sender);

		_transferAfterAcceptOffer(_offerId);

		emit AcceptOffer(_offerId);
	}

	function acceptOfferAuction(uint256 _offerId, uint256 _auctionId) external whenNotPaused {
		IAuctionDex auctionDex = IAuctionDex(xanaliaAddressesStorage.auctionDex());

		auctionDex.cancelAuction(_auctionId, msg.sender, true);

		_transferAfterAcceptOffer(_offerId);

		emit AcceptOffer(_offerId);
	}

	/**
	@notice User cancel an offer
	@param _offerId id of an offer
	*/
	function cancelOffer(uint256 _offerId) external whenNotPaused nonReentrant {
		IOfferDex offerDex = IOfferDex(xanaliaAddressesStorage.offerDex());

		address paymentToken;
		uint256 totalPaymentAmount;

		(paymentToken, totalPaymentAmount) = offerDex.cancelOffer(_offerId, msg.sender);
		require(paymentToken != address(0), "Invalid-offer");

		IERC20Upgradeable(paymentToken).safeTransfer(msg.sender, totalPaymentAmount);

		emit OfferCancelled(_offerId);
	}

	/**
	@notice this function is to set list of whitelisted user
	@param _user array of address of the user whose address get whitelisted
	@param _status status of each address in array
	*/
	function setWhitelistAddress(address[] calldata _user, bool[] calldata _status) external onlyApprover {
		uint256 length = _user.length;
		require(length == _status.length, "Invalid-data");
		for (uint256 i = 0; i < length; i++) {
			isUserWhitelisted[_user[i]] = _status[i];
		}
		emit WhitelistAddressSet(msg.sender, length);
	}

	/**
	@notice this function is to get list of collections created by user
	@param owner_ address of the user whose collections to be fetched
	@return array of addresses of user's collections
	*/
	function getCollections(address owner_) public view returns (address[] memory) {
		return collections[owner_];
	}

	// Test function, remove on production
	function transferCollectionOwnership(address _owner, address _collection) external onlyOwner {
		IXanaliaNFT(_collection).transferOwnership(_owner);
	}
	
	address public landAddress;
	mapping(address => bool) public _transferSupport;
	modifier onlyTransferSupport(address _collectionAddress) {
		require(_transferSupport[_collectionAddress], "unsupported collection");
		_;
	}
	function transfer(address _collectionAddress, uint256 _tokenId, address to) onlyTransferSupport(_collectionAddress) external {
		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, to, _tokenId);
	}
 
	function setTransferSupport(address _collectionAddress, bool status) external onlyOwner {
		_transferSupport[_collectionAddress] = status; 
	}
}