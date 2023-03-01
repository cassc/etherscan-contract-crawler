//SPDX-License-Identifier: Unlicensed
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '../interface/IMarketPlace.sol';
import '../interface/INFT.sol';
import './NFTMarketInfo.sol';
import '../libraries/TokenStructLib.sol';

pragma solidity 0.8.10;

contract MarketPlace is ReentrancyGuard, Ownable, IMarketPlace, IERC721Receiver, Multicall {
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.UintSet;

	using TokenStructLib for TokenStructLib.TokenInfo;

	uint256 public blockNumber;

	uint256 public MAX_FEE = 1500;

	INFT public nft;

	NFTMarketInfo public tokenInfo;

	///@notice checks whether the given address is added as Gallery or not
	mapping(address => bool) public isGallery;

	///@notice checks whether the given address is added as admin or not
	mapping(address => bool) public isAdmin;

	EnumerableSet.UintSet private tokenIdOnSell;

	constructor(address _nft, address _tokenInfo) checkAddress(_nft) checkAddress(_tokenInfo) {
		nft = INFT(_nft);
		tokenInfo = NFTMarketInfo(_tokenInfo);
		isAdmin[msg.sender] = true;
		blockNumber = block.number;
	}

	///@notice to check whether the sender address is owner of given token id or not or the owner of the gallery
	///@dev modifier to check whether the sender address is owner of given token id or not or the owner of the gallery
	modifier onlyGalleryOrTokenOwner(uint256 _tokenId) {
		address owner = address(nft.ownerOf(_tokenId));
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);
		if (!isGallery[msg.sender] && owner != msg.sender && tokenmarketInfo.nftOwner != msg.sender) {
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

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	///@notice  Receive Ether
	receive() external payable {}

	///@notice buy the given token id
	///@param _tokenId token id to be bought by the buyer
	///@param _buyer address of the buyer
	///@dev payable function
	function buy(uint256 _tokenId, address _buyer) public payable override nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;

		tokenmarketInfo = gettokeninfo(_tokenId);
		require(nft.checkNft(_tokenId), 'invalid TokenId');
		require(tokenmarketInfo.onSell, 'Not for sale');
		require(_buyer != tokenmarketInfo.nftOwner, 'owner cannot buy');

		uint256 sellingPrice = tokenmarketInfo.minPrice;
		if (tokenmarketInfo.USD) {
			sellingPrice = tokenInfo.view_nft_price_native(tokenmarketInfo.minPrice);
		}
		checkAmount(sellingPrice, _buyer);

		uint256 _galleryownerfee;
		uint256 _artistfee;
		uint256 _platformfee;
		uint256 _thirdpartyfee;
		uint256 ownerfee;
		address artist;

		(_galleryownerfee, _artistfee, _platformfee, _thirdpartyfee, ownerfee, artist) = tokenInfo.calculateCommissions(
			_tokenId
		);

		transferfees(artist, _artistfee);
		transferfees(tokenInfo.platformAddress(), _platformfee);
		transferfees(tokenmarketInfo.galleryOwner, _galleryownerfee);
		if (_thirdpartyfee > 0) transferfees(tokenmarketInfo.thirdParty, _thirdpartyfee);
		transferfees(tokenmarketInfo.nftOwner, ownerfee);

		nft.safeTransferFrom(address(this), _buyer, _tokenId);
		tokenInfo.updateForBuy(_tokenId, _buyer);
		tokenIdOnSell.remove(_tokenId);
		emit Nftbought(_tokenId, tokenmarketInfo.nftOwner, _buyer, sellingPrice);
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
	function transferfees(address receiver, uint256 _amount) internal {
		(bool txSuccess, ) = receiver.call{ value: _amount }('');
		require(txSuccess, 'Failed to pay commission rates');
	}

	///@notice set the nft for sell
	///@param _tokenId token id to be listed for sale
	///@param _minprice selling price of the token id
	///@param _artistfee commission rate to be transferred to artist while selling nft
	///@param _galleryownerfee commission rate to be transferred to gallery owner while selling nft
	///@param _thirdpartyfee commission rate to be transferred to thirdparty while selling nft
	///@param _expirytime time limit to pay third party commission fee
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
		bool USD
	) public override onlyGalleryOrTokenOwner(_tokenId) nonReentrant {
		require(!gettokeninfo(_tokenId).onSell, 'Already on Sell');
		require(nft.checkNft(_tokenId), 'Invalid tokenId');
		tokenIdOnSell.add(_tokenId);
		address tokenOwner = nft.ownerOf(_tokenId);
		TokenStructLib.TokenInfo memory Token = TokenStructLib.TokenInfo(
			_tokenId,
			0,
			_minprice,
			_thirdpartyfee,
			_galleryownerfee,
			_artistfee,
			_expirytime,
			payable(msg.sender),
			payable(_thirdParty),
			tokenOwner,
			true,
			USD,
			false,
			payable(_gallery)
		);
		tokenInfo.addTokenInfo(Token);

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
	) public onlyTokenOwner(_tokenId) nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);

		require(!tokenmarketInfo.onSell, 'Already on Sell');
		require(nft.checkNft(_tokenId), 'Invalid tokenId');

		tokenIdOnSell.add(_tokenId);
		tokenInfo.updateForSell(_tokenId, _minprice, USD);
		transferNft(_tokenId);
		emit Nftonsell(_tokenId, _minprice);
	}

	///@notice cancel the nft listed for sell
	///@param _tokenId id of the token to be removed from list
	///@dev only gallery  or token owner can cancel the sell of nft
	function cancelSell(uint256 _tokenId) public override onlyGalleryOrTokenOwner(_tokenId) nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);
		require(tokenmarketInfo.onSell, 'Not on Sell');
		require(nft.checkNft(_tokenId), 'Invalid TokenId');
		tokenIdOnSell.remove(_tokenId);
		tokenInfo.updateForCancelSell(_tokenId);
		nft.safeTransferFrom(address(this), msg.sender, _tokenId);
		emit Cancelnftsell(_tokenId);
	}

	///@notice get token info
	///@param _tokenId token id
	///@dev returns the tuple providing information about token
	function gettokeninfo(uint256 _tokenId) public view returns (TokenStructLib.TokenInfo memory tokenMarketInfo) {
		tokenMarketInfo = tokenInfo.getTokenData(_tokenId);
		return tokenMarketInfo;
	}

	///@notice list  all the token listed for sale
	function listtokensforsale() public view override returns (uint256[] memory) {
		return tokenIdOnSell.values();
	}

	///@notice change the  selling price of the listed nft
	///@param _tokenId id of the token
	///@param _minprice new selling price
	///@dev only gallery  or token owner can change  the artist commission rate for given  nft
	function resale(uint256 _tokenId, uint256 _minprice) public override onlyGalleryOrTokenOwner(_tokenId) nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);
		require(tokenmarketInfo.onSell, 'Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		tokenInfo.updateForSell(_tokenId, _minprice, tokenmarketInfo.USD);
	}

	///@notice change the  artist commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _artistFee new artist fee commission rate
	///@dev only gallery owner or token owner can change  the artist commission rate for given  nft
	function changeArtistFee(uint256 _tokenId, uint256 _artistFee) public override onlyGalleryOrTokenOwner(_tokenId) {
		require(gettokeninfo(_tokenId).onSell, 'Token Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		tokenInfo.updateArtistFee(_tokenId, _artistFee);
	}

	///@notice change the  gallery commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _galleryFee new gallery owner fee commission rate
	///@dev only gallery owner or token owner can change  the gallery owner commission rate for given  nft
	function changeGalleryFee(uint256 _tokenId, uint256 _galleryFee) public override onlyGalleryOrTokenOwner(_tokenId) {
		require(gettokeninfo(_tokenId).onSell, 'Token Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		tokenInfo.updateGalleryFee(_tokenId, _galleryFee);
	}

	///@notice change nft  contract address
	///@param _nft new nft address
	///@dev only dev can change address
	function changeNFT(address _nft) public checkAddress(_nft) onlyOwner {
		nft = INFT(_nft);
	}

	///@notice change nftMarketInfo  contract address
	///@param _nftInfo new nft address
	///@dev only dev can change address
	function changeNFTMarketInfo(address _nftInfo) public checkAddress(_nftInfo) onlyOwner {
		tokenInfo = NFTMarketInfo(_nftInfo);
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

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}
}