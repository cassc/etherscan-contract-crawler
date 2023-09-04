// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
    @title Auction Contract Version 1

    @notice This contract allows for the creation and bidding on auction listings
    in a decentralized manner.

    @dev Users can submit auction listings on our platform and then fund them via this smart
    contract by paying the stake and setting the paramaters needed.

    The listingID is unique and generated off-chain on the platform side. It is used to identify the listing
    and what is being sold.

    Once an auction listing is created on chain (by funding it), users can bid on it.

    The auction listing can be closed by approvers (designated by the contract owner).

    When the auction has expired, or been closed due to a buyout bid being placed, the seller (or approvers on
    behaf of the owner) can claim the funds from the auction. If this is done during the cooldown period, after the auction
    has ended, a fee is applied.

    The winning bid is the highest bid when the auction expires or the first bid to reach the buyout price.

    There is also the option for the seller to not put up the listing as an action but rather just allow a single buyout price.

*/

contract AuctionV1 is Ownable {
    address private immutable _arkm;

    uint256 private _listingStake;
    uint256 private _makerFee;
    uint256 private _takerFee;
    uint256 private _withdrawEarlyFee;
    uint256 private _minimumStep;
    bool    private _acceptingListings;
    uint256 private _accruedFees;
    address private _feeReceiverAddress;
    uint    private _listingDuration;
    uint    private _cooldown;
    uint256 private _minimumBuyoutPrice;

    // Basis points are 1/100th of a percent. 10000 = 100%.
    uint64  private constant _MAX_BPS = 10000;

    /// @dev mapping of listingID => Listing
    mapping(uint256 => Listing) private _listings;

    /// @dev mapping of listingID => Bid
    mapping(uint256 => Bid) private _bids;

    /// @dev Approver address => is approver
    mapping(address => bool) private _approvers;

    /// @notice Struct representing a listing
    /// @dev the struct represent a sales listing. Depending on the isAuction flag,
    /// the listing will be an auction or a buyout listing. Auctions may have a buyout price
    /// determined if the buyoutPrice is > 0.
    /// Closed listings cannot be bid on. A listing is closed when the auction is over (timed out or buyout),
    /// use the appropriate getter to find the status rather than relying on the closed flag to take auction
    /// end-time into account.
    /// A stake is payed to create a listing, if the listing is not rejected by an approver the stake is refunded,
    /// when the listing is claimed.
    struct Listing {
        address poster;
        uint256 stake;
        uint64  expiration;
        bool    isAuction;
        uint256 buyoutPrice;
        uint256 startingPrice;
        bool    closed;
        bool    withdrawn;
    }

    /// @notice Struct representing a bid (or buyout) on a listing
    /// @dev the amount is the total amount of ARKM sent (before taker, maker and withdraw fees).
    /// The bid itself is the amount minus the taker fee.
    /// The bidID represents the bid and is is generated off-chain.
    struct Bid {
        address bidder;
        uint256 bidPlusTakerFee;
        uint256 bidID;
    }

    /// @notice Contract constructor
    /// @param arkmAddress The address of the ARKM token
    /// @param initialSubmissionStake The stake required to create a listing
    /// @param initialMakerFee The maker fee (fee paid by the seller when the auction is claimed), in basis points
    /// @param initialTakerFee The initial taker fee (fee paid by the buyer when the auction is claimed), in basis points
    /// @param initialWithdrawEarlyFee The initial fee paid by the seller if the auction is claimed before cool down period has ended, in basis points
    /// @param initialMinimumStep The initial minimum step (minimum amount a bid must be higher than the previous bid in basis point)
    /// @param initialMinimumBuyoutPrice The initial minimum buyout price (minimum amount a buyout price may be set to in a listing)
    /// @param listingDuration The initial listing duration (how long an auction will run for)
    /// @param initialFeeReceiverAddress The initial fee receiver address (where the fees are sent to)
    /// @param initialCooldown The initial cooldown period (how long after an auction has ended before the seller can claim the funds)
    constructor(address arkmAddress, uint256 initialSubmissionStake, uint256 initialMakerFee, uint256 initialTakerFee, uint256 initialWithdrawEarlyFee, uint256 initialMinimumStep, uint256 initialMinimumBuyoutPrice, uint listingDuration, address initialFeeReceiverAddress, uint initialCooldown) {
        require(initialMakerFee <= _MAX_BPS, "AuctionV1: maker fee must be <= 10000");
        require(initialTakerFee <= _MAX_BPS, "AuctionV1: taker fee must be <= 10000");
        require(initialFeeReceiverAddress != address(0), "AuctionV1: fee receiver address cannot be 0x0");
        // 86400 seconds in a day.
        require(listingDuration <= 36500*86400, "AuctionV1: listing duration must be <= 36500 days in seconds");

        try ERC20Burnable(arkmAddress).totalSupply() returns (uint256) {
            _arkm = arkmAddress;
        } catch {
            revert("AuctionV1: provided token address does not implement ERC20Burnable");
        }

        _listingStake = initialSubmissionStake;
        _makerFee = initialMakerFee;
        _takerFee = initialTakerFee;
        _minimumStep = initialMinimumStep;
        _withdrawEarlyFee = initialWithdrawEarlyFee;
        _acceptingListings = true;
        _accruedFees = 0;
        _feeReceiverAddress = initialFeeReceiverAddress;
        _listingDuration = listingDuration;
        _minimumBuyoutPrice = initialMinimumBuyoutPrice;
        _cooldown = initialCooldown;
    }

    /// @notice Funds a listing
    /// @param listing The listingID to fund (generated off-chain on the platform)
    /// @param buyout The buyout price (if a buyer pays this or higher the auction immediatly ends and the bidder wins)
    /// @param startingPrice The starting price for the auction
    /// @param durationInSeconds The duration of the auction in seconds (if 0 will default to the contract default 30 days unless changed by the owner)
    /// @param isAuction Whether the listing is an auction or a buyout-only listing
    /// @dev Will emit an event ListingFunded if successful
    function stakeListing(uint256 listing, uint256 buyout, uint256 startingPrice, uint256 durationInSeconds, bool isAuction) external {
        require(_acceptingListings, "AuctionV1: not accepting listings");
        require(_listings[listing].poster == address(0), "AuctionV1: listing already exists");
        require(buyout > 0 || isAuction, "AuctionV1: must have a buyout price or be an auction");
        require(buyout == 0 || buyout >= _minimumBuyoutPrice, "AuctionV1: must have a buyout price larger than the minimum buyout price");
        require(startingPrice <= buyout || buyout == 0, "AuctionV1: starting price must be lower than or equal to the buyout price");

        // transfer the listing stake to this contract
        SafeERC20.safeTransferFrom(IERC20(_arkm), _msgSender(), address(this), _listingStake);

        _listings[listing] = Listing({
            poster: _msgSender(),
            stake: _listingStake,
            expiration: uint64(block.timestamp + (durationInSeconds > 0 ? durationInSeconds * 1 seconds : _listingDuration * 1 seconds)),
            isAuction: isAuction,
            buyoutPrice: buyout,
            startingPrice: startingPrice,
            closed: false,
            withdrawn: false
        });

        emit ListingFunded(
            listing,
            _msgSender(),
            isAuction,
            startingPrice,
            buyout
        );
    }
    /// @notice Makes a bid on a listing.
    /// @param listing the listingID to bid on
    /// @param amount the total amount payed to make the bid (before fees)
    /// @param bidID an ID generated off-chain to identify the bid
    /// @dev Will emit an event BidPlaced if successful
    function placeBid(uint256 listing, uint256 amount, uint256 bidID) external {
        require(_listings[listing].poster != address(0), "AuctionV1: listing does not exist");
        require(_listings[listing].closed == false, "AuctionV1: listing is closed");
        require(_listings[listing].expiration > block.timestamp, "AuctionV1: listing has expired");
        require(_listings[listing].startingPrice <= amount, "AuctionV1: bid must be at least starting price");

        uint256 _amountPlusTakerFee = addTakerFee(amount);

        if (!_listings[listing].isAuction) {
            require (amount >= _listings[listing].buyoutPrice, "AuctionV1: not accepting non-buyout bids");
        } else {
            // If listing is an auction check that the bid is higher than or equal to the minimum
            // step increase or the buyout price. Be aware that a buyout price of 0 means there is
            // no buyout price.
            require(amount >= afterTakerFee(_bids[listing].bidPlusTakerFee) + minimumStep(listing) || (_listings[listing].buyoutPrice > 0 && amount >= _listings[listing].buyoutPrice), "AuctionV1: bid must be higher by the minimum step increase");
        }

        // pay the current bid back to bidder
        if (_bids[listing].bidder != address(0)) {
            SafeERC20.safeTransfer(IERC20(_arkm), _bids[listing].bidder, _bids[listing].bidPlusTakerFee);
        }

        // If a bid arrives within the last 30 minutes before the listing expires, extend the listing by 30 minutes.
        if (_listings[listing].expiration <= block.timestamp + 30 minutes) {
            _listings[listing].expiration = uint64(block.timestamp + 30 minutes);
        }

        // get the new bid
        SafeERC20.safeTransferFrom(IERC20(_arkm), _msgSender(), address(this), _amountPlusTakerFee);

        // if it's above the buyout, end the auction
        bool buyout = false;
        if (_listings[listing].buyoutPrice != 0 && amount >= _listings[listing].buyoutPrice) {
            _listings[listing].closed = true;
            buyout = true;
            _listings[listing].expiration = uint64(block.timestamp);
        }

        // Store the bid.
        _bids[listing] = Bid({
            bidder: _msgSender(),
            bidPlusTakerFee: _amountPlusTakerFee,
            bidID: bidID
        });

        emit BidMade(
            listing,
            _msgSender(),
            bidID,
            amount,
            buyout
        );
    }

    /// @notice Claim the tokens for the seller from a listing
    /// @param listing the listingID to claim
    /// @param withdrawEarly if set to true it will allow the seller to withdraw early (before the cooldown period has expired but after the listing has closed)
    /// this comes with a fee.
    /// @dev Will emit an event ListingClaimed if successful
    function claim(uint256 listing, bool withdrawEarly) external {
        require(!_listings[listing].withdrawn, "AuctionV1: has already been withdrawn");
        require(_listings[listing].poster != address(0), "AuctionV1: listing does not exist");
        require(isClosed(listing), "AuctionV1: listing is not closed");
        if (withdrawEarly && cooldownExpires(listing) > block.timestamp && _msgSender() == _listings[listing].poster) {
            // Pay the seller amount and their stake - maker, taker and withdraw early fee.
            uint256 fees = withdrawEarlyFee(_bids[listing].bidPlusTakerFee) + makerFee(_bids[listing].bidPlusTakerFee) + takerFee(_bids[listing].bidPlusTakerFee);
            _accruedFees += fees;
            SafeERC20.safeTransfer(IERC20(_arkm), _listings[listing].poster, _bids[listing].bidPlusTakerFee - fees + _listings[listing].stake);
        } else {
            require(cooldownExpires(listing) <= block.timestamp || isApprover(_msgSender()), "AuctionV1: can not withdraw before cooldown period expires");
            // Pay the seller amount and their stake - maker, taker and withdraw early fee.
            uint256 fees = makerFee(_bids[listing].bidPlusTakerFee) + takerFee(_bids[listing].bidPlusTakerFee);
            _accruedFees += fees;
            SafeERC20.safeTransfer(IERC20(_arkm), _listings[listing].poster, _bids[listing].bidPlusTakerFee - fees + _listings[listing].stake);
        }
        _listings[listing].withdrawn = true;
        emit ListingClaimed(listing);
    }

    /// @notice Rejects a listing, forfeiting the stake.
    /// @param listing the listingID to reject
    /// @dev Will emit an event ListingClosed if successful.
    /// Will return the bid to the bidder if the listing already has bids
    function rejectListing(uint256 listing) external {
        require(isApprover(_msgSender()), "AuctionV1: closing requires approver");
        require(_listings[listing].closed == false, "AuctionV1: listing is closed");

        // if there's a current bid return it to the bidder.
        if (_bids[listing].bidder != address(0)) {
            SafeERC20.safeTransfer(IERC20(_arkm), _bids[listing].bidder, _bids[listing].bidPlusTakerFee);
            delete _bids[listing];
        }

        // Forfeit the stake.
        _accruedFees += _listings[listing].stake;
        _listings[listing].closed = true;
        _listings[listing].withdrawn = true;

        emit ListingClosed(listing);
    }

    /// @notice Grants an address approver status
    /// @param approver the address to grant approver status to
    /// @dev Will emit an event GrantApprover if successful
    function grantApprover(address approver) external onlyOwner {
        _approvers[approver] = true;
        emit GrantApprover(approver);
    }
    /// @notice Revokes an address approver status
    /// @param approver the address to revoke approver status from
    /// @dev Will emit an event RevokeApprover if successful
    function revokeApprover(address approver) external onlyOwner {
        _approvers[approver] = false;
        emit RevokeApprover(approver);
    }

    /// @notice makes the contract stop accepting new listings
    /// @dev Will emit an event StopAcceptingListings if successful
    function stopAcceptingListings() external onlyOwner {
        _acceptingListings = false;
        emit StopAcceptingListings();
    }

    // Helpers.

    //// @notice returns the winning bidder's address for a given listing
    /// @param listing the listingID to get the winning bidder for
    /// @dev will revert if the auction has not yet been won
    function winningBidder(uint256 listing) external view returns (address) {
        require(_listings[listing].poster != address(0), "AuctionV1: listing does not exist");
        require(isClosed(listing), "AuctionV1: listing is not closed");
        require(_bids[listing].bidder != address(0), "AuctionV1: listing has not been bid on");
        return _bids[listing].bidder;
    }

    /// @notice returns the winning BidID for a given listing
    /// @param listing the listingID to get the winning bidID for
    /// @dev will revert if the auction has not yet been won
    function winningBidID(uint256 listing) external view returns (uint256) {
        require(_listings[listing].poster != address(0), "AuctionV1: listing does not exist");
        require(isClosed(listing), "AuctionV1: listing is not closed");
        require(_bids[listing].bidID > 0, "AuctionV1: listing has not been bid on");
        return _bids[listing].bidID;
    }

    /// @notice returns the minimum increase in bid needed to make a bid for a given listing
    /// @dev The 10000 accounts for denomination in basis points.
    function minimumStep(uint256 listing) internal view returns (uint256)  {
        return afterTakerFee(_bids[listing].bidPlusTakerFee) * _minimumStep / 10000;
    }

    /// @notice returns the bid given the amount that was sent in the bid
    /// by removing the taker fee from the total sent amount.
    function afterTakerFee(uint256 amount) internal view returns (uint256) {
        return amount - takerFee(amount);
    }

    /// @notice adds the taker fee to an amount
    /// @param amount the amount to add the taker fee to
    function addTakerFee(uint256 amount) internal view returns (uint256) {
        return amount * (10000 + _takerFee) / 10000;
    }

    /// @notice returns the taker fee for a given amount
    /// @param amount the amount to calculate the taker fee for
    function takerFee(uint256 amount) internal view returns (uint256) {
        return amount * _takerFee / (10000 + _takerFee);
    }

    /// @notice the maker fee for a given amount
    /// @param amount the amount to calculate the maker fee for
    /// @dev The 10000 accounts for denomination in basis points.
    /// The maker fee given the total amount payed by the bidder.
    /// The payout to the seller is the `amount payed by bidder - maker fee - taker fee - <withdraw early fee>`
    function makerFee(uint256 amount) internal view returns (uint256) {
        return (amount - takerFee(amount)) * _makerFee / 10000;
    }

    /// @notice the withdraw early fee for a given amount
    /// @param amount the amount to calculate the withdraw early fee for
    /// @dev The 10000 accounts for denomination in basis points.
    /// The withdraw early fee given the total amount payed by the bidder.
    /// The payout to the seller if withdrawn early is
    /// `amount payed by bidder - maker fee - taker fee - withdraw early fee`
    function withdrawEarlyFee(uint256 amount) internal view returns (uint256) {
        return (amount - makerFee(amount) - takerFee(amount)) * _withdrawEarlyFee / 10000;
    }
    /// @notice what timestamp does cool down period for this listing expire
    /// @param listing the listingID to get the cooldown expiration for
    function cooldownExpires(uint256 listing) public view returns (uint256) {
        return _cooldown + _listings[listing].expiration;
    }

    // Getters.
    function minimumStepBasis() external view returns (uint256) {
        return _minimumStep;
    }

    function cooldown() external view returns (uint) {
        return _cooldown;
    }

    function minimumBuyoutPrice() external view returns (uint256) {
        return _minimumBuyoutPrice;
    }

    function feeReceiverAddress() external view returns (address) {
        return _feeReceiverAddress;
    }

    function getListingStake(uint256 listing) external view returns (uint256) {
        return _listings[listing].stake;
    }

    function isApprover(address approver) public view returns (bool) {
        return _approvers[approver];
    }

    function arkm() external view returns (address) {
        return _arkm;
    }

    function listingStake() external view returns (uint256) {
        return _listingStake;
    }

    function makerFee() external view returns (uint256) {
        return _makerFee;
    }

    function takerFee() external view returns (uint256) {
        return _takerFee;
    }

    function withdrawEarlyFee() external view returns (uint256) {
        return _withdrawEarlyFee;
    }

    function listingDurationDays() external view returns (uint) {
        return _listingDuration;
    }

    function acceptingListings() external view returns (bool) {
        return _acceptingListings;
    }

    function accruedFees() external view returns (uint256) {
        return _accruedFees;
    }
    /// @notice return whether the listing is closed or not
    /// @param listing the listingID to check if closed
    /// @dev will revert if the listing does not exist
    function isClosed(uint256 listing) public view returns (bool) {
        require(_listings[listing].poster != address(0), "AuctionV1: listing does not exist");
        return _listings[listing].closed || _listings[listing].expiration < block.timestamp;
    }

    function closesAt(uint256 listing) external view returns (uint256) {
        return _listings[listing].expiration;
    }

    function currentBidID(uint256 listing) external view returns (uint256) {
        return _bids[listing].bidID;
    }

    function currentBidAmount(uint256 listing) external view returns (uint256) {
        return afterTakerFee(_bids[listing].bidPlusTakerFee);
    }

    function withdrawn(uint256 listing) external view returns (bool) {
        return _listings[listing].withdrawn;
    }

    function buyoutPrice(uint256 listing) external view returns (uint256) {
        return _listings[listing].buyoutPrice;
    }

    function listingIsAuction(uint256 listing) external view returns (bool) {
        return _listings[listing].isAuction;
    }

    function listingStartingPrice(uint256 listing) external view returns (uint256) {
        return _listings[listing].startingPrice;
    }

    // Setters.

    /// @notice Sets a new maker fee
    /// @param newFee The new maker fee, in basis points
    function setMakerFee(uint256 newFee) external onlyOwner {
        require(newFee <= _MAX_BPS, "BountyV1: maker fee must be <= 100%");
        uint256 _oldFee = _makerFee;
        _makerFee = newFee;

        emit SetMakerFee(
            newFee,
            _oldFee
        );
    }

    /// @notice Sets a new cooldown time
    /// @param newCooldown The new cooldown time, in seconds
    function setCooldown(uint newCooldown) external onlyOwner {
        uint _oldCooldown = _cooldown;
        _cooldown = newCooldown;

        emit SetCooldown(
            newCooldown,
            _oldCooldown
        );
    }

    /// @notice Sets new default listing duration
    /// @param newDuration The new default listing duration, in seconds
    function setDefaultListingDuration(uint256 newDuration) external onlyOwner {
        uint256 _oldDuration = _listingDuration;
        _listingDuration = newDuration;

        emit SetDefaultListingDuration(
            newDuration,
            _oldDuration
        );
    }

    /// @notice Sets a new minimum price increase for subsequent bids
    /// @param newStep The new minimum price for subsequent bids, in basis points
    /// @dev Emits an event with the new minimum step SetMinimumStep
    function setMinimumStep(uint256 newStep) external onlyOwner {
        uint256 _oldStep = _minimumStep;
        _minimumStep = newStep;

        emit SetMinimumStep(
            newStep,
            _oldStep
        );
    }

    /// @notice Sets a new taker fee
    /// @param newFee The new taker fee, in basis points
    /// @dev Emits an event with the new taker fee SetTakerFee
    function setTakerFee(uint256 newFee) external onlyOwner {
        require(newFee <= _MAX_BPS, "BountyV1: taker fee must be <= 100%");
        uint256 _oldFee = _takerFee;
        _takerFee = newFee;

        emit SetTakerFee(
            newFee,
            _oldFee
        );
    }

    /// @notice Sets a new withdraw early fee
    /// @param newFee The new withdraw early fee, in basis points
    /// @dev Emits an event with the new taker fee SetWithdrawEarlyFee
    function setWithdrawEarlyFee(uint256 newFee) external onlyOwner {
        require(newFee <= _MAX_BPS, "BountyV1: withdraw early fee must be <= 100%");
        uint256 _oldFee = _withdrawEarlyFee;
        _withdrawEarlyFee = newFee;

        emit SetWithdrawEarlyFee(
            newFee,
            _oldFee
        );
    }

    /// @notice Sets a new minimum buyout price
    /// @param newMinimumBuyoutPrice The new minimum buyout price
    /// @dev will emit an event, SetMinimumBuyoutPrice, when changed
    function setMinimumBuyoutPrice(uint256 newMinimumBuyoutPrice) external onlyOwner {
        uint256 _oldMinimumBuyoutPrice = _minimumBuyoutPrice;
        _minimumBuyoutPrice = newMinimumBuyoutPrice;
        emit SetMinimumBuyoutPrice(
            newMinimumBuyoutPrice,
            _oldMinimumBuyoutPrice
        );
    }

    /// @notice Sets a new stake needed to stake a listing
    /// @param newStake The new listing stake, in value of the ERC20 token e.g. 10 e18
    /// @dev Emits an event with the new listing stake SetListingStake
    function setListingStake(uint256 newStake) external onlyOwner {
        uint256 _oldStake = _listingStake;
        _listingStake = newStake;

        emit SetListingStake(
            newStake,
            _oldStake
        );
    }

    /// @notice Sets a new fee receiver address
    /// @param receiver The new fee receiver address
    /// @dev This is the address that will receive fees when contract fees are withdrawn
    function setFeeReceiverAddress(address receiver) external onlyOwner {
        require(receiver != address(0), "BountyV1: fee receiver address cannot be 0x0");
        _feeReceiverAddress = receiver;
    }

    /// @notice Withdraw fees to the fee receiver address
    /// @dev Emits an event with the amount withdrawn WithdrawFees
    function withdrawFees() external onlyOwner {
        uint256 fees = _accruedFees;
        _accruedFees = 0;
        SafeERC20.safeTransfer(IERC20(_arkm), _feeReceiverAddress, fees);

        emit WithdrawFees(
            fees
        );
    }

    // Events.
    /// @notice Emitted when someone makes a valid bid on a listing
    event BidMade (
        uint256 indexed listing,
        address indexed bidder,
        uint256 bidID,
        uint256 amount,
        bool buyout
    );

    /// @notice Emitted when a listing is funded
    event ListingFunded (
        uint256 indexed id,
        address indexed seller,
        bool auction,
        uint256 startingPrice,
        uint256 buyoutPrice
    );

    /// @notice Emitted when a listing is claimed
    event ListingClaimed(
        uint256 indexed listing
    );

    /// @notice Emitted when a listing is rejected
    event ListingClosed (
        uint256 indexed listing
    );


    /// @notice Emitted when an account is granted approver status
    /// @param account The account granted approver status
    event GrantApprover (
        address indexed account
    );

    /// @notice Emitted when an account has its approver status revoked
    /// @param account The account that had its approver status revoked
    event RevokeApprover (
        address indexed account
    );

    /// @notice Emitted when the maker fee is set
    /// @param newFee The new maker fee
    /// @param oldFee The old maker fee
    event SetMakerFee (
        uint256 newFee,
        uint256 oldFee
    );

    /// @notice Emitted when the taker fee is set
    /// @param newFee The new taker fee
    /// @param oldFee The old taker fee
    event SetTakerFee (
        uint256 newFee,
        uint256 oldFee
    );

    /// @notice Emitted when the withdraw early fee is set
    /// @param newFee The new withdraw early fee
    /// @param oldFee The old withdraw early fee
    event SetWithdrawEarlyFee (
        uint256 newFee,
        uint256 oldFee
    );

    /// @notice Emitted when the listing stake is set
    /// @param newStake The new listing stake
    /// @param oldStake The old listing stake
    event SetListingStake (
        uint256 newStake,
        uint256 oldStake
    );

    /// @notice Emitted when accrued fees are withdrawn
    /// @param amount The amount of accrued fees withdrawn
    event WithdrawFees (
        uint256 amount
    );

    /// @notice Emitted when a new minimum buyout price is set
    event SetMinimumBuyoutPrice(
        uint256 newMinimumBuyoutPrice,
        uint256 oldMinimumBuyoutPrice
    );

    /// @notice Emitted when a new minimum bid step is set
    event SetMinimumStep(
        uint256 newMinimumStep,
        uint256 oldMinimumStep
    );

    /// @notice Emitted when a new default listing duration is set
    event SetDefaultListingDuration(
        uint256 newDuration,
        uint256 oldDuration
    );

      /// @notice Emitted when a new cooldown period is set
    event SetCooldown
    (
        uint256 newDuration,
        uint256 oldDuration
    );

    /// @notice Emitted when contract no longer accepts listings
    event StopAcceptingListings();


}