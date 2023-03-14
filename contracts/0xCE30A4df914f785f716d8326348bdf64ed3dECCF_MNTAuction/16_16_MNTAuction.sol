pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @author Monumental Team
/// @title MNT Auction
/// @notice  Per user auction contract handling auction life-cycle
/// @dev Initially inspired from the Avo Labs GmbH auction
contract MNTAuction is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    mapping(address => mapping(uint256 => Auction)) private nftContractAuctions;
    mapping(address => uint256) private failedTransferCredits;

    struct Auction {
        uint32 bidIncreasePercentage;
        uint32 auctionBidPeriod; //Increments the length of time the auction is open in which a new bid can be made after each bid.
        uint256 auctionStart;
        uint256 auctionEnd;
        uint128 reservedPrice;
        uint128 fixedPrice;
        uint128 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address whitelistedBuyer; // Only for fixed price. Define a whitelisted address
        address nftRecipient; //The bidder can specify a recipient for the NFT if their bid is successful.
        address ERC20Token; // The seller can specify an ERC20 token that can be used to bid or purchase the NFT.
        address[] feeRecipients;
        uint32[] feePercentages;
        bool done;
        bool auctionEndSettled;
    }

    struct InfoType {
        uint64 blockNumber;
        uint256 auctionStart;
        uint256 auctionEnd;
        uint128 reservedPrice;
        uint128 fixedPrice;
        uint128 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address whitelistedBuyer;
        bool isAuctionStarted;
        bool isAuctionEnded;
        bool hasBid;
        bool isAuctionDone;
        bool isFixedPrice;
        bool isWhiteListed;
    }

    struct InfoBoolType {
        bool isAuctionStarted;
        bool isAuctionEnded;
        bool hasBid;
        bool isAuctionDone;
        bool isFixedPrice;
        bool isWhiteListed;
    }

    uint32 private constant gasLimit = 1000000;

    uint64 private lastBlockNumber;

    /// ---------------------------
    /// Events
    /// ---------------------------

    event MNTTimedAuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 reservedPrice,
        uint128 fixedPrice,
        uint32 auctionBidPeriod,
        uint32 bidIncreasePercentage,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event MNTFixedPriceCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 fixedPrice,
        address whitelistedBuyer,
        address[] feeRecipients,
        uint32[] feePercentages
    );

    event MNTBidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        uint256 ethAmount,
        address erc20Token,
        uint256 tokenAmount
    );

    event MNTAuctionEndUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 auctionEndPeriod
    );

    event MNTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint128 nftHighestBid,
        address nftHighestBidder,
        address nftRecipient
    );

    event MNTClaimDone(address nftContractAddress, uint256 tokenId, address _nftSeller, address _nftHighestBidder, uint128 _nftHighestBid);

    event MNTAuctionWithdrawn
    (
        address nftContractAddress,
        uint256 tokenId,
        address nftOwner
    );

    event MNTBidWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address highestBidder
    );

    event MNTWhitelistUpdated(
        address nftContractAddress,
        uint256 tokenId,
        address newWhitelistedBuyer
    );

    event MNTReservedPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newMinPrice
    );

    event MNTFixedPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint128 newFixedPrice
    );
    event MNTHighestBidTaken(address nftContractAddress, uint256 tokenId, address _nftSeller, address _nftHighestBidder, uint128 _nftHighestBid);

    event MNTRoyaltiesInfo(address _receiver, uint256 _royalties);

    event MNTAuctionPaymentDetail(address _nftContractAddress, uint256 _tokenId, address _recipient, uint256 _amount, bool success);

    event MNTAuctionPaymentGlobal(address _nftContractAddress, uint256 _tokenId, address _seller, address _nftHighestBidder, uint256 _highestBid, uint256 fees, uint256 _royalties);

    event MNTWithDrawSuccess(address _recipient, uint256 _amount);

    /// ---------------------------
    /// MODIFIERS
    /// ---------------------------

    modifier isAuctionNotStartedByOwner(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(nftContractAuctions[_nftContractAddress][_tokenId].nftSeller != msg.sender, "Auction already started by owner");

        if (nftContractAuctions[_nftContractAddress][_tokenId].nftSeller != address(0)) {
            require(msg.sender == IERC721(_nftContractAddress).ownerOf(_tokenId), "Sender doesn't own NFT");

            _resetAuction(_nftContractAddress, _tokenId);
        }
        _;
    }

    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(_isAuctionOngoing(_nftContractAddress, _tokenId), "Auction has ended");
        _;
    }

    modifier auctionOver(address _nftContractAddress, uint256 _tokenId) {
        require(!_isAuctionOngoing(_nftContractAddress, _tokenId), "Auction is not yet over");
        _;
    }

    modifier auctionDone(address _nftContractAddress, uint256 _tokenId) {
        require(_isAuctionDone(_nftContractAddress, _tokenId), "Auction is not done");
        _;
    }

    modifier auctionActive(address _nftContractAddress, uint256 _tokenId) {
        require(!_isAuctionDone(_nftContractAddress, _tokenId), "Auction is inactive");
        _;
    }

    modifier checkPrice(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }
    /*
     * The minimum price must be 80% of the fixedPrice(if set).
     */
    modifier reservedPriceDoesNotExceedLimit(
        uint128 _fixedPrice,
        uint128 _reservedPrice
    ) {
        require(_fixedPrice == 0 || _getPortionOfBid(_fixedPrice, 8000) >= _reservedPrice, "MinPrice > 80% of fixedPrice");
        _;
    }

    modifier checkSellerAndOwner(address _nftContractAddress, uint256 _tokenId) {
        require(msg.sender != nftContractAuctions[_nftContractAddress][_tokenId].nftSeller, "Owner cannot bid on own NFT");
        require(_checkOwner(_nftContractAddress, _tokenId), "Seller is not the owner");
        _;
    }

    modifier onlySeller(address _nftContractAddress, uint256 _tokenId) {
        require(msg.sender == nftContractAuctions[_nftContractAddress][_tokenId].nftSeller, "Only nft seller");
        _;
    }
    /*
     * The bid amount was either equal the fixedPrice or it must be higher than the previous
     * bid by the specified bid increase percentage.
     */
    modifier bidAmountMeetsBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) {
        require(_doesBidMeetBidRequirements(_nftContractAddress, _tokenId, _tokenAmount), "Not enough funds to bid on NFT");
        _;
    }
    // check if the highest bidder can purchase this NFT.
    modifier onlyApplicableBuyer(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(!_isWhitelistedAuction(_nftContractAddress, _tokenId) || nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer == msg.sender, "Only the whitelisted buyer");
        _;
    }

    modifier reservedPriceNotMet(address _nftContractAddress, uint256 _tokenId) {
        require(!_isReservedPriceMet(_nftContractAddress, _tokenId), "A valid bid was made");
        _;
    }

    /*
     * Payment is accepted if the payment is made in the ERC20 token or ETH specified by the seller.
     * Early bids on NFTs not yet up for auction must be made in ETH.
     */
    modifier paymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    ) {
        require(_isPaymentAccepted(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount), "Bid to be in specified ERC20/Eth");
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    modifier increasePercentageAboveMinimum(uint32 _bidIncreasePercentage) {
        require(_bidIncreasePercentage >= 100, "Bid increase percentage too low");
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(_recipientsLength == _percentagesLength, "Recipients != percentages");
        _;
    }

    modifier isNotFixedPrice(address _nftContractAddress, uint256 _tokenId) {
        require(!_isFixedPrice(_nftContractAddress, _tokenId), "Unauthorized for fixed price");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// Initialize
    function initialize(address owner) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        transferOwnership(owner);
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}


    /// Checks if contract implements the ERC-2981 interface
    /// @param _contract contract address
    /// @return true if ERC-2981 interface is supported, false otherwise
    function _checkRoyalties(address _contract) internal returns (bool) {
        (bool success) = IERC2981(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    /// ---------------------------
    /// Internal check functions
    /// ---------------------------

    /// Check if the auction is ongoing
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isAuctionOngoing(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        uint256 auctionStartTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionStart;
        uint256 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;

        bool isSettled = nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled;

        return (auctionStartTimestamp <= block.timestamp && ((isSettled && block.timestamp < auctionEndTimestamp) || !isSettled));
    }

    /// Check if the auction is done
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isAuctionDone(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].done;
    }

    /// Check if a bid has been made
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isBidMade(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid > 0);
    }

    /// Check if a defined reserved price is met or not
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isReservedPriceMet(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        uint128 reservedPrice = nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice;
        return
        reservedPrice > 0 && (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >= reservedPrice);
    }

    /// Check if a defined fixed price is met or not
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isFixedPriceMet(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        uint128 fixedPrice = nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice;
        return
        fixedPrice > 0 && nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid >= fixedPrice;
    }

    /*
     * Check that a bid is applicable for the purchase of the NFT.
     * In the case of a sale: the bid needs to meet the fixedPrice.
     * In the case of an auction: the bid needs to be a % higher than the previous bid.
     */
    function _doesBidMeetBidRequirements(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        uint128 fixedPrice = nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice;
        //if fixedPrice is met, ignore increase percentage
        if (fixedPrice > 0 && (msg.value >= fixedPrice || _tokenAmount >= fixedPrice)) {
            return true;
        }
        //if the NFT is up for auction, the bid needs to be a % higher than the previous bid
        uint256 bidIncreaseAmount = (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid * (10000 + _getBidIncreasePercentage(_nftContractAddress, _tokenId))) / 10000;

        return (msg.value >= bidIncreaseAmount || _tokenAmount >= bidIncreaseAmount);
    }

    /// Check if the seller is still the owner
    /// If a transfer occurred during an ongoing auction without any bid done,
    /// this function ensure that no one can bid on it.
    /// The owner of the NFT will become the auction SC on a timed auction only
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _checkOwner(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        bool ownerIsSeller = IERC721(_nftContractAddress).ownerOf(_tokenId) == _nftSeller;
        bool ownerIsAuction = IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this);
        return (ownerIsSeller || ownerIsAuction);
    }


    /// Check if current auction is fixed price
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isFixedPrice(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice > 0 && nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice == 0);
    }

    /// Check if the auction has an whitelisted address defined
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isWhitelistedAuction(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return (nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer != address(0));
    }

    /// Check if the highest bidder is allowed to proceed
    /// If a whitelisted address is defined, ensure the highest bidder is the one.
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isHighestBidderAllowedToPurchaseNFT(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return
        (!_isWhitelistedAuction(_nftContractAddress, _tokenId)) || _isHighestBidderWhitelisted(_nftContractAddress, _tokenId);
    }

    /// Check if the highest bidder is whitelisted
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isHighestBidderWhitelisted(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (bool) {
        return (nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder == nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer);
    }


    /// Payment is accepted in the following scenarios:
    /// (1) Auction already created - can accept ETH or Specified Token
    ///     --------> Cannot bid with ETH & an ERC20 Token together in any circumstance<------
    /// (2) Auction not created - only ETH accepted (cannot early bid with an ERC20 Token
    /// (3) Cannot make a zero bid (no ETH or Token amount)
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _isPaymentAccepted(
        address _nftContractAddress,
        uint256 _tokenId,
        address _bidERC20Token,
        uint128 _tokenAmount
    ) internal view returns (bool) {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token;

        if (_isERC20Auction(auctionERC20Token)) {
            return msg.value == 0 && auctionERC20Token == _bidERC20Token && _tokenAmount > 0;
        } else {
            return msg.value != 0 && _bidERC20Token == address(0) && _tokenAmount == 0;
        }
    }

    function _isERC20Auction(address _auctionERC20Token)
    internal
    pure
    returns (bool)
    {
        return _auctionERC20Token != address(0);
    }

    /// Returns the percentage of the total bid (used to calculate fee payments)
    function _getPortionOfBid(uint256 _totalBid, uint256 _percentage)
    internal
    pure
    returns (uint256)
    {
        return (_totalBid * (_percentage)) / 10000;
    }

    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _getBidIncreasePercentage(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal view returns (uint32) {
        return nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage;
    }

    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _getAuctionBidPeriod(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (uint32)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod;
    }

    /// Return the recipient address.
    /// If not set, return the highest bidder address
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _getNftRecipient(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (address)
    {
        address nftRecipient = nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient;

        if (nftRecipient == address(0)) {
            return nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        } else {
            return nftRecipient;
        }
    }

    /// Transfer the NFT contract to the auction contact.
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _transferNftToAuctionContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        if (IERC721(_nftContractAddress).ownerOf(_tokenId) == _nftSeller) {
            IERC721(_nftContractAddress).transferFrom(_nftSeller, address(this), _tokenId);
            require(IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this), "nft transfer failed");
        } else {
            require(IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this), "Seller doesn't own NFT");
        }
    }

    /// Init timed auction
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _reservedPrice _reservedPrice
    /// @param _fixedPrice _fixedPrice
    /// @param _feeRecipients _feeRecipients
    /// @param _feePercentages _feePercentages
    function _initTimedAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _reservedPrice,
        uint128 _fixedPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    internal
    reservedPriceDoesNotExceedLimit(_fixedPrice, _reservedPrice)
    correctFeeRecipientsAndPercentages(_feeRecipients.length, _feePercentages.length)
    isFeePercentagesLessThanMaximum(_feePercentages)
    {
        if (_erc20Token != address(0)) {
            nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token = _erc20Token;
        }
        nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients = _feeRecipients;
        nftContractAuctions[_nftContractAddress][_tokenId].feePercentages = _feePercentages;
        nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice = _fixedPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice = _reservedPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;

    }

    /// Create timed auction
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _reservedPrice _reservedPrice
    /// @param _fixedPrice _fixedPrice
    /// @param _feeRecipients _feeRecipients
    /// @param _feePercentages _feePercentages
    function _createTimedAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _reservedPrice,
        uint128 _fixedPrice,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    ) internal {
        _initTimedAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _reservedPrice,
            _fixedPrice,
            _feeRecipients,
            _feePercentages
        );
        emit MNTTimedAuctionCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _reservedPrice,
            _fixedPrice,
            _getAuctionBidPeriod(_nftContractAddress, _tokenId),
            _getBidIncreasePercentage(_nftContractAddress, _tokenId),
            _feeRecipients,
            _feePercentages
        );
        _updateAuction(_nftContractAddress, _tokenId);
    }

    /// Create a timed auction
    /// @param _start _start
    /// @param _end _end
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _reservedPrice _reservedPrice
    /// @param _fixedPrice _fixedPrice
    /// @param _auctionBidPeriod _auctionBidPeriod
    /// @param _bidIncreasePercentage _bidIncreasePercentage
    /// @param _feeRecipients _feeRecipients
    /// @param _feePercentages _feePercentages
    function mntCreateTimedAuction(
        uint256 _start,
        uint256 _end,
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _reservedPrice,
        uint128 _fixedPrice,
        uint32 _auctionBidPeriod,
        uint32 _bidIncreasePercentage,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    external
    isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
    checkPrice(_reservedPrice)
    increasePercentageAboveMinimum(_bidIncreasePercentage)
    {

        nftContractAuctions[_nftContractAddress][_tokenId].auctionStart = _start;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = _end;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = _auctionBidPeriod;
        nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = _bidIncreasePercentage;
        nftContractAuctions[_nftContractAddress][_tokenId].done = false;

        nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled = false;

        _createTimedAuction(
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _reservedPrice,
            _fixedPrice,
            _feeRecipients,
            _feePercentages
        );

        _updateLastBlockNumber();
    }

    /// Init a fixed price auction
    /// @param _start _start
    /// @param _end _end
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _fixedPrice _fixedPrice
    /// @param _whitelistedBuyer _whitelistedBuyer
    /// @param _feeRecipients _feeRecipients
    /// @param _feePercentages _feePercentages
    function _initFixedPriceAuction(
        uint256 _start,
        uint256 _end,
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _fixedPrice,
        address _whitelistedBuyer,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    internal
    correctFeeRecipientsAndPercentages(_feeRecipients.length, _feePercentages.length)
    isFeePercentagesLessThanMaximum(_feePercentages)
    {
        if (_erc20Token != address(0)) {
            nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token = _erc20Token;
        }

        nftContractAuctions[_nftContractAddress][_tokenId].auctionStart = _start;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = _end;
        nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients = _feeRecipients;
        nftContractAuctions[_nftContractAddress][_tokenId].feePercentages = _feePercentages;
        nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice = _fixedPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer = _whitelistedBuyer;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;
        nftContractAuctions[_nftContractAddress][_tokenId].done = false;

        nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled = false;

    }

    /// Create a fixed price auction
    /// @param _start _start
    /// @param _end _end
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _fixedPrice _fixedPrice
    /// @param _whitelistedBuyer _whitelistedBuyer
    /// @param _feeRecipients _feeRecipients
    /// @param _feePercentages _feePercentages
    function mntCreateFixedPriceAuction(
        uint256 _start,
        uint256 _end,
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _fixedPrice,
        address _whitelistedBuyer,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    external
    isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
    checkPrice(_fixedPrice)
    {
        _initFixedPriceAuction(
            _start,
            _end,
            _nftContractAddress,
            _tokenId,
            _erc20Token,
            _fixedPrice,
            _whitelistedBuyer,
            _feeRecipients,
            _feePercentages
        );

        emit MNTFixedPriceCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _fixedPrice,
            _whitelistedBuyer,
            _feeRecipients,
            _feePercentages
        );
        //check if fixedPrice is meet and conclude sale, otherwise reverse the early bid
        if (_isBidMade(_nftContractAddress, _tokenId)) {
            //we only revert the underbid if the seller specifies a different
            //whitelisted buyer to the highest bidder
            if (_isHighestBidderAllowedToPurchaseNFT(
                    _nftContractAddress,
                    _tokenId
                )
            ) {
                if (_isFixedPriceMet(_nftContractAddress, _tokenId)) {
                    _transferNftToAuctionContract(
                        _nftContractAddress,
                        _tokenId
                    );
                    _transferNftAndPaySeller(_nftContractAddress, _tokenId);
                }
            } else {
                _reverseAndResetPreviousBid(_nftContractAddress, _tokenId);
            }
        }

        _updateLastBlockNumber();
    }

    /********************************************************************
     * Make bids with ETH or an ERC20 Token specified by the NFT seller.*
     * Additionally, a buyer can pay the asking price to conclude a sale*
     * of an NFT.                                                       *
     ********************************************************************/

    /// Place a bid
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _tokenAmount _tokenAmount
    function _placeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
    internal
    checkSellerAndOwner(_nftContractAddress, _tokenId)
    paymentAccepted(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount)
    bidAmountMeetsBidRequirements(_nftContractAddress, _tokenId, _tokenAmount)
    {

        _reversePreviousBidAndUpdateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);
        emit MNTBidMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            msg.value,
            _erc20Token,
            _tokenAmount
        );
        _updateAuction(_nftContractAddress, _tokenId);
    }

    /// Place a bid
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _erc20Token _erc20Token
    /// @param _tokenAmount _tokenAmount
    function mntPlaceBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
    external
    payable
    auctionOngoing(_nftContractAddress, _tokenId)
    auctionActive(_nftContractAddress, _tokenId)
    onlyApplicableBuyer(_nftContractAddress, _tokenId)
    {
        _placeBid(_nftContractAddress, _tokenId, _erc20Token, _tokenAmount);
        _updateLastBlockNumber();
    }

    /// Update an auction
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    function _updateAuction(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        // If fixed price is reached, process to NFT transfer and seller payment
        if (_isFixedPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _transferNftAndPaySeller(_nftContractAddress, _tokenId);
            return;
        }
        // if reserved price is reached , process to NFT transfer and start auction
        if (_isReservedPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }
    }

    /// Update the last blockNumber.
    function _updateLastBlockNumber()
    internal {
        lastBlockNumber = uint64(block.timestamp);
    }

    /// Set the auction end date (only on the first bid)
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _settleAuctionEnd(address _nftContractAddress, uint256 _tokenId)
    internal
    {
        if (!nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled) {
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = _getAuctionBidPeriod(_nftContractAddress, _tokenId) + uint64(block.timestamp);
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled = true;
        }

    }

    /// Update auction end
    /// During the last 10 minuts, if a bid occured, auction end time is extended with 10 min more
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _updateAuctionEnd(address _nftContractAddress, uint256 _tokenId)
    internal
    {
        _settleAuctionEnd(_nftContractAddress, _tokenId);

        uint256 diff = 0;
        if (nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd > block.timestamp) {
            diff = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd - block.timestamp;
        }

        if (0 < diff && diff <= 600) {
            //nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = _getAuctionBidPeriod(_nftContractAddress, _tokenId) + uint64(block.timestamp);
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd = /*diff*/ 600 + nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;

            emit MNTAuctionEndUpdated(
                _nftContractAddress,
                _tokenId,
                nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd
            );
        }

    }

    /// Reset auction
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _resetAuction(address _nftContractAddress, uint256 _tokenId)
    internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].auctionBidPeriod = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].bidIncreasePercentage = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token = address(0);
    }

    /// Set an auction as done
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _setAuctionDone(address _nftContractAddress, uint256 _tokenId)
    internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId].done = true;
    }

    /// Reset all bids
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _resetBids(address _nftContractAddress, uint256 _tokenId)
    internal
    {
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
        nftContractAuctions[_nftContractAddress][_tokenId].nftRecipient = address(0);
    }

    /// Update highest bid
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    /// @param _tokenAmount amount
    function _updateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            IERC20(auctionERC20Token).transferFrom(msg.sender, address(this), _tokenAmount);
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = _tokenAmount;
        } else {
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid = uint128(msg.value);
        }
        nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder = msg.sender;
    }

    /// Reverse and reset previous bid
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    function _reverseAndResetPreviousBid(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;

        uint128 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);
    }

    /// Reverse previous bid and update highest bid
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _tokenAmount _tokenAmount
    function _reversePreviousBidAndUpdateHighestBid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _tokenAmount
    ) internal {
        address prevNftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;

        uint256 prevNftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _updateHighestBid(_nftContractAddress, _tokenId, _tokenAmount);

        if (prevNftHighestBidder != address(0)) {
            _payout(_nftContractAddress, _tokenId, prevNftHighestBidder, prevNftHighestBid);
        }
    }

    /// Transfer an NFT and pay the seller
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payFeesAndSeller(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBidder, _nftHighestBid);
        IERC721(_nftContractAddress).transferFrom(address(this), _nftRecipient, _tokenId);

        _resetAuction(_nftContractAddress, _tokenId);
        _setAuctionDone(_nftContractAddress, _tokenId);

        emit MNTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid,
            _nftHighestBidder,
            _nftRecipient
        );
    }

    /// Pay fees and seller
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _nftSeller _nftSeller
    /// @param _nftHighestBidder _nftHighestBidder
    /// @param _highestBid _highestBid
    function _payFeesAndSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        address _nftHighestBidder,
        uint256 _highestBid
    ) internal {
        uint256 feesPaid;

        // Pay royalties base on the highest bid price
        uint256 royalties = 0;
        if (_checkRoyalties(_nftContractAddress)) {
            // Get amount of royalties to pays and recipient
            (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(_nftContractAddress).royaltyInfo(_tokenId, _highestBid);

            emit MNTRoyaltiesInfo(royaltiesReceiver, royaltiesAmount);

            // Transfer royalties to right holder if not zero
            if (royaltiesAmount > 0) {
                royalties = royaltiesAmount;
                bool success = _payout(_nftContractAddress, _tokenId, royaltiesReceiver, royaltiesAmount);
                emit MNTAuctionPaymentDetail(_nftContractAddress, _tokenId, royaltiesReceiver, royaltiesAmount, success);
            }
        }

        // Pay platform fees
        for (uint256 i = 0; i < nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients.length; i++) {
            uint256 fee = _getPortionOfBid(_highestBid, nftContractAuctions[_nftContractAddress][_tokenId].feePercentages[i]);
            feesPaid = feesPaid + fee;
            bool success = _payout(_nftContractAddress, _tokenId, nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients[i], fee);
            emit MNTAuctionPaymentDetail(_nftContractAddress, _tokenId, nftContractAuctions[_nftContractAddress][_tokenId].feeRecipients[i], fee, success);
        }

        // Pay the seller
        bool success = _payout(_nftContractAddress, _tokenId, _nftSeller, (_highestBid - feesPaid - royalties));
        emit MNTAuctionPaymentDetail(_nftContractAddress, _tokenId, _nftSeller, (_highestBid - feesPaid - royalties), success);

        emit MNTAuctionPaymentGlobal(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBidder, _highestBid, feesPaid, royalties);

    }

    /// Send funds to recipient
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    /// @param _recipient recipient address
    /// @param _amount amount
    /// @notice Send funds to recipient
    function _payout(
        address _nftContractAddress,
        uint256 _tokenId,
        address _recipient,
        uint256 _amount
    ) internal
    returns (bool)
    {
        address auctionERC20Token = nftContractAuctions[_nftContractAddress][_tokenId].ERC20Token;
        if (_isERC20Auction(auctionERC20Token)) {
            bool success = IERC20(auctionERC20Token).transfer(_recipient, _amount);
            return success;
        } else {
            // attempt to send the funds to the recipient
            (bool success,) = payable(_recipient).call{value : _amount, gas : gasLimit}("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[_recipient] = failedTransferCredits[_recipient] + _amount;
            }
            return success;
        }
    }

    /// Claim an auction
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    function mntClaim(address _nftContractAddress, uint256 _tokenId)
    external
    auctionOver(_nftContractAddress, _tokenId)
    {
        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        //address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;

        _transferNftAndPaySeller(_nftContractAddress, _tokenId);

        _updateLastBlockNumber();

        emit MNTClaimDone(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBidder, _nftHighestBid);
    }

    /// Withdraw auction
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function mntWithdrawAuction(address _nftContractAddress, uint256 _tokenId)
    external
    {
        //only the NFT owner can prematurely close and auction
        require(IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        _resetAuction(_nftContractAddress, _tokenId);
        _setAuctionDone(_nftContractAddress, _tokenId);

        _updateLastBlockNumber();

        emit MNTAuctionWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    /// Withdraw bid function
    /// @dev Not used
    function mntWithdrawBid(address _nftContractAddress, uint256 _tokenId)
    external
    reservedPriceNotMet(_nftContractAddress, _tokenId)
    {
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        require(msg.sender == nftHighestBidder, "Cannot withdraw funds");

        uint128 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;
        _resetBids(_nftContractAddress, _tokenId);

        _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);

        _updateLastBlockNumber();

        emit MNTBidWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    /// Update white list buyer
    /// @dev Not used
    function mntUpdateWhitelistedBuyer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _newWhitelistedBuyer
    ) external onlySeller(_nftContractAddress, _tokenId) {
        require(_isFixedPrice(_nftContractAddress, _tokenId), "Not a fixed price");
        nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer = _newWhitelistedBuyer;
        //if an underbid is by a non whitelisted buyer,reverse that bid
        address nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        uint128 nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;

        if (nftHighestBid > 0 && !(nftHighestBidder == _newWhitelistedBuyer)) {
            //we only revert the underbid if the seller specifies a different
            //whitelisted buyer to the highest bider

            _resetBids(_nftContractAddress, _tokenId);

            _payout(_nftContractAddress, _tokenId, nftHighestBidder, nftHighestBid);
        }

        _updateLastBlockNumber();

        emit MNTWhitelistUpdated(
            _nftContractAddress,
            _tokenId,
            _newWhitelistedBuyer
        );
    }

    /// Update minimum price
    /// @dev Not used
    function mntUpdateMinimumPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newMinPrice
    )
    external
    onlySeller(_nftContractAddress, _tokenId)
    reservedPriceNotMet(_nftContractAddress, _tokenId)
    isNotFixedPrice(_nftContractAddress, _tokenId)
    checkPrice(_newMinPrice)
    reservedPriceDoesNotExceedLimit(nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice, _newMinPrice)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice = _newMinPrice;

        emit MNTReservedPriceUpdated(_nftContractAddress, _tokenId, _newMinPrice);

        if (_isReservedPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _updateAuctionEnd(_nftContractAddress, _tokenId);
        }

        _updateLastBlockNumber();
    }

    function mntUpdateFixedPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _newFixedPrice
    )
    external
    onlySeller(_nftContractAddress, _tokenId)
    checkPrice(_newFixedPrice)
    reservedPriceDoesNotExceedLimit(_newFixedPrice, nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice)
    {
        nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice = _newFixedPrice;
        emit MNTFixedPriceUpdated(_nftContractAddress, _tokenId, _newFixedPrice);
        if (_isFixedPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftToAuctionContract(_nftContractAddress, _tokenId);
            _transferNftAndPaySeller(_nftContractAddress, _tokenId);
        }

        _updateLastBlockNumber();

    }

    /// When seller decide to end an auction, this function takes the highest bid and terminate auction
    /// @param _nftContractAddress _nftContractAddress
    /// @param _tokenId _tokenId
    function mntTakeHighestBid(address _nftContractAddress, uint256 _tokenId)
    external
    onlySeller(_nftContractAddress, _tokenId)
    {
        require(_isBidMade(_nftContractAddress, _tokenId), "cannot payout 0 bid");

        address _nftSeller = nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
        address _nftHighestBidder = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder;
        //address _nftRecipient = _getNftRecipient(_nftContractAddress, _tokenId);
        uint128 _nftHighestBid = nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid;

        _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        _transferNftAndPaySeller(_nftContractAddress, _tokenId);

        _updateLastBlockNumber();

        emit MNTHighestBidTaken(_nftContractAddress, _tokenId, _nftSeller, _nftHighestBidder, _nftHighestBid);
    }

    /// If the transfer of a bid has failed, allow the recipient to reclaim their amount later.
    function mntWithdrawAllFailedCredits(/*uint32 gasLimit*/) external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        (bool successfulWithdraw,) = msg.sender.call{value : amount, gas : gasLimit}("");

        if (successfulWithdraw) {
            emit MNTWithDrawSuccess(msg.sender, amount);
        }
        require(successfulWithdraw, "withdraw failed");

        failedTransferCredits[msg.sender] = 0;

        _updateLastBlockNumber();
    }

    /// Get the last blockNumber in which the auction state has changed
    function getLastBlockNumber() public view returns (uint64 blockNumber){
        return lastBlockNumber;
    }

    /// Overview of the auction state
    /// @param _nftContractAddress contract address
    /// @param _tokenId tokenId
    function getInfo(address _nftContractAddress, uint256 _tokenId) public view returns (InfoType memory){

        uint256 auctionStartTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionStart;
        uint256 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;

        bool isSettled = nftContractAuctions[_nftContractAddress][_tokenId].auctionEndSettled;

        bool isAuctionStarted = auctionStartTimestamp <= block.timestamp;
        bool isAuctionEnded = isSettled && auctionEndTimestamp < block.timestamp && !_isFixedPrice(_nftContractAddress, _tokenId);
        bool hasBid = _isBidMade(_nftContractAddress, _tokenId);
        bool isAuctionDone = nftContractAuctions[_nftContractAddress][_tokenId].done;
        bool isFixedPrice = _isFixedPrice(_nftContractAddress, _tokenId);

        bool isWhiteListed = _isWhitelistedAuction(_nftContractAddress, _tokenId);

        InfoBoolType memory infoBoolType = InfoBoolType(
            isAuctionStarted,
            isAuctionEnded,
            hasBid,
            isAuctionDone,
            isFixedPrice,
            isWhiteListed
        );

        return _fillInfoStruct(_nftContractAddress, _tokenId, lastBlockNumber, infoBoolType);
    }

    /// Fill the info struct
    function _fillInfoStruct(
        address _nftContractAddress,
        uint256 _tokenId,
        uint64 _lastBlockNumber,
        InfoBoolType memory infoBoolType
    ) internal view returns (InfoType memory){
        InfoType memory info = InfoType(
            _lastBlockNumber,
            nftContractAuctions[_nftContractAddress][_tokenId].auctionStart,
            nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd,
            nftContractAuctions[_nftContractAddress][_tokenId].reservedPrice,
            nftContractAuctions[_nftContractAddress][_tokenId].fixedPrice,
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBid,
            nftContractAuctions[_nftContractAddress][_tokenId].nftHighestBidder,
            nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,
            nftContractAuctions[_nftContractAddress][_tokenId].whitelistedBuyer,
            infoBoolType.isAuctionStarted,
            infoBoolType.isAuctionEnded,
            infoBoolType.hasBid,
            infoBoolType.isAuctionDone,
            infoBoolType.isFixedPrice,
            infoBoolType.isWhiteListed
        );
        return info;
    }

}