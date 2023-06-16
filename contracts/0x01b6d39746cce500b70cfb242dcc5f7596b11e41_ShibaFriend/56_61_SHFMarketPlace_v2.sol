// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./external/AggregatorV3Interface.sol";

/**
 * @title Marketplace Contract
 * @notice A contract that allow users place nft to sold
 */
contract SHFMarketplaceV2 is AccessControlUpgradeable, PausableUpgradeable {
    /*
        List of nft to be trading on marketplace
    */
    mapping(address => mapping(uint256 => Trading)) public tradings;
    mapping(IERC721 => SpecialFee) public specialFee;
    uint256 public defaultFee;
    struct Trading {
        address seller;
        uint256 price;
        uint256 startAt;
    }
    //Repesent the special fee of some nft address
    struct SpecialFee {
        uint256 rate;
        bool enabled;
    }
    // Contract's Events
    event TradingCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address indexed seller
    );

    event TradingSuccessful(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        address indexed buyer,
        address currency
    );

    event TradingCancelled(
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    AggregatorV3Interface internal bnbPriceFeed;
    address binanceUSD;

    function initialize(uint256 _defaultFee) initializer public {
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        require(_defaultFee <= 100, "This fee is not acceptable");
        require(_defaultFee >= 0, "This fee is not acceptable");
        defaultFee = _defaultFee;
    }

    /*
        Admin functions
    */
    function setSpecialFee(address externalNftAddress, uint256 fee)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(fee <= 100, "This fee is not acceptable");
        require(fee >= 0, "This fee is not acceptable");
        // Set the fee
        specialFee[IERC721(externalNftAddress)] = SpecialFee(fee, true);
    }

    function removeSpecialFee(address externalNftAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Set the fee
        // specialFee[externalNftAddress].rate = 0;
        delete specialFee[IERC721(externalNftAddress)];
    }

    function setDefaultFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fee <= 100, "This fee is not acceptable");
        require(fee >= 0, "This fee is not acceptable");
        // Set the fee
        defaultFee = fee;
    }

    /*
       @dev admin can withdraw all funds
    */
    function adminClaim(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // withdraw native currency
        if (currencyAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 currencyContract = IERC20(currencyAddress);
            currencyContract.transfer(msg.sender, currencyContract.balanceOf(address(this)));
        }
    }

    /*
        End admin functions
    */

    /*
       @dev check if a token is on sale
    */
    modifier isOnTrading(address _nftAddress, uint256 _tokenId) {
        require(tradings[_nftAddress][_tokenId].startAt > 0, "Token not listed for sale");
        _;
    }

    /*
        @dev Creates and begins a new trade. sender should already allow this contract to manage _tokenId
        @param _nftAddress - address of a deployed contract implementing NFT interface.
        @param _tokenId - ID of token to trade, sender must be owner.
        @param _price - price to trade
    */
    function createTrading(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    ) external whenNotPaused {
        address _seller = msg.sender;
        // require(_price >= 100, "Must set a price");
        // require(_price % 100 == 0, "Price must be divisible by 100");
        // currency must be native token or allowed
        require(_owns(_nftAddress, _seller, _tokenId), "Invalid owner");
        /*
            Transfer the nft to marketplace
        */
        _escrow(_nftAddress, _seller, _tokenId);
        Trading memory _trading = Trading(
            _seller,
            _price,
            block.timestamp
        );
        _addTrading(_nftAddress, _tokenId, _trading, _seller);
    }

    function buy(address _nftAddress, uint256 _tokenId ,address _currency)
        external
        payable
        whenNotPaused
    {
        _buy(_nftAddress, _tokenId ,_currency);
        _transfer(_nftAddress, msg.sender, _tokenId);
    }

    /// @dev tranfer money too
    ///  Returns the NFT to original owner.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of token on trading
    function cancelTrading(address _nftAddress, uint256 _tokenId)
        external
        isOnTrading(_nftAddress, _tokenId)
    {
        Trading storage _trading = tradings[_nftAddress][_tokenId];
        require(msg.sender == _trading.seller);
        _cancelTrading(_nftAddress, _tokenId, _trading.seller);
    }

    /// @dev Cancels an auction when the contract is paused.
    ///  Only the Admin can do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param _nftAddress - Address of the NFT.
    /// @param _tokenId - ID of the NFT on auction to cancel.
    function cancelTradingWhenPaused(address _nftAddress, uint256 _tokenId)
        external
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
        isOnTrading(_nftAddress, _tokenId)
    {
        Trading storage _trading = tradings[_nftAddress][_tokenId];
        _cancelTrading(_nftAddress, _tokenId, _trading.seller);
    }

    function _computeFee(uint256 _price, address _nftAddress)
        internal
        view
        returns (uint256)
    {
        IERC721 _nftContract = IERC721(_nftAddress);
        if (specialFee[_nftContract].enabled) {
            return _price / 100 * specialFee[_nftContract].rate;
        }
        return _price / 100 * defaultFee;
    }

    function _buy(address _nftAddress, uint256 _tokenId ,address _currency)
        internal
        isOnTrading(_nftAddress, _tokenId)
        returns (uint256)
    {
        // Get a reference to the auction struct
        require((_currency == address(0)) || (_currency == binanceUSD), "SHFMarketPlace: Currency not allowed");
        Trading storage _trading = tradings[_nftAddress][_tokenId];
        require(msg.sender != _trading.seller, "SHFMarketPlace: Cannot buy your own");

        //Validate trading
        address _seller = _trading.seller;
         //USD price
        _removeTrading(_nftAddress, _tokenId);
        if (_currency == address(0)) {
            uint256 _price = getLatestPrice(_trading.price);
            // Transfer proceeds to seller (if there are any!)
            uint256 _tradingFee = _computeFee(_price, _nftAddress);
            uint256 _sellerProceeds = _price - _tradingFee;
            require(msg.value >= _price, "Not enough money");
            payable(_seller).transfer(_sellerProceeds);
        } else {
            uint256 _price = _trading.price * 10**18;
            // Case busd
            uint256 _tradingFee = _computeFee(_price, _nftAddress); // With decimal
            uint256 _sellerProceeds = (_price - _tradingFee); // with decimal
            IERC20(_currency).transferFrom(msg.sender, address(this), _price);
            IERC20(_currency).transfer(_seller, _sellerProceeds);
        }
        emit TradingSuccessful(
            _nftAddress,
            _tokenId,
            _trading.price,
            msg.sender,
            _currency
        );
        return _trading.price;
    }

    /// @dev Adds an _trading to the list of open tradings. Emit TradingCreated event.
    function _addTrading(
        address _nftAddress,
        uint256 _tokenId,
        Trading memory _trading,
        address _seller
    ) internal {
        tradings[_nftAddress][_tokenId] = _trading;
        emit TradingCreated(
            _nftAddress,
            _tokenId,
            _trading.price,
            _seller
        );
    }

    /// @dev Removes an trading from the list of open tradings.
    /// @param _tokenId - ID of NFT on auction.
    function _removeTrading(address _nftAddress, uint256 _tokenId) internal {
        delete tradings[_nftAddress][_tokenId];
    }

    /// @dev Cancels an trading unconditionally.
    function _cancelTrading(
        address _nftAddress,
        uint256 _tokenId,
        address _seller
    ) internal {
        _removeTrading(_nftAddress, _tokenId);
        _transfer(_nftAddress, _seller, _tokenId);
        emit TradingCancelled(_nftAddress, _tokenId);
    }

    /// @dev Transfers an NFT owned by this contract to another address.
    /// Returns true if the transfer succeeds.
    /// @param _nftAddress - The address of the NFT.
    /// @param _receiver - Address to transfer NFT to.
    /// @param _tokenId - ID of token to transfer.
    function _transfer(
        address _nftAddress,
        address _receiver,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = IERC721(_nftAddress);
        // It will throw if transfer fails
        _nftContract.transferFrom(address(this), _receiver, _tokenId);
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _nftAddress - The address of the NFT.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(
        address _nftAddress,
        address _owner,
        uint256 _tokenId
    ) internal {
        IERC721 _nftContract = IERC721(_nftAddress);
        // It will throw if transfer fails
        _nftContract.transferFrom(_owner, address(this), _tokenId);
    }

    /*
        Check NFT address belong to
    */
    function _owns(
        address _nftAddress,
        address _requesterAddr,
        uint256 _tokenId
    ) internal view returns (bool) {
        IERC721 _nftContract = IERC721(_nftAddress);
        return (_nftContract.ownerOf(_tokenId) == _requesterAddr);
    }

    function setBUSDCurrency(address currencyAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        binanceUSD = currencyAddress;
    }

    // priceFeed should be something like BUSD/BNB or DAI/BNB
    function setBnbPriceFeed(address _priceFeed, string calldata _description) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bnbPriceFeed = AggregatorV3Interface(_priceFeed);
        require(memcmp(bytes(bnbPriceFeed.description()), bytes(_description)),"SHFMarketPlace: Incorrect Feed");
    }

    function memcmp(bytes memory a, bytes memory b) internal pure returns(bool) {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function getLatestPrice(uint256 salePrice) public view returns (uint) {
        (
            , int price, , ,
        ) = bnbPriceFeed.latestRoundData();
        // rateDecimals = bnbPriceFeed.decimals();
        // price is BUSD / BNB * (amount)
        require(price > 0, "SHFMarketPlace: Invalid price");
        return uint(price) * salePrice; // since rateDecimals is 18, the same as BNB, we don't need to do anything
    }
}