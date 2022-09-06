//SPDX-License-Identifier: Unlicensed
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '../interface/IMarketPlace.sol';
import '../interface/INFT.sol';

pragma solidity ^0.8.0;

contract MarketPlace is Ownable, IMarketPlace, IERC721Receiver, Multicall {
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.UintSet;

	uint256 public platformfee;
	uint256 public blockNumber;
	address public platformaddress;

	uint256 public MAX_FEE = 1500;

	uint256 public DECIMALS;

	INFT public nft;

	AggregatorV3Interface public priceFeed;

	///@notice provides  market information of particular tokenId
	///@dev map the tokenid with tokenMarketInfo struct
	mapping(uint256 => tokenMarketInfo) public TokenMarketInfo;

	mapping(uint256 => feeInfo) public TokenfeeInfo;

	///@notice checks whether the given address is added as Gallery or not
	mapping(address => bool) public isGallery;

	///@notice checks whether the given address is added as admin or not
	mapping(address => bool) public isAdmin;

	EnumerableSet.UintSet private tokenIdOnSell;

	constructor(
		address _nft,
		address _platformfeeaddress,
		address _aggregatorContract,
		uint256 decimals
	) {
		nft = INFT(_nft);
		platformfee = 450; // 4.5%
		platformaddress = _platformfeeaddress;
		priceFeed = AggregatorV3Interface(_aggregatorContract);
		isAdmin[msg.sender] = true;
		blockNumber = block.number;
		DECIMALS = decimals;
	}

	///@notice to check whether the sender address is owner of given token id or not or the owner of the gallery
	///@dev modifier to check whether the sender address is owner of given token id or not or the owner of the gallery
	modifier onlyGalleryOrTokenOwner(uint256 _tokenId) {
		address owner = address(nft.ownerOf(_tokenId));
		tokenMarketInfo memory TokenInfo = TokenMarketInfo[_tokenId];
		if (!isGallery[msg.sender] && owner != msg.sender && TokenInfo.owner != msg.sender) {
			revert('access-denied');
		}
		_;
	}

	///@notice to check whether the sender address is admin or not
	///@dev modifier to check whether the sender address is admin or not
	modifier onlyAdmin() {
		require(isAdmin[msg.sender], 'admin-access-denied');
		_;
	}
	///@notice to check whether the sender address is admin or owner or not
	///@dev modifier to check whether the sender address is admin ,owner or  not
	modifier onlyAdminOrOwner() {
		require(isAdmin[msg.sender] || owner() == msg.sender, 'Should be owner/admin');
		_;
	}

	///@notice to check whether the sender address is token owner or not
	///@dev modifier to check whether the sender address token owner or not
	modifier onlyTokenOwner(uint256 _tokenId) {
		require(nft.ownerOf(_tokenId) == msg.sender, 'Not-owner');
		_;
	}

	///@notice  Receive Ether
	receive() external payable {}

	///@notice buy the given token id
	///@param _tokenId token id to be bought by the buyer
	///@param _buyer address of the buyer
	///@dev payable function
	function buy(uint256 _tokenId, address _buyer) public payable override {
		tokenMarketInfo storage TokenInfo = TokenMarketInfo[_tokenId];
		feeInfo storage feeinfo = TokenfeeInfo[_tokenId];
		// address owner =
		require(nft.checkNft(_tokenId), 'invalid TokenId');
		require(TokenInfo.onSell, 'Not for sale');
		require(_buyer != TokenInfo.owner, 'owner cannot buy');

		uint256 sellingPrice = TokenInfo.minPrice;
		if (TokenInfo.USD) {
			sellingPrice = view_nft_price_matic(TokenInfo.minPrice);
		}
		checkAmount(sellingPrice, _buyer);

		uint256 _galleryownerfee;
		uint256 _artistfee;
		uint256 _platformfee;
		uint256 _thirdpartyfee;
		uint256 ownerfee;

		(_galleryownerfee, _artistfee, _platformfee, _thirdpartyfee, ownerfee) = calculateCommissions(_tokenId);

		feeinfo.totalartistfee = addTotal(_artistfee, feeinfo.totalartistfee);
		feeinfo.totalplatformfee = addTotal(_platformfee, feeinfo.totalplatformfee);
		feeinfo.totalthirdpartyfee = addTotal(_thirdpartyfee, feeinfo.totalthirdpartyfee);
		transferfees(TokenInfo.artist, _artistfee);
		transferfees(platformaddress, _platformfee);
		transferfees(TokenInfo.galleryOwner, _galleryownerfee);
		if (_thirdpartyfee > 0) transferfees(TokenInfo.thirdParty, _thirdpartyfee);
		transferfees(TokenInfo.owner, ownerfee);

		nft.safeTransferFrom(address(this), _buyer, _tokenId);
		TokenInfo.onSell = false;
		TokenInfo.totalSell += 1;
		TokenInfo.minPrice = 0;
		TokenInfo.artistfee = 0;
		TokenInfo.galleryownerfee = 0;
		TokenInfo.USD = false;
		tokenIdOnSell.remove(_tokenId);
		TokenInfo.owner = _buyer;
		emit Nftbought(_tokenId, TokenInfo.owner, _buyer, sellingPrice);
	}

	///@notice check amount value send
	///@param sellingPrice selling price of the token
	///@param buyer address of the buyer
	///@dev checks the value sent with selling price and return excessive amount to the buyer address
	function checkAmount(uint256 sellingPrice, address buyer) internal {
		require(msg.value >= sellingPrice, 'Insufficient amount');
		uint256 amountToRefund = msg.value - sellingPrice;
		transferfees(payable(buyer), amountToRefund);
	}

	///@notice transfer the fees/commission rates to different parties
	///@dev internal utility function to transfer fees
	// function transferfees(uint256 _tokenId) internal {
	function transferfees(address receiver, uint256 _amount) internal {
		(bool txSuccess, ) = receiver.call{ value: _amount }('');
		require(txSuccess, 'Failed to pay commission rates');
	}

	///@notice calculate the fees/commission rates to different parties
	///@param tokenId id of the token
	///@dev internal utility function to calculate commission rate for different parties
	function calculateCommissions(uint256 tokenId)
		internal
		view
		returns (
			uint256 _galleryOwnercommission,
			uint256 artistcommssion,
			uint256 platformCommission,
			uint256 thirdPartyCommission,
			uint256 _remainingAmount
		)
	{
		tokenMarketInfo storage TokenInfo = TokenMarketInfo[tokenId];

		uint256 sellingPrice = TokenInfo.minPrice;

		if (TokenInfo.USD) {
			sellingPrice = view_nft_price_matic(TokenInfo.minPrice);
		}
		platformCommission = cutPer10000(platformfee, sellingPrice);
		uint256 newSellingPrice = sellingPrice.sub(platformCommission);
		thirdPartyCommission;
		artistcommssion;

		if (TokenInfo.totalSell == 0) {
			artistcommssion = cutPer10000(TokenInfo.artistfee, newSellingPrice);
			_galleryOwnercommission = cutPer10000(TokenInfo.galleryownerfee, newSellingPrice);
			_remainingAmount = newSellingPrice.sub(artistcommssion).sub(_galleryOwnercommission);
		} else {
			uint256 _rate;
			address receiver;
			(receiver, _rate) = nft.getRoyaltyInfo(uint256(tokenId), newSellingPrice);
			artistcommssion = _rate;
			if (block.timestamp <= TokenInfo.feeExpiryTime) {
				thirdPartyCommission = cutPer10000(TokenInfo.thirdpartyfee, newSellingPrice);
			} else thirdPartyCommission = 0;

			_remainingAmount = newSellingPrice.sub(_rate).sub(thirdPartyCommission);
		}

		return (_galleryOwnercommission, artistcommssion, platformCommission, thirdPartyCommission, _remainingAmount);
	}

	///@notice set the nft for sell
	///@param _tokenId token id to be listed for sale
	///@param _minprice selling price of the token id
	///@param _artistfee commission rate to be transferred to artist while selling nft
	///@param _galleryownerfee commission rate to be transferred to gallery owner while selling nft
	///@param _thirdpartyfee commission rate to be transferred to thirdparty while selling nft
	///@param _expirytime time limit to pay third party commission fee
	///@param _artist address of the artist of nft
	///@param _thirdParty address of the third party asssociated with nft
	///@param _gallery address of the gallery associated  with  nft
	///@param USD boolean value to indicate pricing is in dollar or not
	///@dev function to list nft for sell and can be called only by gallery or tokenOwner
	function sell(
		uint256 _tokenId,
		uint256 _minprice,
		uint256 _artistfee,
		uint256 _galleryownerfee,
		uint256 _thirdpartyfee,
		uint256 _expirytime,
		address _thirdParty,
		address _gallery,
		address _artist,
		bool USD
	) public override onlyGalleryOrTokenOwner(_tokenId) {
		tokenMarketInfo storage TokenInfo = TokenMarketInfo[_tokenId];
		require(!TokenInfo.onSell, 'Already on Sell');
		require(nft.checkNft(_tokenId), 'Invalid tokenId');
		tokenIdOnSell.add(_tokenId);
		TokenInfo.tokenId = _tokenId;
		TokenInfo.minPrice = _minprice;
		TokenInfo.artistfee = _artistfee;
		TokenInfo.galleryownerfee = _galleryownerfee;
		TokenInfo.thirdpartyfee = _thirdpartyfee;
		TokenInfo.feeExpiryTime = _expirytime;
		TokenInfo.galleryOwner = payable(_gallery);
		TokenInfo.artist = payable(_artist);
		TokenInfo.thirdParty = payable(_thirdParty);
		TokenInfo.onSell = true;
		TokenInfo.USD = USD;
		TokenInfo.owner = nft.ownerOf(_tokenId);
		transferNft(_tokenId);

		emit Nftonsell(_tokenId, _minprice);
	}

	function transferNft(uint256 _tokenId) internal {
		address owner = nft.ownerOf(_tokenId);
		nft.safeTransferFrom(owner, address(this), _tokenId);
	}

	///@notice set the nft for secondary sell
	///@param _tokenId token id to be listed for sale
	///@param _minprice selling price of the token id
	/// @param USD boolean value to indicate pricing is in dollar or not
	///@dev nft is set for sell after first sell
	function SecondarySell(
		uint256 _tokenId,
		uint256 _minprice,
		bool USD
	) public onlyTokenOwner(_tokenId) {
		tokenMarketInfo storage TokenInfo = TokenMarketInfo[_tokenId];
		require(!TokenInfo.onSell, 'Already on Sell');
		require(nft.checkNft(_tokenId), 'Invalid tokenId');
		TokenInfo.owner = nft.ownerOf(_tokenId);
		// require(TokenInfo.totalSell != 0, 'Cannot add for secondary sell ');
		tokenIdOnSell.add(_tokenId);
		TokenInfo.tokenId = _tokenId;
		TokenInfo.minPrice = _minprice;
		TokenInfo.onSell = true;
		TokenInfo.USD = USD;
		transferNft(_tokenId);
		emit Nftonsell(_tokenId, _minprice);
	}

	///@notice cancel the nft listed for sell
	///@param _tokenId id of the token to be removed from list
	///@dev only gallery  or token owner can cancel the sell of nft
	function cancelSell(uint256 _tokenId) public override onlyGalleryOrTokenOwner(_tokenId) {
		tokenMarketInfo storage TokenInfo = TokenMarketInfo[_tokenId];
		require(TokenInfo.onSell, 'Not on Sell');
		require(nft.checkNft(_tokenId), 'Invalid TokenId');
		tokenIdOnSell.remove(_tokenId);
		TokenInfo.onSell = false;
		TokenInfo.minPrice = 0;
		TokenInfo.USD = false;
		nft.safeTransferFrom(address(this), msg.sender, _tokenId);
		emit Cancelnftsell(_tokenId);
	}

	///@notice get token info
	///@param _tokenId token id
	///@dev returns the tuple providing information about token
	function gettokeninfo(uint256 _tokenId) public view override returns (tokenMarketInfo memory) {
		tokenMarketInfo storage TokenInfo = TokenMarketInfo[_tokenId];
		return TokenInfo;
	}

	///@notice list  all the token listed for sale
	function listtokenforsale() public view override returns (uint256[] memory) {
		return tokenIdOnSell.values();
	}

	///@notice change the  selling price of the listed nft
	///@param _tokenId id of the token
	///@param _minprice new selling price
	///@dev only gallery  or token owner can change  the artist commission rate for given  nft
	function resale(uint256 _tokenId, uint256 _minprice) public override onlyGalleryOrTokenOwner(_tokenId) {
		tokenMarketInfo storage TokenInfo = TokenMarketInfo[_tokenId];
		require(TokenInfo.onSell, 'Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		TokenInfo.minPrice = _minprice;
	}

	///@notice change the  artist commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _artistFee new artist fee commission rate
	///@dev only gallery owner or token owner can change  the artist commission rate for given  nft
	function changeArtistFee(uint256 _tokenId, uint256 _artistFee) public override onlyGalleryOrTokenOwner(_tokenId) {
		tokenMarketInfo storage TokenInfo = TokenMarketInfo[_tokenId];
		require(TokenInfo.onSell, 'Token Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		TokenInfo.tokenId = _tokenId;
		TokenInfo.artistfee = _artistFee;
	}

	///@notice change the  gallery commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _galleryFee new gallery owner fee commission rate
	///@dev only gallery owner or token owner can change  the gallery owner commission rate for given  nft
	function changeGalleryFee(uint256 _tokenId, uint256 _galleryFee) public override onlyGalleryOrTokenOwner(_tokenId) {
		tokenMarketInfo storage TokenInfo = TokenMarketInfo[_tokenId];
		require(TokenInfo.onSell, 'Token Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');

		TokenInfo.tokenId = _tokenId;
		TokenInfo.galleryownerfee = _galleryFee;
	}

	///@notice add the gallery address
	///@param _gallery address of the gallery to be added
	///@param _status status to set
	///@dev only Admin can the gallery
	function addGallery(address _gallery, bool _status) public override onlyAdmin {
		require(_gallery != address(0x0), '0x00 galleryaddress');
		isGallery[_gallery] = _status;
	}

	///@notice add new admins
	///@param _admin address to add as admin
	///@dev onlyOwner can add new admin
	function addAdmin(address _admin) public override onlyOwner {
		isAdmin[_admin] = true;
	}

	///@notice calculate percent amount for given percent and total
	///@dev calculates the cut per 10000 fo the given total
	///@param _cut cut to be caculated per 10000, i.e percentAmount * 100
	///@param _total total amount from which cut is to be calculated
	///@return cutAmount percentage amount calculated
	///@dev internal utility function to calculate percentage
	function cutPer10000(uint256 _cut, uint256 _total) internal pure returns (uint256 cutAmount) {
		if (_cut == 0) return 0;
		cutAmount = _total.mul(_cut).div(10000);
		return cutAmount;
	}

	///@notice calculate total amount accumulated
	///@param _add add to be added to previous total
	///@param _total previous total amount
	///@return totalAmount added sum
	///@dev internal utility function to add totals
	function addTotal(uint256 _add, uint256 _total) internal pure returns (uint256 totalAmount) {
		totalAmount = _total.add(_add);
	}

	///@notice change the platform address
	///@param _platform new platform address
	///@dev only owner can change the platform address
	function changePlatformAddress(address _platform) public override onlyOwner {
		platformaddress = _platform;
	}

	///@notice change the platform commission rate
	///@param _amount new amount
	///@dev only owner can change the platform commission rate
	function changePlatformFee(uint256 _amount) public onlyOwner {
		require(_amount < MAX_FEE, 'Exceeded max platformfee');
		platformfee = _amount;
	}

	///@notice provides the latest matic/usd rate
	///@return price latest matictodollar rate
	///@dev uses the chain link data feed's function to get latest rate
	function getLatestPrice() public view returns (int256) {
		(, int256 price, , , ) = priceFeed.latestRoundData();
		return price;
	}

	///@notice calculate the equivalent matic from given dollar price
	///@dev uses chainlink data feed's function to get the lateset matic/usd rate and calculate matic( in wei)
	///@param priceindollar price in terms of dollar
	///@return priceinwei returns the value in terms of wei
	function view_nft_price_matic(uint256 priceindollar) public view returns (uint256) {
		uint8 priceFeedDecimals = priceFeed.decimals();
		uint256 precision = 1 * 10**18;
		uint256 price = uint256(getLatestPrice());
		uint256 requiredWei = (priceindollar * 10**priceFeedDecimals * precision) / price;
		requiredWei = requiredWei / 10**DECIMALS;
		return requiredWei;
	}

	///@notice change the aggregator contract address
	///@param _contract new address of the aggregator contract
	///@dev change the address of the aggregator contract used for matic/usd conversion  and can only be called  by owner or admin
	function changeAggregatorContract(address _contract) public onlyAdminOrOwner {
		priceFeed = AggregatorV3Interface(_contract);
	}

	///@notice change the decimal of  marketplace contract
	///@param _decimals new decimal  value
	///@dev change the decimals  and can only be called  by owner or admin
	function changeMarketPlaceDecimal(uint256 _decimals) public onlyAdminOrOwner {
		DECIMALS = _decimals;
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		// emit NFTReceived(operator, from, tokenId, data);
		return IERC721Receiver.onERC721Received.selector;
	}
	// function changeThirdPartyAddress(uint256 _tokenId, address _account) public {
	// 	tokenMarketInfo storage TokenInfo = TokenMarketInfo[_tokenId];
	// 	TokenInfo.thirdParty = payable(_account);
	// }
}