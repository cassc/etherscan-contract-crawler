// SPDX-License-Identifier: GPL-3.0

/// @title The Wizards DAO Auction House

// LICENSE
// AuctionHouse.sol is a modified version of the Nouns's Auction house.
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
//
// AuctionHouse.sol source code Copyright Zora licensed under the GPL-3.0 license.
// With modifications by Nounders DAO and Wizards DAO.

pragma solidity ^0.8.6;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAuctionHouse} from "./IAuctionHouse.sol";
import {IWizardToken} from "../IWizards.sol";
import {IWETH} from "../IWETH.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract AuctionHouse is
    IAuctionHouse,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMath for uint256;

    // The address of the creators of WizardDAO
    address public creatorsDAO;

    address public daoWallet;

    uint256 public creatorFeePercent;

    // The Wizards ERC721 token contract
    IWizardToken public wizards;

    // The address of the WETH contract
    address public weth;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The maximum amount of wizards that can be minted.
    uint256 public wizardCap;

    // we have reached the cap for total supply of wizards.
    bool public reachedCap;

    // The last wizardId minted for an auction.
    uint256 public lastWizardId;

    // The oneOfOneId to mint.
    uint48 public oneOfOneId;

    // To include 1-1 wizards in the auction
    bool public auctionOneOfOne;

    // RH:
    // Whitelist addresses
    mapping(uint256 => address) public whitelistAddrs;

    // Number of addresses in the current whitelist
    uint256 public whitelistSize;

    // The active auctions
    mapping(uint256 => IAuctionHouse.Auction) public auctions;
    uint8 public auctionCount;

    // record lastAuctionCount when updating auctionCount so when we attempt to settle the current
    // auction we get all the wizards.
    uint256 public lastAuctionCount;

    /**
     * @notice Require that the sender is the creators DAO.
     */
    modifier onlyCreatorsDAO() {
        require(msg.sender == creatorsDAO, "Sender is not the creators DAO");
        _;
    }

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        IWizardToken _wizards,
        address _creatorsDAO,
        address _daoWallet,
        address _weth,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration,
        bool _auctionOneOfOne,
        uint256 _wizardCap,
        uint8 _auctionCount
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        _pause();

        creatorsDAO = _creatorsDAO;
        daoWallet = _daoWallet;

        auctionCount = _auctionCount;
        creatorFeePercent = 10;

        auctionOneOfOne = _auctionOneOfOne;
        wizards = _wizards;
        weth = _weth;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
        wizardCap = _wizardCap;
    }

    /**
     * @notice Set the creators wallet address.
     * @dev Only callable by creators.
     */
    function setCreatorsDAO(address _creatorsDAO)
        external
        override
        onlyCreatorsDAO
    {
        creatorsDAO = _creatorsDAO;
        emit CreatorsDAOUpdated(_creatorsDAO);
    }

    /**
     * @notice Set the amount of wizards to auction.
     * @dev Only callable by owner.
     */
    function setAuctionCount(uint8 _auctionCount) external onlyOwner {
        lastAuctionCount = auctionCount;
        auctionCount = _auctionCount;
    }

    /**
     * @notice Set the WizardsDAO wallet address.
     * @dev Only callable by owner.
     */
    function setDAOWallet(address _daoWallet) external override onlyOwner {
        daoWallet = _daoWallet;
        emit DAOWalletUpdated(_daoWallet);
    }

    /**
     * @notice Settle all current auctions, mint new Wizards, and put them up for auction.
     */
    function settleCurrentAndCreateNewAuction()
        external
        override
        nonReentrant
        whenNotPaused
    {
        require(lastWizardId < wizardCap, "All wizards have been auctioned");

        // if lastAuctionCount is different than the auctionCount var set
        // that means we are undergoing a migration to a diff # of wizards being auctioned.
        uint256 toSettle = uint256(auctionCount);
        if (auctionCount != lastAuctionCount && lastAuctionCount != 0) {
            toSettle = uint256(lastAuctionCount);
        }

        // ensure all previous auctions have been settled
        for (uint256 i = toSettle; i >= 1; i--) {
            require(
                block.timestamp >= auctions[i].endTime,
                "All auctions have not completed"
            );
        }

        // settle past auctions
        for (uint256 i = 1; i <= toSettle; i++) {
            IAuctionHouse.Auction memory _a = auctions[i];

            // when paused an auction could have been settled
            if (!_a.settled) {
                _settleAuction(i);
            }
        }

        // further # of auctions will be current auctionCount
        lastAuctionCount = auctionCount;

        // RH:
        // refresh whitelist if whitelistDay
        if (auctions[1].isWhitelistDay) {
            _refreshWhitelist();
        }

        // start new auctions
        for (uint256 i = 1; i <= uint256(auctionCount); i++) {
            if (lastWizardId <= wizardCap && !reachedCap) {
                _createAuction(i);
            }
        }

        if ((lastWizardId == wizardCap) || reachedCap) {
            emit AuctionCapReached(wizardCap);
        }
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction(uint256 aId)
        external
        override
        whenPaused
        nonReentrant
    {
        _settleAuction(aId);
    }

    /**
     * @notice Create a bid for a Wizard with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 wizardId, uint256 aId)
        external
        payable
        override
        nonReentrant
    {
        IAuctionHouse.Auction memory _auction = auctions[aId];

        require(
            (aId <= uint256(auctionCount)) && (aId >= 1),
            "Auction Id is not currently open"
        );
        require(_auction.wizardId == wizardId, "Wizard not up for auction");
        require(block.timestamp < _auction.endTime, "Auction expired");
        require(msg.value >= reservePrice, "Must send at least reservePrice");
        require(
            msg.value >=
                _auction.amount +
                    ((_auction.amount * minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );

        // RH:
        // ensure bidder is in whitelist
        if (_auction.isWhitelistDay) {
            bool bidderInWhitelist;
            for (uint256 i = 0; i < whitelistSize; i += 1) {
                if (whitelistAddrs[i] == msg.sender) {
                    bidderInWhitelist = true;
                    break;
                }
            }
            require(bidderInWhitelist, "Bidder is not on whitelist");
        }

        address payable lastBidder = _auction.bidder;

        // refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }

        auctions[aId].amount = msg.value;
        auctions[aId].bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auctions[aId].endTime = _auction.endTime =
                block.timestamp +
                timeBuffer;
        }

        emit AuctionBid(
            _auction.wizardId,
            aId,
            msg.sender,
            msg.value,
            extended
        );

        if (extended) {
            emit AuctionExtended(_auction.wizardId, aId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused. If required, this function will start a new auction.
     */
    function unpause() external override onlyOwner {
        _unpause();

        // if lastAuctionCount is different than the auctionCount var set
        // that means we are undergoing a migration to a diff # of wizards being auctioned.
        if (auctionCount != lastAuctionCount && lastAuctionCount != 0) {
            // if in a migration we just want to unpause to allow settlement and new auction creation
            return;
        }

        for (uint256 i = 1; i <= uint256(auctionCount); i++) {
            IAuctionHouse.Auction memory _a = auctions[i];
            if (_a.startTime == 0 || _a.settled) {
                if (lastWizardId <= wizardCap && !reachedCap) {
                    _createAuction(i);
                }
            }
        }

        if ((lastWizardId == wizardCap) || reachedCap) {
            emit AuctionCapReached(wizardCap);
        }
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set whether we should auction 1-1's.
     * @dev Only callable by the owner.
     */
    function setAuctionOneOfOne(bool _auctionOneOfOne)
        external
        override
        onlyOwner
    {
        auctionOneOfOne = _auctionOneOfOne;

        emit AuctionOneOfOne(_auctionOneOfOne);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice)
        external
        override
        onlyOwner
    {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the max number of wizards that can be auctioned off.
     * @dev Only callable by the owner.
     */
    function setWizardCap(uint256 _cap) external override onlyOwner {
        wizardCap = _cap;
        emit AuctionCapUpdated(_cap);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage)
        external
        override
        onlyOwner
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(
            _minBidIncrementPercentage
        );
    }

    /**
     * @notice Set oneOfOneId to mint for the next auction.
     * @dev Only callable by the owner.
     */
    function setOneOfOneId(uint48 _oneOfOneId) external override onlyOwner {
        oneOfOneId = _oneOfOneId;
    }

    // RH:
    /**
     * @notice Set whitelist addresses for the next whitelist day
     * @dev Only callable by the owner.
     */
    function setWhitelistAddresses(address[] calldata _whitelistAddrs)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelistAddrs.length; i += 1) {
            whitelistAddrs[i] = _whitelistAddrs[i];
        }
        whitelistSize = _whitelistAddrs.length;
    }

    // RH:
    /**
     * @notice Remove whitelist restriction for any reason, but keep auction going
     * @dev Only callable by the owner.
     */
    function stopWhitelistDay() external override onlyOwner {
        whitelistSize = 0;
        for (uint256 i = 1; i <= uint256(auctionCount); i += 1) {
            auctions[i].isWhitelistDay = false;
        }
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * If the mint reverts, the minter was updated without pausing this contract first. To remedy this,
     * catch the revert and pause this contract.
     */
    function _createAuction(uint256 aId) internal {
        // every last wizard of the day is a 1-1 if 1-1 minting is enabled.
        if (aId % uint256(auctionCount) == 0 && auctionOneOfOne) {
            try wizards.mintOneOfOne(oneOfOneId) returns (
                uint256 wizardId,
                bool isOneOfOne
            ) {
                lastWizardId = wizardId;
                uint256 startTime = block.timestamp;
                uint256 endTime = startTime + duration;
                bool isWhitelistDay = whitelistSize > 0;

                // RH:
                auctions[aId] = Auction({
                    wizardId: wizardId,
                    amount: 0,
                    startTime: startTime,
                    endTime: endTime,
                    bidder: payable(0),
                    settled: false,
                    isWhitelistDay: isWhitelistDay
                });

                // RH:
                emit AuctionCreated(
                    wizardId,
                    aId,
                    startTime,
                    endTime,
                    isOneOfOne,
                    isWhitelistDay
                );
            } catch Error(string memory reason) {
                if (
                    keccak256(abi.encodePacked(reason)) !=
                    keccak256(abi.encodePacked("All wizards have been minted"))
                ) {
                    // if we have issues minting a 1-1 we should mint a regular wiz
                    // and disable 1-1 minting.
                    _mintGeneratedWizard(aId);
                    auctionOneOfOne = false;
                } else {
                    reachedCap = true;
                    _pause();
                }
            }

            return;
        }

        _mintGeneratedWizard(aId);
    }

    /**
     * @notice Mint a generated wizard.
     */
    function _mintGeneratedWizard(uint256 aId) internal {
        try wizards.mint() returns (uint256 wizardId) {
            lastWizardId = wizardId;
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;
            bool isWhitelistDay = whitelistSize > 0;

            // RH:
            auctions[aId] = Auction({
                wizardId: wizardId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false,
                isWhitelistDay: isWhitelistDay
            });

            emit AuctionCreated(
                wizardId,
                aId,
                startTime,
                endTime,
                false,
                isWhitelistDay
            );
        } catch Error(string memory reason) {
            if (
                keccak256(abi.encodePacked(reason)) !=
                keccak256(abi.encodePacked("All wizards have been minted"))
            ) {
                _pause();
            } else {
                reachedCap = true;
                _pause();
            }
        }
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     * @dev If there are no bids, the Wizard is burned.
     */
    function _settleAuction(uint256 aId) internal {
        IAuctionHouse.Auction memory _auction = auctions[aId];

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        auctions[aId].settled = true;

        if (_auction.bidder == address(0)) {
            wizards.burn(_auction.wizardId);
        } else {
            wizards.transferFrom(
                address(this),
                _auction.bidder,
                _auction.wizardId
            );
        }

        if (_auction.amount > 0) {
            uint256 amount = _auction.amount;            
            _safeTransferETHWithFallback(daoWallet, amount);
        }

        emit AuctionSettled(
            _auction.wizardId,
            aId,
            _auction.bidder,
            _auction.amount
        );
    }

    // RH:
    /**
     * @notice set whitelistSize to 0 after whitelist day
     */
    function _refreshWhitelist() internal {
        whitelistSize = 0;
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }
}