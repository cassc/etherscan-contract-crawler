//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;

// import './StructDeclaration.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '../interface/INFT.sol';
import '../libraries/TokenStructLib.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

contract NFTMarketInfo is ReentrancyGuard, Ownable {
	using SafeMath for uint256;

	uint256 public platformFee;
	address public platformAddress;

	uint256 public DECIMALS;

	uint256 public MAX_FEE = 1500;

	using TokenStructLib for TokenStructLib.TokenInfo;

	mapping(address => bool) public isManager;
	mapping(uint256 => TokenStructLib.TokenInfo) public TokenMarketInfo;
	INFT public nft;

	AggregatorV3Interface public priceFeed;

	constructor(
		address _nft,
		address _platformFeeAddress,
		address _priceFeed,
		uint256 decimals
	) checkAddress(_nft) checkAddress(_platformFeeAddress) checkAddress(_priceFeed) {
		nft = INFT(_nft);
		priceFeed = AggregatorV3Interface(_priceFeed);
		platformFee = 450; // 4.5%
		platformAddress = _platformFeeAddress;
		DECIMALS = decimals;
	}

	modifier onlyManager() {
		require(isManager[msg.sender], 'NFTInfo:access-denied');
		_;
	}

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	modifier onlyManagerOrOwner() {
		require(isManager[msg.sender] || owner() == msg.sender, 'NFTInfo:access-denied');
		_;
	}

	///@notice function to add token info in a struct
	///@param tokeninfo struct of type TokenStructLib.TokenInfo to store nft/token related info
	///@dev stores all the nft related info and can only be called by managers
	function addTokenInfo(TokenStructLib.TokenInfo calldata tokeninfo) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[tokeninfo.tokenId];
		tokenInfo.tokenId = tokeninfo.tokenId;
		tokenInfo.totalSell = tokeninfo.totalSell;
		tokenInfo.minPrice = tokeninfo.minPrice;
		tokenInfo.thirdPartyFee = tokeninfo.thirdPartyFee;
		tokenInfo.galleryOwnerFee = tokeninfo.galleryOwnerFee;
		tokenInfo.artistFee = tokeninfo.artistFee;
		tokenInfo.thirdPartyFeeExpiryTime = tokeninfo.thirdPartyFeeExpiryTime;
		tokenInfo.gallery = tokeninfo.gallery;
		tokenInfo.thirdParty = tokeninfo.thirdParty;
		tokenInfo.nftOwner = tokeninfo.nftOwner;
		tokenInfo.onSell = tokeninfo.onSell;
		tokenInfo.USD = tokeninfo.USD;
		tokenInfo.galleryOwner = tokeninfo.galleryOwner;
		tokenInfo.onAuction = tokeninfo.onAuction;
	}

	///@notice function to update token info for sell
	///@param _tokenId id of the token to update info
	///@param _minPrice minimum selling price
	///@dev is called from marketplace contract (only managers can call)
	function updateForSell(
		uint256 _tokenId,
		uint256 _minPrice,
		bool USD
	) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.tokenId = _tokenId;
		tokenInfo.minPrice = _minPrice;
		tokenInfo.USD = USD;
		tokenInfo.onSell = true;
	}

	///@notice function to update token info for buy
	///@param _tokenId id of the token to update info
	///@param _owner new owner of nft
	///@dev is called from marketplace contract (only managers can call)
	function updateForBuy(uint256 _tokenId, address _owner) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.tokenId = _tokenId;
		tokenInfo.minPrice = 0;
		tokenInfo.totalSell += 1;
		tokenInfo.onSell = false;
		tokenInfo.USD = false;
		tokenInfo.nftOwner = _owner;
	}

	///@notice function to update token info for cancel sell
	///@param _tokenId id of the token to update info
	///@dev is called from marketplace contract (only managers can call)
	function updateForCancelSell(uint256 _tokenId) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.minPrice = 0;
		tokenInfo.onSell = false;
		tokenInfo.USD = false;
	}

	///@notice function to update token info after claiming nft in auction
	///@param _tokenId id of the token to update info
	///@param _owner new owner of the nft
	///@dev is called from auction contract(only managers can call)
	function updateForAuction(uint256 _tokenId, address _owner) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.minPrice = 0;
		tokenInfo.USD = false;
		tokenInfo.onAuction = false;
		tokenInfo.totalSell += 1;
		tokenInfo.nftOwner = _owner;
	}

	///@notice function to update token info for cancel auction
	///@param _tokenId id of the token to update info
	///@dev is called from auction contract(only managers can call)
	function updateForAuctionCancel(uint256 _tokenId) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.minPrice = 0;
		tokenInfo.USD = false;
		tokenInfo.onAuction = false;
	}

	function updateForSecondaryAuction(
		uint256 _tokenId,
		uint256 _minBiddingAmount,
		bool USD,
		address _owner
	) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.minPrice = _minBiddingAmount;
		tokenInfo.USD = USD;
		tokenInfo.onAuction = true;
		tokenInfo.nftOwner = _owner;
	}

	///@notice function to provide token related info
	///@param _tokenId id of the token to get info
	///@dev getter function
	function getTokenData(uint256 _tokenId)
		public
		view
		returns (
			TokenStructLib.TokenInfo memory tokenInfo // uint256 _minPrice,
		)
	{
		return TokenMarketInfo[_tokenId];
	}

	///@notice function to change galleryfee of tokenId
	///@param _tokenId id of the token to update info
	///@param _galleryFee new gallery owner fee
	///@dev is called from marketplace contract (only managers can call)
	function updateGalleryFee(uint256 _tokenId, uint256 _galleryFee) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.galleryOwnerFee = _galleryFee;
	}

	///@notice function to change artistfee of tokenId
	///@param _tokenId id of the token to update info
	///@param _artistFee new artist owner fee
	///@dev is called from marketplace contract (only managers can call)
	function updateArtistFee(uint256 _tokenId, uint256 _artistFee) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.galleryOwnerFee = _artistFee;
	}

	function setManagers(address _manager, bool status) public onlyOwner {
		isManager[_manager] = status;
	}

	///@notice change the aggregator contract address
	///@param _newaggregator new address of the aggregator contract
	///@dev change the address of the aggregator contract used for matic/usd conversion  and can only be called  by owner
	function changeAggregatorAddress(address _newaggregator) public checkAddress(_newaggregator) onlyOwner {
		priceFeed = AggregatorV3Interface(_newaggregator);
	}

	///@notice calculate the fees/commission rates to different parties
	///@param tokenId id of the token
	///@dev internal utility function to calculate commission rate for different parties
	function calculateCommissions(uint256 tokenId)
		public
		view
		returns (
			uint256 _galleryOwnerCommission,
			uint256 artistCommission,
			uint256 platformCommission,
			uint256 thirdPartyCommission,
			uint256 _remainingAmount,
			address artist
		)
	{
		TokenStructLib.TokenInfo memory tokenmarketInfo = TokenMarketInfo[tokenId];
		uint256 sellingPrice = tokenmarketInfo.minPrice;

		if (tokenmarketInfo.USD) {
			sellingPrice = view_nft_price_native(tokenmarketInfo.minPrice);
		}
		platformCommission = cutPer10000(platformFee, sellingPrice);
		uint256 newSellingPrice = sellingPrice.sub(platformCommission);
		uint256 _rate;
		address receiver;

		(receiver, _rate) = nft.getRoyaltyInfo(uint256(tokenId), newSellingPrice);
		artist = receiver;

		if (tokenmarketInfo.totalSell == 0) {
			artistCommission = cutPer10000(tokenmarketInfo.artistFee, newSellingPrice);
			_galleryOwnerCommission = cutPer10000(tokenmarketInfo.galleryOwnerFee, newSellingPrice);
			_remainingAmount = newSellingPrice.sub(artistCommission).sub(_galleryOwnerCommission);
		} else {
			artistCommission = _rate;
			if (block.timestamp <= tokenmarketInfo.thirdPartyFeeExpiryTime) {
				thirdPartyCommission = cutPer10000(tokenmarketInfo.thirdPartyFee, newSellingPrice);
			} else thirdPartyCommission = 0;

			_remainingAmount = newSellingPrice.sub(_rate).sub(thirdPartyCommission);
		}

		return (
			_galleryOwnerCommission,
			artistCommission,
			platformCommission,
			thirdPartyCommission,
			_remainingAmount,
			artist
		);
	}

	///@notice change the platform address
	///@param _platform new platform address
	///@dev only owner can change the platform address
	function changePlatformAddress(address _platform) public onlyOwner checkAddress(_platform) {
		platformAddress = _platform;
	}

	///@notice change the platform commission rate
	///@param _amount new amount
	///@dev only owner can change the platform commission rate
	function changePlatformFee(uint256 _amount) public onlyOwner {
		require(_amount < MAX_FEE, 'Exceeded max platformfee');
		platformFee = _amount;
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
	function view_nft_price_native(uint256 priceindollar) public view returns (uint256) {
		uint8 priceFeedDecimals = priceFeed.decimals();
		uint256 precision = 1 * 10**18;
		uint256 price = uint256(getLatestPrice());
		uint256 requiredWei = (priceindollar * 10**priceFeedDecimals * precision) / price;
		requiredWei = requiredWei / 10**DECIMALS;
		return requiredWei;
	}

	///@notice change the decimals of the contract
	///@param _decimals new decimals
	function updateDecimals(uint8 _decimals) public onlyOwner {
		DECIMALS = _decimals;
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
}