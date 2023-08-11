// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@openzeppelin/utils/structs/EnumerableSet.sol";
import "@solmate/auth/Owned.sol";
import "@solmate/utils/FixedPointMathLib.sol";
import "@solmate/utils/ReentrancyGuard.sol";
import "@solmate/utils/SafeTransferLib.sol";
import "@solmate/tokens/ERC20.sol";
import "@solmate/tokens/ERC721.sol";
import "../interfaces/ILoanLiquidator.sol";
import "../interfaces/loans/IMultiSourceLoan.sol";
import "./AddressManager.sol";

/// @title Auction Loan Liquidator
/// @author Florida St
/// @notice Receives an NFT to be auctioned when a loan defaults.
///         Mainly taking Zora's implementation.
contract AuctionLoanLiquidator is
    ERC721TokenReceiver,
    ILoanLiquidator,
    Owned,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    struct Auction {
        address loanAddress;
        uint256 loanId;
        uint256 highestBid;
        address highestBidder;
        uint96 duration;
        address asset;
        uint96 startTime;
        address originator;
        uint96 lastBidTime;
    }

    uint256 public constant MAX_TRIGGER_FEE = 500;
    uint256 public constant MIN_INCREMENT_BPS = 500;
    uint256 private constant _BPS = 10000;
    uint96 private constant _MIN_NO_ACTION_MARGIN = 10 minutes;
    AddressManager private immutable _currencyManager;
    AddressManager private immutable _collectionManager;
    uint256 private _triggerFee = 100;
    EnumerableSet.AddressSet private _validLoanContracts;

    mapping(address => mapping(uint256 => Auction)) private _auctions;

    event LoanContractAdded(address loan);

    event LoanContractRemoved(address loan);

    event LoanLiquidationStarted(
        address loanAddress,
        uint256 loanId,
        uint96 duration,
        address asset
    );

    event BidPlaced(
        address auctionContract,
        uint256 tokenId,
        address newBidder,
        uint256 bid,
        address loanAddress,
        uint256 loanId
    );

    event AuctionSettled(
        address loanContract,
        uint256 loanId,
        address auctionContract,
        uint256 tokenId,
        address asset,
        uint256 highestBid,
        address settler,
        uint256 triggerFee
    );

    event TriggerFeeUpdated(uint256 triggerFee);

    error NFTNotOwnedError(address _owner);

    error AuctionNotExistsError(address _contract, uint256 _tokenId);

    error MinBidError(uint256 _minBid);

    error AuctionOverError(uint96 _expiration);

    error AuctionNotOverError(uint96 _expiration);

    error AuctionAlreadyInProgressError();

    error NoBidsError();

    error CurrencyNotWhitelistedError();

    error CollectionNotWhitelistedError();

    error LoanNotAcceptedError(address _loan);

    error ZeroAddressError();

    error InvalidTriggerFee(uint256 triggerFee);

    constructor(
        address currencyManager,
        address collectionManager,
        uint256 triggerFee
    ) Owned(msg.sender) {
        if (currencyManager == address(0) || collectionManager == address(0)) {
            revert ZeroAddressError();
        }
        _currencyManager = AddressManager(currencyManager);
        _collectionManager = AddressManager(collectionManager);
        _updateTriggerFee(triggerFee);
    }

    /// @notice Add a loan contract to the list of accepted contracts.
    /// @param _loanContract The loan contract to be added.
    function addLoanContract(address _loanContract) external onlyOwner {
        _validLoanContracts.add(_loanContract);

        emit LoanContractAdded(_loanContract);
    }

    /// @notice Remove a loan contract from the list of accepted contracts.
    /// @param _loanContract The loan contract to be removed.
    function removeLoanContract(address _loanContract) external onlyOwner {
        _validLoanContracts.remove(_loanContract);

        emit LoanContractRemoved(_loanContract);
    }

    /// @return The loan contracts that are accepted by this liquidator.
    function getValidLoanContracts() external view returns (address[] memory) {
        return _validLoanContracts.values();
    }

    /// @notice Called by the owner to update the trigger fee.
    /// @param triggerFee The new trigger fee.
    function updateTriggerFee(uint256 triggerFee) external onlyOwner {
        _updateTriggerFee(triggerFee);
    }

    /// @return The trigger fee.
    function getTriggerFee() external view returns (uint256) {
        return _triggerFee;
    }

    /// @notice Return a given auction.
    /// @param _contract The NFT contract address.
    /// @param _tokenId The NFT token ID.
    /// @return The auction.
    function getAuction(
        address _contract,
        uint256 _tokenId
    ) external view returns (Auction memory) {
        return _auctions[_contract][_tokenId];
    }

    /// @notice Called by a loan contract. This contract must receive the NFT before calling it.
    /// @param _loanId The loan ID.
    /// @param _contract The NFT contract address.
    /// @param _tokenId The NFT token ID.
    /// @param _asset The asset to be used to pay the loan/auction the item.
    /// @param _duration The duration of the auction.
    /// @param _originator The address that trigger the liquidation.
    function liquidateLoan(
        uint256 _loanId,
        address _contract,
        uint256 _tokenId,
        address _asset,
        uint96 _duration,
        address _originator
    ) external override nonReentrant {
        address _owner = ERC721(_contract).ownerOf(_tokenId);
        if (_owner != address(this)) {
            revert NFTNotOwnedError(_owner);
        }

        if (!_validLoanContracts.contains(msg.sender)) {
            revert LoanNotAcceptedError(msg.sender);
        }

        if (!_currencyManager.isWhitelisted(_asset)) {
            revert CurrencyNotWhitelistedError();
        }

        if (!_collectionManager.isWhitelisted(_contract)) {
            revert CollectionNotWhitelistedError();
        }

        Auction storage auction = _auctions[_contract][_tokenId];

        if (auction.loanId != 0) {
            revert AuctionAlreadyInProgressError();
        }

        auction.loanId = _loanId;
        auction.loanAddress = msg.sender;
        auction.duration = _duration;
        auction.asset = _asset;
        auction.startTime = uint96(block.timestamp);
        auction.originator = _originator;

        emit LoanLiquidationStarted(
            auction.loanAddress,
            _loanId,
            auction.duration,
            _asset
        );
    }

    /// @notice When a bid is placed, the contract takes possesion of the bid, and
    ///         if there was a previous bid, it returns that capital to the original
    ///         bidder.
    function placeBid(
        address _contract,
        uint256 _tokenId,
        uint256 _bid
    ) external nonReentrant {
        Auction storage auction = _auctions[_contract][_tokenId];

        if (auction.loanId == 0) {
            revert AuctionNotExistsError(_contract, _tokenId);
        }

        uint256 currentHighestBid = auction.highestBid;
        if (
            currentHighestBid.mulDivDown(_BPS + MIN_INCREMENT_BPS, _BPS) >= _bid
        ) {
            revert MinBidError(_bid);
        }

        uint256 currentTime = block.timestamp;
        uint96 expiration = auction.startTime + auction.duration;
        uint96 withMargin = auction.lastBidTime + _MIN_NO_ACTION_MARGIN;
        uint96 max = withMargin > expiration ? withMargin : expiration;
        if (
            withMargin < currentTime &&
            currentTime > expiration &&
            currentHighestBid > 0
        ) {
            revert AuctionOverError(max);
        }

        ERC20 token = ERC20(auction.asset);
        if (currentHighestBid > 0) {
            token.safeTransfer(auction.highestBidder, currentHighestBid);
        }

        address newBidder = msg.sender;
        token.safeTransferFrom(newBidder, address(this), _bid);

        auction.highestBidder = newBidder;
        auction.highestBid = _bid;
        auction.lastBidTime = uint96(currentTime);

        emit BidPlaced(
            _contract,
            _tokenId,
            newBidder,
            _bid,
            auction.loanAddress,
            auction.loanId
        );
    }

    /// @notice On settlement, the NFT is sent to the highest bidder.
    ///         Calls loan liquidated for accounting purposes.
    function settleAuction(
        address _contract,
        uint256 _tokenId,
        bytes calldata _loan
    ) external nonReentrant {
        Auction storage auction = _auctions[_contract][_tokenId];

        if (auction.highestBidder == address(0)) {
            revert NoBidsError();
        }

        uint256 currentTime = block.timestamp;
        uint96 expiration = auction.startTime + auction.duration;
        uint96 withMargin = auction.lastBidTime + _MIN_NO_ACTION_MARGIN;
        if ((withMargin > currentTime) || (currentTime < expiration)) {
            uint96 max = withMargin > expiration ? withMargin : expiration;
            revert AuctionNotOverError(max);
        }

        uint256 highestBid = auction.highestBid;

        uint256 triggerFee = highestBid.mulDivDown(_triggerFee, _BPS);

        uint256 proceeds = highestBid - 2 * triggerFee;

        ERC20(auction.asset).safeTransfer(auction.originator, triggerFee);

        ERC20(auction.asset).safeTransfer(msg.sender, triggerFee);

        ERC20(auction.asset).approve(auction.loanAddress, proceeds);

        ERC721(_contract).safeTransferFrom(
            address(this),
            auction.highestBidder,
            _tokenId
        );

        IBaseLoan(auction.loanAddress).loanLiquidated(
            _contract,
            _tokenId,
            auction.loanId,
            proceeds,
            _loan
        );

        emit AuctionSettled(
            auction.loanAddress,
            auction.loanId,
            _contract,
            _tokenId,
            auction.asset,
            proceeds,
            msg.sender,
            triggerFee
        );

        /// @dev Save gas + allow for future auctions for the same NFT
        delete _auctions[_contract][_tokenId];
    }

    function _updateTriggerFee(uint256 triggerFee) private {
        if (triggerFee > MAX_TRIGGER_FEE) {
            revert InvalidTriggerFee(triggerFee);
        }
        _triggerFee = triggerFee;

        emit TriggerFeeUpdated(triggerFee);
    }
}