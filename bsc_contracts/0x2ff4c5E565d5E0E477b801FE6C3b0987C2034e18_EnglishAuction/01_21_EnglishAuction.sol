//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./components/WhitelistedAddresses.sol";
import "./components/IsPausable.sol";
import "./components/PriceGetter.sol";
import "./interfaces/IOuterRingNFT.sol";

/// @title English Auction Smart Contract
/// @author eludius18lab
/// @notice English Auction --> MarketPlace
/// @dev This Contract will be used to create and Bid NFTs English Auction

//============== ENGLISH AUCTION ==============

contract EnglishAuction is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    WhitelistedAddresses,
    IsPausable,
    PriceGetter,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //============== STRUCTS ==============

    struct Auction {
        uint256 auctionEnd;
        uint256 minPrice;
        uint256 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address ERC20Token;
        address feeRecipients;
        uint32 feePercentages;
        uint32 bidIncreasePercentageInBP;
    }

    struct AuctionTime {
        bool active;
        uint256 price;
    }

    //============== MAPPINGS ==============

    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    mapping(uint256 => AuctionTime) public mapAuctionTime;

    //============== VARIABLES ==============
    address public defaultFeeRecipient;
    uint32 public minExtraBidPercentages;
    uint32 public maxExtraBidPercentages;
    uint32 public defaultFeePercentages;
    uint32 public firstOwnerFeePercentage;
    bool public initialized;

    //============== ERRORS ==============

    error NotNFTOwner();

    //============== EVENTS ==============

    event NftAuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint256 minPrice,
        uint32 auctionBidPeriod,
        uint32 bidIncreasePercentageInBP,
        address feeRecipients,
        uint32 feePercentages
    );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        address erc20Token,
        uint256 tokenAmount
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 nftHighestBid,
        address nftHighestBidder
    );

    event ChangedDefaultFeePercentages(uint32 newFee);
    event ChangedDefaultFeeRecipient(address newFee);
    event ChangedFirstOwnerFeePercentage(uint32 newFee);
    event ChangedMaxBidPercentages(uint32 newMaxBidPercentage);
    event ChangedMinBidPercentages(uint32 newMinBidPercentage);

    //============== MODIFIERS ==============

    modifier isPercentageInBounds(uint256 percentage) {
        require(
            percentage >= 0 && percentage <= 10000,
            "Error: incorrect percentage"
        );
        _;
    }

    modifier isPercentageBidCorrect(uint32 percentage) {
        require(
            percentage > 0 && percentage <= 10000,
            "Error: incorrect percentage"
        );
        _;
    }

    modifier isInitialized() {
        require(initialized, "Error: contract not initialized");
        _;
    }

    modifier auctionOngoing(address nftContractAddress, uint256 tokenId) {
        require(
            _isAuctionOngoing(nftContractAddress, tokenId),
            "Auction has ended"
        );
        _;
    }

    modifier notNftSeller(address nftContractAddress, uint256 tokenId) {
        require(
            msg.sender !=
                nftContractAuctions[nftContractAddress][tokenId].nftSeller,
            "Owner cannot bid on own NFT"
        );
        _;
    }

    modifier isNFTOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        if (spender != IERC721Upgradeable(nftAddress).ownerOf(tokenId)) {
            revert NotNFTOwner();
        }
        _;
    }

    modifier doesBidMeetBidRequirements(
        address nftContractAddress,
        uint256 tokenId,
        uint256 tokenAmount
    ) {
        Auction memory nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];
        uint256 bidIncreaseAmount = (nftContractAuction.nftHighestBid *
            (10000 + nftContractAuction.bidIncreasePercentageInBP)) / 10000;
        require(tokenAmount > 0, "Not enough funds to bid on NFT");
        require(
            tokenAmount >= bidIncreaseAmount,
            "Not enough funds to bid on NFT"
        );
        require(
            tokenAmount >= nftContractAuction.minPrice,
            "Not enough funds to bid on NFT"
        );
        _;
    }

    modifier isAuctionOver(address nftContractAddress, uint256 tokenId) {
        require(
            !_isAuctionOngoing(nftContractAddress, tokenId),
            "Auction is not yet over"
        );
        _;
    }

    modifier outerRingNFTHasFirstOwner(address nftAddress, uint256 tokenId) {
        if (outerRingNFTs[nftAddress]) {
            require(
                IOuterRingNFT(nftAddress).getFirstOwner(tokenId) != address(0),
                "first owner must be != 0"
            );
        }
        _;
    }

    //============== CONSTRUCTOR ==============

    constructor() {
        _disableInitializers();
    }

    //============== INITIALIZE ==============

    function initialize(
        uint32 maxExtraBidPercentages_,
        uint32 minExtraBidPercentages_,
        uint32 defaultFeePercentages_,
        address defaultFeeRecipient_,
        uint32 firstOwnerFeePercentage_,
        address aggregatorAddress
    )
        external
        initializer
        isPercentageBidCorrect(maxExtraBidPercentages_)
        isPercentageBidCorrect(minExtraBidPercentages_)
        isPercentageInBounds(defaultFeePercentages_)
        isPercentageInBounds(firstOwnerFeePercentage_)
    {
        __Ownable_init();
        __PriceGetter_init(aggregatorAddress);
        __WhitelistedAddresses_init();
        __IsPausable_init();
        require(
            defaultFeeRecipient_ != address(0),
            "Error: invalid fee recipient"
        );
        require(aggregatorAddress != address(0), "Error: invalid aggregator");
        require(
            defaultFeePercentages_ + firstOwnerFeePercentage_ <= 10000,
            "Error: incorrect amount"
        );
        maxExtraBidPercentages = maxExtraBidPercentages_;
        minExtraBidPercentages = minExtraBidPercentages_;
        defaultFeePercentages = defaultFeePercentages_;
        defaultFeeRecipient = defaultFeeRecipient_;
        firstOwnerFeePercentage = firstOwnerFeePercentage_;
        initialized = true;
    }

    receive() external payable {}

    //============== EXTERNAL FUNCTIONS ==============

    /// Creates a new auction
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    /// @param erc20Token Token used to pay
    /// @param minPrice The minimum price for the auction
    /// @param auctionBidPeriod Duration of the auction
    /// @param bidIncreasePercentageInBP Percentage to increase between bids the number is in basis points
    function createNewNftAuction(
        address nftContractAddress,
        uint256 tokenId,
        address erc20Token,
        uint256 minPrice,
        uint32 auctionBidPeriod,
        uint32 bidIncreasePercentageInBP
    )
        external
        payable
        whenNotPaused
        isInitialized
        isWhitelistedToken(erc20Token)
        isWhitelistedNFT(nftContractAddress)
        outerRingNFTHasFirstOwner(nftContractAddress, tokenId)
    {
        require(minPrice > 0, "Min price must be > 0");
        // The bid increase percentage is defined in basis points
        require(
            bidIncreasePercentageInBP >= minExtraBidPercentages &&
                bidIncreasePercentageInBP <= maxExtraBidPercentages,
            "Bid Increase Percentage should be between range"
        );
        AuctionTime memory auctionTime = mapAuctionTime[auctionBidPeriod];
        require(auctionTime.active, "Not a valid bid period");
        _setupAuction(
            nftContractAddress,
            tokenId,
            erc20Token,
            minPrice,
            auctionBidPeriod,
            bidIncreasePercentageInBP
        );
        _auctionTimePayment(auctionTime.price);
        emit NftAuctionCreated(
            nftContractAddress,
            tokenId,
            msg.sender,
            erc20Token,
            minPrice,
            auctionBidPeriod,
            bidIncreasePercentageInBP,
            defaultFeeRecipient,
            defaultFeePercentages
        );
    }

    /// Makes a new bid with ERC20 token
    /// @param nftContractAddress Contract address on auction
    /// @param tokenId Identifier of the NFT
    /// @param tokenAmount The amount of tokens to bid
    function makeBid(
        address nftContractAddress,
        uint256 tokenId,
        uint256 tokenAmount
    ) external nonReentrant {
        address erc20Token = nftContractAuctions[nftContractAddress][tokenId]
            .ERC20Token;
        require(erc20Token != address(0), "Only ERC20 Payment");
        _reversePreviousBidAndUpdateHighestBid(
            nftContractAddress,
            tokenId,
            tokenAmount
        );
        emit BidMade(
            nftContractAddress,
            tokenId,
            msg.sender,
            erc20Token,
            tokenAmount
        );
    }

    /// Makes a new bid with BNB
    /// @param nftContractAddress Contract address on auction
    /// @param tokenId Identifier of the NFT
    function makeBNBBid(address nftContractAddress, uint256 tokenId)
        external
        payable
        nonReentrant
    {
        address erc20Token = nftContractAuctions[nftContractAddress][tokenId]
            .ERC20Token;
        require(erc20Token == address(0), "Only BNB Payment");
        _reversePreviousBidAndUpdateHighestBid(
            nftContractAddress,
            tokenId,
            msg.value
        );
        emit BidMade(
            nftContractAddress,
            tokenId,
            msg.sender,
            erc20Token,
            msg.value
        );
    }

    /// Settles the auction
    /// @param nftContractAddress Contract address on auction
    /// @param tokenId Identifier of the NFT
    function settleAuction(address nftContractAddress, uint256 tokenId)
        external
        whenNotPaused
        isAuctionOver(nftContractAddress, tokenId)
    {
        Auction memory nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];
        require(
            msg.sender == nftContractAuction.nftHighestBidder ||
                msg.sender == nftContractAuction.nftSeller,
            "Only NFT Highest Bidder or Seller"
        );
        _transferNftAndPaySeller(nftContractAddress, tokenId);
    }

    /// Change the default fee percentage
    /// @param newDefaultFeePercentages New fee percentage
    function changeDefaultFeePercentages(uint32 newDefaultFeePercentages)
        external
        onlyOwner
        isPercentageInBounds(newDefaultFeePercentages)
    {
        require(
            newDefaultFeePercentages + firstOwnerFeePercentage <= 10000,
            "Error: incorrect amount"
        );
        defaultFeePercentages = newDefaultFeePercentages;
        emit ChangedDefaultFeePercentages(defaultFeePercentages);
    }

    /// Change the default fee recipient
    /// @param newDefaultFeeRecipient New address for recipient
    function changeDefaultFeeRecipient(address newDefaultFeeRecipient)
        external
        onlyOwner
    {
        require(
            newDefaultFeeRecipient != address(0),
            "fee recipient must be != address(0)"
        );
        defaultFeeRecipient = newDefaultFeeRecipient;
        emit ChangedDefaultFeeRecipient(defaultFeeRecipient);
    }

    /// Change the first owner fee
    /// @param newFirstOwnerFeePercentage New fee percentage for first owner
    function changeFirstOwnerFeePercentage(uint32 newFirstOwnerFeePercentage)
        external
        onlyOwner
        isPercentageInBounds(newFirstOwnerFeePercentage)
    {
        require(
            newFirstOwnerFeePercentage + defaultFeePercentages <= 10000,
            "Error: incorrect amount"
        );
        firstOwnerFeePercentage = newFirstOwnerFeePercentage;
        emit ChangedFirstOwnerFeePercentage(firstOwnerFeePercentage);
    }

    /// Change or add the data time and price for auction
    /// @param auctionBidPeriod Duration of the auction
    /// @param active Status of the auction
    /// @param price Comission price for aditional period
    function changeAuctionTimeMap(
        uint256 auctionBidPeriod,
        bool active,
        uint256 price
    ) external onlyOwner {
        AuctionTime storage auctionTime = mapAuctionTime[auctionBidPeriod];
        auctionTime.active = active;
        auctionTime.price = price;
    }

    /// Change the max bound for bid percentage
    /// @param newMaxExtraBidPercentage The max limit percentage
    function changeMaxExtraBidPercentages(uint32 newMaxExtraBidPercentage)
        external
        onlyOwner
        isPercentageBidCorrect(newMaxExtraBidPercentage)
    {
        require(
            newMaxExtraBidPercentage >= minExtraBidPercentages,
            "Error: bid max percentage incorrect"
        );
        maxExtraBidPercentages = newMaxExtraBidPercentage;
        emit ChangedMaxBidPercentages(maxExtraBidPercentages);
    }

    /// Change the min bound for bid percentage
    /// @param newMinExtraBidPercentage The min limit percentage
    function changeMinExtraBidPercentages(uint32 newMinExtraBidPercentage)
        external
        onlyOwner
        isPercentageBidCorrect(newMinExtraBidPercentage)
    {
        require(
            newMinExtraBidPercentage <= maxExtraBidPercentages,
            "Error: bid min percentage incorrect"
        );
        minExtraBidPercentages = newMinExtraBidPercentage;
        emit ChangedMinBidPercentages(minExtraBidPercentages);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    //============== INTERNAL FUNCTIONS ==============

    /// Function responsible to check if auction is on going
    /// @param nftContractAddress Contract address on auction
    /// @param tokenId Identifier of the NFT
    function _isAuctionOngoing(address nftContractAddress, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        uint256 auctionEndTimestamp = nftContractAuctions[nftContractAddress][
            tokenId
        ].auctionEnd;
        return (block.timestamp < auctionEndTimestamp);
    }

    /// Auxiliar function to get bid portion
    /// @param totalBid The last highest bid
    /// @param percentage Quantity to extract from totalBid
    function _getPortionOfBid(uint256 totalBid, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (totalBid * (percentage)) / 10000;
    }

    /// Internal function to set up the auction data
    /// @param nftContractAddress Contract address that will be put on auction
    /// @param tokenId Identifier of the NFT
    /// @param erc20Token Token used to pay
    /// @param minPrice The minimum price for the auction
    /// @param auctionBidPeriod Duration of the auction
    /// @param bidIncreasePercentageInBP Is the percentage to increase between bids
    function _setupAuction(
        address nftContractAddress,
        uint256 tokenId,
        address erc20Token,
        uint256 minPrice,
        uint32 auctionBidPeriod,
        uint32 bidIncreasePercentageInBP
    ) internal isNFTOwner(nftContractAddress, tokenId, msg.sender) {
        Auction storage nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];
        nftContractAuction
            .bidIncreasePercentageInBP = bidIncreasePercentageInBP;
        nftContractAuction.ERC20Token = erc20Token;
        nftContractAuction.feeRecipients = defaultFeeRecipient;
        nftContractAuction.feePercentages = defaultFeePercentages;
        nftContractAuction.minPrice = minPrice;
        nftContractAuction.nftSeller = msg.sender;
        nftContractAuction.auctionEnd = auctionBidPeriod + block.timestamp;
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
    }

    /// Internal function for payment the comission depending on auction period
    /// @param price The price that user has to pay
    function _auctionTimePayment(uint256 price) internal {
        if (price > 0) {
            uint256 comission = convertBUSDToBNB(price);
            require(msg.value == comission, "Not enough BNB");
            (bool success, ) = payable(defaultFeeRecipient).call{
                value: comission
            }("");
            require(success, "error sending");
        }
    }

    /// Internal function to reset the auction data
    /// @param nftContractAddress Contract address auctioned
    /// @param tokenId Identifier of the NFT
    function _resetAuction(address nftContractAddress, uint256 tokenId)
        internal
    {
        Auction storage nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];
        nftContractAuction.minPrice = 0;
        nftContractAuction.auctionEnd = 0;
        nftContractAuction.bidIncreasePercentageInBP = 0;
        nftContractAuction.nftSeller = address(0);
        nftContractAuction.ERC20Token = address(0);
        nftContractAuction.feePercentages = 0;
        nftContractAuction.feeRecipients = address(0);
    }

    /// Internal function to reset the bids info
    /// @param nftContractAddress Contract address auctioned
    /// @param tokenId Identifier of the NFT
    function _resetBids(address nftContractAddress, uint256 tokenId) internal {
        nftContractAuctions[nftContractAddress][tokenId]
            .nftHighestBidder = address(0);
        nftContractAuctions[nftContractAddress][tokenId].nftHighestBid = 0;
    }

    /// Internal function for updating the bids data if new bid is greater than last bid
    /// @param nftContractAddress Contract address auctioned
    /// @param tokenId Identifier of the NFT
    /// @param tokenAmount Amount of tokens for the bid
    function _updateHighestBid(
        address nftContractAddress,
        uint256 tokenId,
        uint256 tokenAmount
    ) internal {
        Auction storage auction = nftContractAuctions[nftContractAddress][
            tokenId
        ];
        auction.nftHighestBid = tokenAmount;
        auction.nftHighestBidder = msg.sender;
        if (auction.ERC20Token != address(0)) {
            IERC20Upgradeable(auction.ERC20Token).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmount
            );
        } else {
            (bool success, ) = payable(address(this)).call{value: tokenAmount}(
                ""
            );
            require(success, "error sending");
        }
    }

    /// Internal function to extract the fees and reset bid data
    /// @param nftContractAddress Contract address auctioned
    /// @param tokenId Identifier of the NFT
    function _reverseAndResetPreviousBid(
        address nftContractAddress,
        uint256 tokenId,
        address prevNftHighestBidder,
        uint256 prevNftHighestBid
    ) internal {
        Auction memory nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];
        if (nftContractAuction.ERC20Token != address(0)) {
            _payout(
                prevNftHighestBidder,
                prevNftHighestBid,
                nftContractAuction.ERC20Token
            );
        } else {
            (bool success, ) = payable(prevNftHighestBidder).call{
                value: prevNftHighestBid
            }("");
            require(success, "error sending");
        }
    }

    /// Internal function to return the previous bid and update the highest bid
    /// @param nftContractAddress Contract address auctioned
    /// @param tokenId Identifier of the NFT
    /// @param tokenAmount The amount of the bid
    function _reversePreviousBidAndUpdateHighestBid(
        address nftContractAddress,
        uint256 tokenId,
        uint256 tokenAmount
    )
        internal
        whenNotPaused
        auctionOngoing(nftContractAddress, tokenId)
        notNftSeller(nftContractAddress, tokenId)
        doesBidMeetBidRequirements(nftContractAddress, tokenId, tokenAmount)
    {
        address prevNftHighestBidder = nftContractAuctions[nftContractAddress][
            tokenId
        ].nftHighestBidder;
        uint256 prevNftHighestBid = nftContractAuctions[nftContractAddress][
            tokenId
        ].nftHighestBid;
        _updateHighestBid(nftContractAddress, tokenId, tokenAmount);
        if (prevNftHighestBidder != address(0)) {
            _reverseAndResetPreviousBid(
                nftContractAddress,
                tokenId,
                prevNftHighestBidder,
                prevNftHighestBid
            );
        }
    }

    /// Internal function to pay the fees and transfer the NFT to the highest bidder
    /// @param nftContractAddress Contract address auctioned
    /// @param tokenId Identifier of the NFT
    function _transferNftAndPaySeller(
        address nftContractAddress,
        uint256 tokenId
    ) internal {
        Auction memory nftContractAuction = nftContractAuctions[
            nftContractAddress
        ][tokenId];

        _resetBids(nftContractAddress, tokenId);
        _resetAuction(nftContractAddress, tokenId);
        if (nftContractAuction.nftHighestBid != 0) {
            _payFeesAndSeller(
                nftContractAddress,
                tokenId,
                nftContractAuction.nftSeller,
                nftContractAuction.nftHighestBid,
                nftContractAuction.ERC20Token
            );
            IERC721Upgradeable(nftContractAddress).safeTransferFrom(
                address(this),
                nftContractAuction.nftHighestBidder,
                tokenId
            );
        } else {
            IERC721Upgradeable(nftContractAddress).safeTransferFrom(
                address(this),
                nftContractAuction.nftSeller,
                tokenId
            );
        }
        emit NFTTransferredAndSellerPaid(
            nftContractAddress,
            tokenId,
            nftContractAuction.nftSeller,
            nftContractAuction.nftHighestBid,
            nftContractAuction.nftHighestBidder
        );
    }

    /// Makes payment of the NFT fees
    /// @param nftContractAddress Contract address of the NFT on sale
    /// @param tokenId Identifier of the NFT
    /// @param nftSeller Seller of the NFT who receives the fee
    /// @param highestBid The highest bid amount
    function _payFeesAndSeller(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 highestBid,
        address erc20Token
    ) internal {
        uint256 fee = _getPortionOfBid(highestBid, defaultFeePercentages);
        uint256 firstOwnerFee;
        if (outerRingNFTs[nftContractAddress]) {
            firstOwnerFee = _getPortionOfBid(
                highestBid,
                firstOwnerFeePercentage
            );
            _payout(
                IOuterRingNFT(nftContractAddress).getFirstOwner(tokenId),
                firstOwnerFee,
                erc20Token
            );
        }
        _payout(defaultFeeRecipient, fee, erc20Token);
        _payout(
            nftSeller,
            (highestBid - fee - firstOwnerFee),
            erc20Token
        );
    }

    /// Makes the transfer of the tokens ERC20 or BNB
    /// @param recipient Address that receives tokens
    /// @param amountPaid Amount to transfer
    function _payout(
        address recipient,
        uint256 amountPaid,
        address auctionERC20Token
    ) internal {
        if (auctionERC20Token != address(0)) {
            IERC20Upgradeable(auctionERC20Token).safeTransfer(
                recipient,
                amountPaid
            );
        } else {
            (bool success, ) = payable(recipient).call{value: amountPaid}("");
            require(success, "error sending");
        }
    }
}