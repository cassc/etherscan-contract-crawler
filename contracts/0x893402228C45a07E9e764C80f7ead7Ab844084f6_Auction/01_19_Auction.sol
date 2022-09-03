// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IPoolMaster.sol";
import "./interfaces/IAuction.sol";
import "./libraries/Decimal.sol";

/// @notice This contract is responsible for processing pool default auctions
contract Auction is IAuction, ERC721Upgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Decimal for uint256;

    /// @notice PoolFactory contract
    IPoolFactory public factory;

    /// @notice Debt auction duration (in seconds)
    uint256 public auctionDuration;

    /// @notice Minimal ratio of initial bid to pool insurance (as 18-digit decimal)
    uint256 public minBidFactor;

    /// @notice Mapping of addresses to flags if they are whitelisted bidders
    mapping(address => bool) public isWhitelistedBidder;

    /// @notice Structure storing information about auction for some pool
    struct AuctionInfo {
        uint256 end;
        uint96 tokenId;
        address lastBidder;
        uint256 lastBid;
    }

    /// @notice Mapping of pool addresses to their debt auction info
    mapping(address => AuctionInfo) public auctionInfo;

    /// @notice Structure storing details of some token, representint pool debt
    struct TokenInfo {
        address pool;
        uint256 borrowsAtClaim;
        uint256 interestRate;
    }

    /// @notice Mapping of token IDs to their token info
    mapping(uint256 => TokenInfo) public tokenInfo;

    /// @notice Last debt token ID
    uint96 public lastTokenId;

    // EVENTS

    /// @notice Event emitted when debt auction is started for some pool
    /// @param pool Address of the pool
    /// @param bidder Account who initiated auction by placing first bid
    event AuctionStarted(address indexed pool, address indexed bidder);

    /// @notice Event emitted when bid is placed for some pool
    /// @param pool Address of the pool
    /// @param bidder Account who made bid
    /// @param amount Amount of the bid in pool's currency
    event Bid(address indexed pool, address indexed bidder, uint256 amount);

    /// @notice Event emitted when some address status as whitelisted bidder is changed
    /// @param bidder Account who's status was changed
    /// @param whitelisted True if account was whitelisted, false otherwise
    event WhitelistedBidderSet(address bidder, bool whitelisted);

    /// @notice Event emitted when auction duration is set
    /// @param duration New auction duration in seconds
    event AuctionDurationSet(uint256 duration);

    /// @notice Event emitted when auction end is set for some pool
    /// @param pool Address of the pool for which auction end is set
    /// @param end New auction end
    event AuctionEndSet(address pool, uint256 end);

    // CONSTRUCTOR

    /// @notice Upgradeable contract constructor
    /// @param factory_ Address of the PoolFactory
    /// @param auctionDuration_ Auction duration value
    /// @param minBidFactor_ Min bid factor value
    function initialize(
        address factory_,
        uint256 auctionDuration_,
        uint256 minBidFactor_
    ) external initializer {
        __Ownable_init();
        __ERC721_init("Ribbon Debt", "RDEBT");

        factory = IPoolFactory(factory_);
        auctionDuration = auctionDuration_;
        minBidFactor = minBidFactor_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Makes a bid on a pool
    /// @param pool Address of a pool
    /// @param amount Amount of the bid
    function bid(address pool, uint256 amount) external {
        require(factory.isPool(pool), "PNE");
        require(isWhitelistedBidder[msg.sender], "NWB");

        if (auctionInfo[pool].lastBidder == address(0)) {
            _startAuction(pool, amount);
        }

        require(block.timestamp < auctionInfo[pool].end, "AF");
        require(amount > auctionInfo[pool].lastBid, "NBG");

        IERC20Upgradeable currency = IERC20Upgradeable(
            IPoolMaster(pool).currency()
        );

        if (auctionInfo[pool].lastBidder != address(0)) {
            currency.safeTransfer(
                auctionInfo[pool].lastBidder,
                auctionInfo[pool].lastBid
            );
        }

        currency.safeTransferFrom(msg.sender, address(this), amount);
        auctionInfo[pool].lastBidder = msg.sender;
        auctionInfo[pool].lastBid = amount;

        emit Bid(pool, msg.sender, amount);
    }

    /// @notice Claims ownership of a pool if caller has won a auction
    /// @param pool Address of a pool
    function claimDebtOwnership(address pool) external {
        require(block.timestamp >= auctionInfo[pool].end, "ANF");
        require(auctionInfo[pool].tokenId == 0, "AC");
        require(msg.sender == auctionInfo[pool].lastBidder, "NLB");

        lastTokenId++;
        _mint(msg.sender, lastTokenId);
        tokenInfo[lastTokenId] = TokenInfo({
            pool: pool,
            borrowsAtClaim: IPoolMaster(pool).borrows(),
            interestRate: IPoolMaster(pool).getBorrowRate()
        });
        auctionInfo[pool].tokenId = lastTokenId;
        IPoolMaster(pool).processDebtClaim();

        IERC20Upgradeable(IPoolMaster(pool).currency()).safeTransfer(
            pool,
            auctionInfo[pool].lastBid
        );
    }

    // RESTRICTED FUNCTIONS

    /// @notice Function is used to set whitelisted status for some bidder (restricted to owner)
    /// @param bidder Address of the bidder
    /// @param whitelisted True if bidder should be whitelisted false otherwise
    function setWhitelistedBidder(address bidder, bool whitelisted)
        external
        onlyOwner
    {
        isWhitelistedBidder[bidder] = whitelisted;
        emit WhitelistedBidderSet(bidder, whitelisted);
    }

    /// @notice Function is used to set new value for auction duration
    /// @param auctionDuration_ Auction duration in seconds
    function setAuctionDuration(uint256 auctionDuration_) external onlyOwner {
        auctionDuration = auctionDuration_;
        emit AuctionDurationSet(auctionDuration_);
    }

    /// @notice Function is used to set new end for some already existing auction
    /// @param end New auction end timestamp (should be in future)
    function setPoolAuctionEnd(address pool, uint256 end) external onlyOwner {
        require(auctionInfo[pool].end > block.timestamp, "AF");
        require(end > block.timestamp, "ESF");

        auctionInfo[pool].end = end;
        emit AuctionEndSet(pool, end);
    }

    // VIEW FUNCTIONS

    /// @notice Returns owner of a debt
    /// @param pool Address of a pool
    /// @return Address of the owner
    function ownerOfDebt(address pool) external view returns (address) {
        return
            auctionInfo[pool].tokenId != 0
                ? ownerOf(auctionInfo[pool].tokenId)
                : address(0);
    }

    /// @notice Returns state of a pool auction
    /// @param pool Address of a pool
    /// @return state of a pool auction
    function state(address pool) external view returns (State) {
        if (IPoolMaster(pool).state() != IPoolMaster.State.Default) {
            return State.None;
        } else if (auctionInfo[pool].lastBidder == address(0)) {
            return State.NotStarted;
        } else if (block.timestamp < auctionInfo[pool].end) {
            return State.Active;
        } else if (
            block.timestamp >= auctionInfo[pool].end &&
            auctionInfo[pool].tokenId == 0
        ) {
            return State.Finished;
        } else {
            return State.Closed;
        }
    }

    // PRIVATE FUNCTIONS

    /// @notice Private function that starts auction for a pool
    /// @param poolAddress Address of the pool
    /// @param amount Amount of the initial bid
    function _startAuction(address poolAddress, uint256 amount) private {
        IPoolMaster pool = IPoolMaster(poolAddress);

        require(pool.state() == IPoolMaster.State.Default, "NID");
        require(amount >= pool.insurance().mulDecimal(minBidFactor), "LMB");

        pool.processAuctionStart();
        auctionInfo[poolAddress].end = block.timestamp + auctionDuration;

        emit AuctionStarted(poolAddress, msg.sender);
    }
}