// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../interfaces/IJPEGCardsCigStaking.sol";

contract JPEGAuction is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    event NewAuction(
        IERC721Upgradeable indexed nft,
        uint256 indexed index,
        uint256 startTime
    );
    event NewBid(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidValue
    );
    event JPEGDeposited(address indexed account, uint256 currentAmount);
    event CardDeposited(address indexed account, uint256 index);
    event JPEGWithdrawn(address indexed account, uint256 amount);
    event CardWithdrawn(address indexed account, uint256 index);
    event NFTClaimed(uint256 indexed auctionId);
    event BidWithdrawn(
        uint256 indexed auctionId,
        address indexed account,
        uint256 bidValue
    );
    event BidTimeIncrementChanged(uint256 newTime, uint256 oldTime);
    event JPEGLockAmountChanged(uint256 newLockAmount, uint256 oldLockAmount);
    event LockDurationChanged(uint256 newDuration, uint256 oldDuration);
    event MinimumIncrementRateChanged(
        Rate newIncrementRate,
        Rate oldIncrementRate
    );

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    enum StakeMode {
        CIG,
        JPEG,
        CARD,
        LEGACY
    }

    struct UserInfo {
        StakeMode stakeMode;
        uint256 stakeArgument; //unused for CIG
        uint256 unlockTime; //unused for CIG
    }

    struct Auction {
        IERC721Upgradeable nftAddress;
        uint256 nftIndex;
        uint256 startTime;
        uint256 endTime;
        uint256 minBid;
        address highestBidOwner;
        bool ownerClaimed;
        mapping(address => uint256) bids;
    }

    IERC20Upgradeable public jpeg;
    IERC721Upgradeable public cards;
    IJPEGCardsCigStaking public cigStaking;
    JPEGAuction public legacyAuction;

    uint256 public lockDuration;
    uint256 public jpegAmountNeeded;
    uint256 public bidTimeIncrement;
    uint256 public auctionsLength;

    Rate public minIncrementRate;

    mapping(address => UserInfo) public userInfo;
    mapping(address => EnumerableSetUpgradeable.UintSet) internal userAuctions;
    mapping(uint256 => Auction) public auctions;

    function initialize(
        IERC20Upgradeable _jpeg,
        IERC721Upgradeable _cards,
        IJPEGCardsCigStaking _cigStaking,
        JPEGAuction _legacyAuction,
        uint256 _jpegLockAmount,
        uint256 _lockDuration,
        uint256 _bidTimeIncrement,
        Rate memory _incrementRate
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        jpeg = _jpeg;
        cards = _cards;
        cigStaking = _cigStaking;
        legacyAuction = _legacyAuction;

        setJPEGLockAmount(_jpegLockAmount);
        setLockDuration(_lockDuration);
        setBidTimeIncrement(_bidTimeIncrement);
        setMinimumIncrementRate(_incrementRate);
    }

    /// @notice Allows the owner to create a new auction
    /// @param _nft The address of the NFT to sell
    /// @param _idx The index of the NFT to sell
    /// @param _startTime The time at which the auction starts
    /// @param _endTime The time at which the auction ends
    /// @param _minBid The minimum bid value
    function newAuction(
        IERC721Upgradeable _nft,
        uint256 _idx,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minBid
    ) external onlyOwner {
        require(address(_nft) != address(0), "INVALID_NFT");
        require(_startTime > block.timestamp, "INVALID_START_TIME");
        require(_endTime > _startTime, "INVALID_END_TIME");
        require(_minBid > 0, "INVALID_MIN_BID");

        Auction storage auction = auctions[auctionsLength++];
        auction.nftAddress = _nft;
        auction.nftIndex = _idx;
        auction.startTime = _startTime;
        auction.endTime = _endTime;
        auction.minBid = _minBid;

        _nft.transferFrom(msg.sender, address(this), _idx);

        emit NewAuction(_nft, _idx, _startTime);
    }

    /// @notice Allows users to deposit (and lock) JPEG in this contract to get access to auctions.
    /// The amount deposited is defined by the `jpegAmountNeeded`, which can be modified by the owner.
    /// In case this happens, calling this function will correct the amount of jpeg deposited, either
    /// increasing it or decreasing it to match the `jpegAmountNeeded` variable.
    function correctDepositedJPEG() public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stakeMode != StakeMode.CARD, "STAKING_CARD");

        uint256 stakedAmount = user.stakeArgument;
        uint256 amountNeeded = jpegAmountNeeded;

        require(stakedAmount != amountNeeded, "ALREADY_CORRECT");

        user.stakeMode = StakeMode.JPEG;
        user.stakeArgument = amountNeeded;

        if (user.unlockTime == 0)
            user.unlockTime = block.timestamp + lockDuration;

        if (stakedAmount > amountNeeded)
            jpeg.transfer(msg.sender, stakedAmount - amountNeeded);
        else
            jpeg.transferFrom(
                msg.sender,
                address(this),
                amountNeeded - stakedAmount
            );

        emit JPEGDeposited(msg.sender, amountNeeded);
    }

    /// @notice Allows users to deposit (and lock) JPEG Cards in this contract to get access to auctions.
    /// @param _idx The index of the Card to deposit
    function depositCard(uint256 _idx) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        StakeMode stakeMode = user.stakeMode;
        require(
            stakeMode == StakeMode.CIG || stakeMode == StakeMode.LEGACY,
            "ALREADY_STAKING"
        );

        user.stakeMode = StakeMode.CARD;
        user.stakeArgument = _idx;
        user.unlockTime = block.timestamp + lockDuration;

        cards.transferFrom(msg.sender, address(this), _idx);

        emit CardDeposited(msg.sender, _idx);
    }

    /// @notice Allows users to bid on an auction. In case of multiple bids by the same user,
    /// the actual bid value is the sum of all bids.
    /// @param _auctionIndex The index of the auction to bid on
    function bid(uint256 _auctionIndex) public payable nonReentrant {
        Auction storage auction = auctions[_auctionIndex];
        uint256 endTime = auction.endTime;

        require(block.timestamp >= auction.startTime, "NOT_STARTED");
        require(block.timestamp < endTime, "ENDED_OR_INVALID");

        require(isAuthorized(msg.sender), "NOT_AUTHORIZED");

        uint256 previousBid = auction.bids[msg.sender];
        uint256 totalBid = msg.value + previousBid;
        uint256 currentMinBid = auction.bids[auction.highestBidOwner];
        currentMinBid +=
            (currentMinBid * minIncrementRate.numerator) /
            minIncrementRate.denominator;

        require(
            totalBid >= currentMinBid && totalBid >= auction.minBid,
            "INVALID_BID"
        );

        auction.highestBidOwner = msg.sender;
        auction.bids[msg.sender] = totalBid;

        if (previousBid == 0)
            assert(userAuctions[msg.sender].add(_auctionIndex));

        uint256 bidIncrement = bidTimeIncrement;
        if (bidIncrement > endTime - block.timestamp)
            auction.endTime = block.timestamp + bidIncrement;

        emit NewBid(_auctionIndex, msg.sender, totalBid);
    }

    /// @notice Allows the highest bidder to claim the NFT they bid on if the auction is already over.
    /// @param _auctionIndex The index of the auction to claim the NFT from
    function claimNFT(uint256 _auctionIndex) external nonReentrant {
        Auction storage auction = auctions[_auctionIndex];

        require(auction.highestBidOwner == msg.sender, "NOT_WINNER");
        require(block.timestamp >= auction.endTime, "NOT_ENDED");
        require(
            userAuctions[msg.sender].remove(_auctionIndex),
            "ALREADY_CLAIMED"
        );

        auction.nftAddress.transferFrom(
            address(this),
            msg.sender,
            auction.nftIndex
        );

        emit NFTClaimed(_auctionIndex);
    }

    /// @notice Allows users to deposit JPEG and bid on an auction.
    /// @param _auctionIndex The auction to bid on.
    function depositJPEGAndBid(uint256 _auctionIndex) external payable {
        correctDepositedJPEG();
        bid(_auctionIndex);
    }

    /// @notice Allows users to deposit a card and bid on an auction.
    /// @param _auctionIndex The auction to bid on.
    /// @param _idx The index of the card to deposit.
    function depositCardAndBid(uint256 _auctionIndex, uint256 _idx)
        external
        payable
    {
        depositCard(_idx);
        bid(_auctionIndex);
    }

    /// @notice Allows bidders to withdraw their bid. Only works if `msg.sender` isn't the highest bidder.
    /// @param _auctionIndex The auction to claim the bid from.
    function withdrawBid(uint256 _auctionIndex) public nonReentrant {
        Auction storage auction = auctions[_auctionIndex];

        require(auction.highestBidOwner != msg.sender, "HIGHEST_BID_OWNER");

        uint256 bidAmount = auction.bids[msg.sender];
        require(bidAmount > 0, "NO_BID");

        auction.bids[msg.sender] = 0;
        assert(userAuctions[msg.sender].remove(_auctionIndex));

        (bool sent, ) = payable(msg.sender).call{value: bidAmount}("");
        require(sent, "ETH_TRANSFER_FAILED");

        emit BidWithdrawn(_auctionIndex, msg.sender, bidAmount);
    }

    /// @notice Allows bidders to withdraw multiple bids. Only works if `msg.sender` isn't the highest bidder.
    /// @param _indexes The auctions to claim the bids from.
    function withdrawBids(uint256[] calldata _indexes) external {
        for (uint256 i; i < _indexes.length; i++) {
            withdrawBid(_indexes[i]);
        }
    }

    /// @notice Allows users that deposited a Card to withdraw it, if unlocked.
    function withdrawCard() external nonReentrant {
        UserInfo memory user = userInfo[msg.sender];
        require(user.stakeMode == StakeMode.CARD, "CARD_NOT_DEPOSITED");
        require(block.timestamp >= user.unlockTime, "LOCKED");

        require(userAuctions[msg.sender].length() == 0, "ACTIVE_BIDS");

        delete userInfo[msg.sender];

        uint256 cardIndex = user.stakeArgument;

        cards.transferFrom(address(this), msg.sender, cardIndex);

        emit CardWithdrawn(msg.sender, cardIndex);
    }

    /// @notice Allows users that deposited JPEG to withdraw it, if unlocked.
    function withdrawJPEG() external nonReentrant {
        UserInfo memory user = userInfo[msg.sender];
        require(user.stakeMode == StakeMode.JPEG, "JPEG_NOT_DEPOSITED");
        require(block.timestamp >= user.unlockTime, "LOCKED");

        require(userAuctions[msg.sender].length() == 0, "ACTIVE_BIDS");

        delete userInfo[msg.sender];

        uint256 jpegAmount = user.stakeArgument;

        jpeg.transfer(msg.sender, jpegAmount);

        emit JPEGWithdrawn(msg.sender, jpegAmount);
    }

    /// @notice Allows users to renounce to LEGACY StakeMode.
    /// Useful if they want to switch to CIG StakeMode without depositing JPEG/a Card.
    function renounceLegacyStakeMode() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.stakeMode == StakeMode.LEGACY, "NOT_LEGACY");

        delete userInfo[msg.sender];
    }

    /// @return Whether a user is authorized to bid or not.
    /// @param _account The address to check.
    function isAuthorized(address _account) public view returns (bool) {
        StakeMode stakeMode = userInfo[_account].stakeMode;

        if (stakeMode == StakeMode.CARD) return true;
        else if (stakeMode == StakeMode.JPEG)
            return userInfo[_account].stakeArgument >= jpegAmountNeeded;
        else if (stakeMode == StakeMode.CIG)
            return cigStaking.isUserStaking(_account);
        else return legacyAuction.isAuthorized(_account);
    }

    /// @return The list of active bids for an account.
    /// @param _account The address to check.
    function getActiveBids(address _account)
        external
        view
        returns (uint256[] memory)
    {
        return userAuctions[_account].values();
    }

    /// @return The active bid of an account for an auction.
    /// @param _auctionIndex The auction to retrieve the bid from.
    /// @param _account The bidder's account
    function getAuctionBid(uint256 _auctionIndex, address _account)
        external
        view
        returns (uint256)
    {
        return auctions[_auctionIndex].bids[_account];
    }

    /// @notice Allows the owner to withdraw ETH after a successful auction.
    /// @param _auctionIndex The auction to withdraw the ETH from
    function withdrawETH(uint256 _auctionIndex) external onlyOwner {
        Auction storage auction = auctions[_auctionIndex];

        require(block.timestamp >= auction.endTime, "NOT_ENDED");
        address highestBidder = auction.highestBidOwner;
        require(highestBidder != address(0), "NFT_UNSOLD");
        require(!auction.ownerClaimed, "ALREADY_CLAIMED");

        auction.ownerClaimed = true;

        (bool sent, ) = payable(msg.sender).call{
            value: auction.bids[highestBidder]
        }("");
        require(sent, "ETH_TRANSFER_FAILED");
    }

    /// @notice Allows the owner to withdraw an unsold NFT
    /// @param _auctionIndex The auction to withdraw the NFT from.
    function withdrawUnsoldNFT(uint256 _auctionIndex) external onlyOwner {
        Auction storage auction = auctions[_auctionIndex];

        require(block.timestamp >= auction.endTime, "NOT_ENDED");
        address highestBidder = auction.highestBidOwner;
        require(highestBidder == address(0), "NFT_SOLD");
        require(!auction.ownerClaimed, "ALREADY_CLAIMED");

        auction.ownerClaimed = true;

        auction.nftAddress.transferFrom(
            address(this),
            msg.sender,
            auction.nftIndex
        );
    }

    /// @notice Allows the owner to add accounts that are staking in the legacy contract
    /// @param _accounts The accounts to add
    function addLegacyAccounts(address[] calldata _accounts)
        external
        onlyOwner
    {
        for (uint256 i; i < _accounts.length; ++i) {
            address account = _accounts[i];
            require(
                userInfo[account].stakeMode == StakeMode.CIG,
                "ACCOUNT_ALREADY_STAKING"
            );

            userInfo[account].stakeMode = StakeMode.LEGACY;
        }
    }

    /// @notice Allows the owner to set the amount of time to increase an auction by if a bid happens in the last few minutes
    /// @param _newTime The new amount of time
    function setBidTimeIncrement(uint256 _newTime) public onlyOwner {
        require(_newTime > 0, "INVALID_TIME");

        emit BidTimeIncrementChanged(_newTime, bidTimeIncrement);

        bidTimeIncrement = _newTime;
    }

    /// @notice Allows the owner to set the amount of JPEG to lock to be able to participate in auctions.
    /// @param _lockAmount The amount of JPEG.
    function setJPEGLockAmount(uint256 _lockAmount) public onlyOwner {
        require(_lockAmount > 0, "INVALID_LOCK_AMOUNT");

        emit JPEGLockAmountChanged(_lockAmount, jpegAmountNeeded);

        jpegAmountNeeded = _lockAmount;
    }

    /// @notice Allows the owner to set the duration of locks.
    /// @param _newDuration The new lock duration
    function setLockDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "INVALID_LOCK_DURATION");

        emit LockDurationChanged(_newDuration, lockDuration);

        lockDuration = _newDuration;
    }

    /// @notice Allows the owner to set the minimum increment rate from the last highest bid.
    /// @param _newIncrementRate The new increment rate.
    function setMinimumIncrementRate(Rate memory _newIncrementRate)
        public
        onlyOwner
    {
        require(
            _newIncrementRate.denominator != 0 &&
                _newIncrementRate.denominator >= _newIncrementRate.numerator,
            "INVALID_RATE"
        );

        emit MinimumIncrementRateChanged(_newIncrementRate, minIncrementRate);

        minIncrementRate = _newIncrementRate;
    }
}