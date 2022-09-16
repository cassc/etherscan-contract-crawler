// SPDX-License-Identifier: MIT
/*
_____   ______________________   ____________________________   __
___  | / /__  ____/_  __ \__  | / /__  __ \__    |___  _/__  | / /
__   |/ /__  __/  _  / / /_   |/ /__  /_/ /_  /| |__  / __   |/ / 
_  /|  / _  /___  / /_/ /_  /|  / _  _, _/_  ___ |_/ /  _  /|  /  
/_/ |_/  /_____/  \____/ /_/ |_/  /_/ |_| /_/  |_/___/  /_/ |_/  
 ___________________________________________________________ 
  S Y N C R O N A U T S: The Bravest Souls in the Metaverse

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./IAffiliate.sol";

interface IAddressRegistry {
    function affiliate() external view returns (address);

    function marketplace() external view returns (address);

    function tokenRegistry() external view returns (address);
}

interface IMarketplace {
    function minters(address, uint256) external view returns (address);

    function royalties(address, uint256) external view returns (uint16);

    function collectionRoyalties(address)
        external
        view
        returns (
            uint16,
            address,
            address
        );

    function getPrice(address) external view returns (int256);

    function getCollectionRoyaltyFeeRecipient(address)
        external
        view
        returns (address);

    function getCollectionRoyaltyRoyalty(address)
        external
        view
        returns (uint16);
}

interface ITokenRegistry {
    function enabled(address) external returns (bool);
}

/**
 * @notice Secondary sale auction contract for NFTs
 */
contract AuctionV2 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address payable;
    using SafeERC20 for IERC20;

    /// @notice Event emitted only on construction. To be used by indexers
    event AuctionContractDeployed();

    event PauseToggled(bool isPaused);

    event AuctionCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken
    );

    event UpdateAuctionEndTime(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 endTime
    );

    event UpdateAuctionReservePrice(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address payToken,
        uint256 reservePrice
    );

    event UpdatePlatformFee(uint256 platformFee);

    event UpdatePlatformFeeRecipient(address payable platformFeeRecipient);

    event UpdateMinBidIncrement(uint256 minBidIncrement);

    event UpdateBidWithdrawalLockTime(uint256 bidWithdrawalLockTime);

    event BidPlaced(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event BidWithdrawn(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event BidRefunded(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bid
    );

    event AuctionResulted(
        address oldOwner,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed winner,
        address payToken,
        int256 unitPrice,
        uint256 winningBid
    );

    event AuctionCancelled(address indexed nftAddress, uint256 indexed tokenId);

    /// @notice Parameters of an auction
    struct Auction {
        address owner;
        address payToken;
        uint256 reservePrice;
        uint256 endTime;
        bool resulted;
    }

    /// @notice Information about the sender that placed a bit on an auction
    struct HighestBid {
        address payable bidder;
        uint256 bid;
        uint256 lastBidTime;
    }

    uint256 public bidTimeExtension; // 15 minutes

    /// @notice ERC721 Address -> Token ID -> Auction Parameters
    mapping(address => mapping(uint256 => Auction)) public auctions;

    /// @notice ERC721 Address -> Token ID -> highest bidder info (if a bid has been received)
    mapping(address => mapping(uint256 => HighestBid)) public highestBids;

    /// @notice globally and across all auctions, the amount by which a bid has to increase
    uint256 public minBidIncrement = 0;

    /// @notice global bid withdrawal lock time
    uint256 public bidWithdrawalLockTime = 20 minutes;

    /// @notice global platform fee, assumed to always be to 10 decimal place i.e. 250 = 2.5%
    uint256 public platformFee;

    /// @notice where to send platform fee funds to
    address payable public platformFeeRecipient;

    /// @notice initial duration of auction
    uint256 public auctionInitialDuration = 1 days;

    /// @notice Address registry
    IAddressRegistry public addressRegistry;

    /// @notice for switching off auction creations, bids and withdrawals
    bool public isPaused;

    /// @dev Only allow actions when the contract is not paused
    modifier whenNotPaused() {
        require(!isPaused, "contract paused");
        _;
    }

    /// @dev Only Marketplace allowed to call the function
    modifier onlyMarketplace() {
        require(
            addressRegistry.marketplace() == _msgSender(),
            "not marketplace contract"
        );
        _;
    }

    /// @notice Contract initializer
    /// @param _platformFeeRecipient Recipient of the platform fees
    /// @param _platformFee Fee of the platform
    function initialize(
        address payable _platformFeeRecipient,
        uint16 _platformFee
    ) public initializer {
        require(
            _platformFeeRecipient != address(0),
            "Auction: Invalid Platform Fee Recipient"
        );

        platformFee = _platformFee;
        platformFeeRecipient = _platformFeeRecipient;
        emit AuctionContractDeployed();

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     @notice Creates a new auction for a given item
     @dev Only the owner of item can create an auction and must have approved the contract
     @dev In addition to owning the item, the sender also has to have the MINTER role.
     @dev End time for the auction must be in the future.
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     @param _payToken Paying token
     @param _reservePrice Item cannot be sold for less than this or minBidIncrement, whichever is higher
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _reservePrice
    ) external whenNotPaused {
        // Ensure this contract is approved to move the token
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender() &&
                IERC721(_nftAddress).isApprovedForAll(
                    _msgSender(),
                    address(this)
                ),
            "not owner and or contract not approved"
        );

        require(
            _payToken == address(0) ||
                (addressRegistry.tokenRegistry() != address(0) &&
                    ITokenRegistry(addressRegistry.tokenRegistry()).enabled(
                        _payToken
                    )),
            "invalid pay token"
        );

        _createAuction(_nftAddress, _tokenId, _payToken, _reservePrice);
    }

    /**
     @notice Places a new bid, out bidding the existing bidder if found and criteria is reached
     @dev Only callable when the auction is open
     @dev Bids from smart contracts are prohibited to prevent griefing with always reverting receiver
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     @param _bidAmount Bid amount
     @param _affiliateOwner For establishing referral connections
     */
    function placeBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _bidAmount,
        address _affiliateOwner
    ) external payable nonReentrant whenNotPaused {
        // Check the auction to see if this is a valid bid
        Auction memory auction = auctions[_nftAddress][_tokenId];
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        require(auction.owner != address(0), "auction not found");
        // Ensure auction is in flight
        require(
            highestBid.bidder == address(0) || _getNow() <= auction.endTime,
            "bidding outside of the auction window"
        );

        if (auction.payToken == address(0)) {
            require(_bidAmount == 0, "Wrong payment token");
        }

        IAffiliate(addressRegistry.affiliate()).signUpWithPromo(
            msg.sender,
            _affiliateOwner
        );
        if (_bidAmount == 0) {
            _placeBid(_nftAddress, _tokenId, msg.value);
        } else {
            _placeBid(_nftAddress, _tokenId, _bidAmount);
        }
    }

    function _placeBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _bidAmount
    ) internal whenNotPaused {
        Auction storage auction = auctions[_nftAddress][_tokenId];

        require(
            _bidAmount >= auction.reservePrice,
            "bid cannot be lower than reserve price"
        );

        // Ensure bid adheres to outbid increment and threshold
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        uint256 minBidRequired = highestBid.bid + minBidIncrement;

        require(_bidAmount > minBidRequired, "failed to outbid highest bidder");

        if (auction.payToken != address(0)) {
            IERC20 payToken = IERC20(auction.payToken);
            require(
                payToken.transferFrom(_msgSender(), address(this), _bidAmount),
                "insufficient balance or not approved"
            );
        }

        if (highestBid.bidder == address(0)) {
            auction.endTime = _getNow() + auctionInitialDuration;
            emit UpdateAuctionEndTime(_nftAddress, _tokenId, auction.endTime);
        } else if (
            highestBid.bidder != address(0) &&
            auction.endTime < _getNow() + bidTimeExtension
        ) {
            auction.endTime = _getNow() + bidTimeExtension;
            emit UpdateAuctionEndTime(_nftAddress, _tokenId, auction.endTime);
        }

        // Refund existing top bidder if found
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(
                _nftAddress,
                _tokenId,
                highestBid.bidder,
                highestBid.bid
            );
        }

        // assign top bidder and bid time
        highestBid.bidder = payable(_msgSender());
        highestBid.bid = _bidAmount;
        highestBid.lastBidTime = _getNow();

        emit BidPlaced(_nftAddress, _tokenId, _msgSender(), _bidAmount);
    }

    /**
     @notice Allows the hightest bidder to withdraw the bid (after 12 hours post auction's end) 
     @dev Only callable by the existing top bidder
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     */
    function withdrawBid(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
        whenNotPaused
    {
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];

        // Ensure highest bidder is the caller
        require(
            highestBid.bidder == _msgSender(),
            "you are not the highest bidder"
        );

        uint256 _endTime = auctions[_nftAddress][_tokenId].endTime;

        require(
            _getNow() > _endTime && (_getNow() - _endTime >= 43200),
            "can withdraw only after 12 hours (after auction ended)"
        );

        uint256 previousBid = highestBid.bid;

        // Clean up the existing top bid
        delete highestBids[_nftAddress][_tokenId];

        // Refund the top bidder
        _refundHighestBidder(
            _nftAddress,
            _tokenId,
            payable(_msgSender()),
            previousBid
        );

        emit BidWithdrawn(_nftAddress, _tokenId, _msgSender(), previousBid);
    }

    /**
     @notice Closes a finished auction and rewards the highest bidder
     @dev Only admin or smart contract
     @dev Auction can only be resulted if there has been a bidder and reserve met.
     @dev If there have been no bids, the auction needs to be cancelled instead using `cancelAuction()`
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the item being auctioned
     */
    function resultAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        // Check the auction to see if it can be resulted
        Auction storage auction = auctions[_nftAddress][_tokenId];

        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender() &&
                _msgSender() == auction.owner,
            "sender must be item owner"
        );

        // Check the auction real
        require(auction.endTime > 0, "there were no bids");

        // Check the auction has ended
        require(_getNow() > auction.endTime, "auction not ended");

        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");

        // Get info on who the highest bidder is
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        address winner = highestBid.bidder;

        // Ensure there is a winner
        require(winner != address(0), "no open bids");
        require(
            highestBid.bid >= auction.reservePrice,
            "highest bid is below reservePrice"
        );

        // Ensure this contract is approved to move the token
        require(
            IERC721(_nftAddress).isApprovedForAll(_msgSender(), address(this)),
            "auction not approved"
        );

        uint256 platformFeeToPay = (highestBid.bid * platformFee) / 10000;

        // Result the auction
        auction.resulted = true;

        IAffiliate(addressRegistry.affiliate()).setHasTransacted(winner);
        IAffiliate(addressRegistry.affiliate()).setHasTransacted(_msgSender());

        IMarketplace marketplace = IMarketplace(addressRegistry.marketplace());

        address collectionRoyaltyFeeRecipient = marketplace
            .getCollectionRoyaltyFeeRecipient(_nftAddress);
        uint16 collectionRoyaltyFee = marketplace.getCollectionRoyaltyRoyalty(
            _nftAddress
        );

        // If there is no collection royalty fee, then split the platform fee with the referrer
        if (
            (collectionRoyaltyFee == 0 ||
                collectionRoyaltyFeeRecipient == address(0))
        ) {
            if (auction.payToken == address(0)) {
                (bool transferToAffiliateContract, ) = payable(
                    addressRegistry.affiliate()
                ).call{value: platformFeeToPay}("");
                require(transferToAffiliateContract, "transfer failed");
                IAffiliate(addressRegistry.affiliate())
                    .splitFeeWithAffiliateETH(
                        platformFeeToPay,
                        winner,
                        platformFeeRecipient,
                        platformFeeToPay
                    );
            } else {
                IERC20 payToken = IERC20(auction.payToken);
                payToken.approve(addressRegistry.affiliate(), platformFeeToPay);
                IAffiliate(addressRegistry.affiliate()).splitFeeWithAffiliate(
                    payToken,
                    platformFeeToPay,
                    winner,
                    address(this),
                    platformFeeRecipient,
                    platformFeeToPay
                );
            }
        } else {
            // If there is a collection royalty fee set then don't split the platform fee
            if (auction.payToken == address(0)) {
                (bool transferSuccess, ) = payable(platformFeeRecipient).call{
                    value: platformFeeToPay
                }("");
                require(transferSuccess, "transfer failed");
            } else {
                IERC20 payToken = IERC20(auction.payToken);
                require(
                    payToken.transfer(platformFeeRecipient, platformFeeToPay),
                    "failed to send platform fee"
                );
            }
        }

        // Either way deduct the platform fee from the payout amount
        uint256 payAmount = highestBid.bid - platformFeeToPay;

        // If there is a collection royalty fee then split that amount beteen ther affiliate and the royalty recipient
        if (
            collectionRoyaltyFeeRecipient != address(0) &&
            collectionRoyaltyFee != 0
        ) {
            if (auction.payToken == address(0)) {
                (bool transferToAffiliateContract, ) = payable(
                    addressRegistry.affiliate()
                ).call{value: (payAmount * collectionRoyaltyFee) / 10000}("");
                require(transferToAffiliateContract, "transfer failed");
                IAffiliate(addressRegistry.affiliate())
                    .splitFeeWithAffiliateETH(
                        (payAmount * collectionRoyaltyFee) / 10000,
                        winner,
                        collectionRoyaltyFeeRecipient,
                        platformFeeToPay
                    );
            } else {
                IERC20 payToken = IERC20(auction.payToken);
                // The amout to split should not be higher than the platform fee
                payToken.approve(
                    addressRegistry.affiliate(),
                    (payAmount * collectionRoyaltyFee) / 10000
                );

                IAffiliate(addressRegistry.affiliate()).splitFeeWithAffiliate(
                    payToken,
                    (payAmount * collectionRoyaltyFee) / 10000,
                    winner,
                    address(this),
                    collectionRoyaltyFeeRecipient,
                    platformFeeToPay
                );
            }
            payAmount =
                payAmount -
                ((payAmount * collectionRoyaltyFee) / 10000);
        }
        if (payAmount > 0) {
            if (auction.payToken == address(0)) {
                (bool success, ) = payable(auction.owner).call{
                    value: payAmount
                }("");
                require(success, "failed to send pay amount");
            } else {
                IERC20 payToken = IERC20(auction.payToken);
                require(
                    payToken.transfer(auction.owner, payAmount),
                    "failed to send the owner the auction balance"
                );
            }
        }

        // Transfer the token to the winner
        IERC721(_nftAddress).safeTransferFrom(
            IERC721(_nftAddress).ownerOf(_tokenId),
            winner,
            _tokenId
        );

        emit AuctionResulted(
            _msgSender(),
            _nftAddress,
            _tokenId,
            winner,
            auction.payToken,
            IMarketplace(addressRegistry.marketplace()).getPrice(
                auction.payToken
            ),
            highestBid.bid
        );
        // Clean up the highest bid
        delete highestBids[_nftAddress][_tokenId];

        // Remove auction
        delete auctions[_nftAddress][_tokenId];
    }

    /**
     @notice Cancels and inflight and un-resulted auctions, returning the funds to the top bidder if found
     @dev Only item owner
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     */
    function cancelAuction(address _nftAddress, uint256 _tokenId)
        external
        nonReentrant
    {
        // Check valid and not resulted
        Auction memory auction = auctions[_nftAddress][_tokenId];

        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == _msgSender() &&
                _msgSender() == auction.owner,
            "sender must be owner"
        );
        // Check auction not already resulted
        require(!auction.resulted, "auction already resulted");

        _cancelAuction(_nftAddress, _tokenId);
    }

    //////////
    // Admin //
    //////////

    /**
     @notice Toggling the pause flag
     @dev Only admin
     */
    function toggleIsPaused() external onlyOwner {
        isPaused = !isPaused;
        emit PauseToggled(isPaused);
    }

    /**
     @notice Update the amount by which bids have to increase, across all auctions
     @dev Only admin
     @param _minBidIncrement New bid step in WEI
     */
    function updateMinBidIncrement(uint256 _minBidIncrement)
        external
        onlyOwner
    {
        minBidIncrement = _minBidIncrement;
        emit UpdateMinBidIncrement(_minBidIncrement);
    }

    /**
     @notice Update the global bid withdrawal lockout time
     @dev Only admin
     @param _bidWithdrawalLockTime New bid withdrawal lock time
     */
    function updateBidWithdrawalLockTime(uint256 _bidWithdrawalLockTime)
        external
        onlyOwner
    {
        bidWithdrawalLockTime = _bidWithdrawalLockTime;
        emit UpdateBidWithdrawalLockTime(_bidWithdrawalLockTime);
    }

    /**
     @notice Update the current reserve price for an auction
     @dev Only admin
     @dev Auction must exist
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     @param _reservePrice New Ether reserve price (WEI value)
     */
    function updateAuctionReservePrice(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _reservePrice
    ) external {
        Auction storage auction = auctions[_nftAddress][_tokenId];

        require(_msgSender() == auction.owner, "sender must be item owner");

        // Ensure auction not already resulted
        require(!auction.resulted, "auction already resulted");

        require(
            auction.endTime == 0,
            "Reserve price can be updated before any bids"
        );

        auction.reservePrice = _reservePrice;
        emit UpdateAuctionReservePrice(
            _nftAddress,
            _tokenId,
            auction.payToken,
            _reservePrice
        );
    }

    /**
     @notice Method for updating platform fee
     @dev Only admin
     @param _platformFee uint256 the platform fee to set
     */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
        emit UpdatePlatformFee(_platformFee);
    }

    /**
     @notice Method for updating initial auction duration
     @dev Only admin
     @param _auctionInitialDuration initial auction duration to set in seconds
     */
    function updateAuctionInitialDuration(uint256 _auctionInitialDuration)
        external
        onlyOwner
    {
        auctionInitialDuration = _auctionInitialDuration;
    }

    /**
     @notice Method for updating platform fee address
     @dev Only admin
     @param _platformFeeRecipient payable address the address to sends the funds to
     */
    function updatePlatformFeeRecipient(address payable _platformFeeRecipient)
        external
        onlyOwner
    {
        require(_platformFeeRecipient != address(0), "zero address");

        platformFeeRecipient = _platformFeeRecipient;
        emit UpdatePlatformFeeRecipient(_platformFeeRecipient);
    }

    /**
     @notice Update AddressRegistry contract
     @dev Only admin
     */
    function updateAddressRegistry(address _registry) external onlyOwner {
        addressRegistry = IAddressRegistry(_registry);
    }

    /** @notice Update bid time extension
    @dev Only admin
     */

    function updateBidTimeExtension(uint256 _bidTimeExtension)
        external
        onlyOwner
    {
        bidTimeExtension = _bidTimeExtension;
    }

    ///////////////
    // Accessors //
    ///////////////

    /**
     @notice Method for getting all info about the auction
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     */
    function getAuction(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (
            address _owner,
            address _payToken,
            uint256 _reservePrice,
            uint256 _endTime,
            bool _resulted
        )
    {
        Auction storage auction = auctions[_nftAddress][_tokenId];
        return (
            auction.owner,
            auction.payToken,
            auction.reservePrice,
            auction.endTime,
            auction.resulted
        );
    }

    /**
     @notice Method for getting all info about the highest bidder
     @param _tokenId Token ID of the NFT being auctioned
     */
    function getHighestBidder(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (
            address payable _bidder,
            uint256 _bid,
            uint256 _lastBidTime
        )
    {
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        return (highestBid.bidder, highestBid.bid, highestBid.lastBidTime);
    }

    /////////////////////////
    // Internal and Private /
    /////////////////////////

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     @notice Private method doing the heavy lifting of creating an auction
     @param _nftAddress ERC 721 Address
     @param _tokenId Token ID of the NFT being auctioned
     @param _payToken Paying token
     @param _reservePrice Item cannot be sold for less than this or minBidIncrement, whichever is higher
     */
    function _createAuction(
        address _nftAddress,
        uint256 _tokenId,
        address _payToken,
        uint256 _reservePrice
    ) private {
        // Ensure a token cannot be re-listed if previously successfully sold
        require(
            auctions[_nftAddress][_tokenId].owner != _msgSender(),
            "auction already created"
        );

        // Setup the auction
        auctions[_nftAddress][_tokenId] = Auction({
            owner: _msgSender(),
            payToken: _payToken,
            reservePrice: _reservePrice,
            endTime: 0,
            resulted: false
        });

        emit AuctionCreated(_nftAddress, _tokenId, _payToken);
    }

    function _cancelAuction(address _nftAddress, uint256 _tokenId) private {
        // refund existing top bidder if found
        HighestBid storage highestBid = highestBids[_nftAddress][_tokenId];
        if (highestBid.bidder != address(0)) {
            _refundHighestBidder(
                _nftAddress,
                _tokenId,
                highestBid.bidder,
                highestBid.bid
            );

            // Clear up highest bid
            delete highestBids[_nftAddress][_tokenId];
        }

        // Remove auction and top bidder
        delete auctions[_nftAddress][_tokenId];

        emit AuctionCancelled(_nftAddress, _tokenId);
    }

    /**
     @notice Used for sending back escrowed funds from a previous bid
     @param _currentHighestBidder Address of the last highest bidder
     @param _currentHighestBid Ether or Mona amount in WEI that the bidder sent when placing their bid
     */
    function _refundHighestBidder(
        address _nftAddress,
        uint256 _tokenId,
        address payable _currentHighestBidder,
        uint256 _currentHighestBid
    ) private {
        Auction memory auction = auctions[_nftAddress][_tokenId];
        if (auction.payToken == address(0)) {
            // refund previous best (if bid exists)
            (bool successRefund, ) = _currentHighestBidder.call{
                value: _currentHighestBid
            }("");
            require(successRefund, "failed to refund previous bidder");
        } else {
            IERC20 payToken = IERC20(auction.payToken);
            require(
                payToken.transfer(_currentHighestBidder, _currentHighestBid),
                "failed to refund previous bidder"
            );
        }
        emit BidRefunded(
            _nftAddress,
            _tokenId,
            _currentHighestBidder,
            _currentHighestBid
        );
    }

    /**
     * @notice Reclaims ERC20 Compatible tokens for entire balance
     * @dev Only access controls admin
     * @param _tokenContract The address of the token contract
     */
    function reclaimERC20(address _tokenContract) external onlyOwner {
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(_msgSender(), balance), "Transfer failed");
    }
}