// SPDX-License-Identifier: GPL-3.0

import "./Doc.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {INounsAuctionHouse} from "./external/interfaces/INounsAuctionHouse.sol";
import {IBidder} from "./IBidder.sol";

pragma solidity 0.8.19;

contract Bidder is IBidder, OwnableUpgradeable, PausableUpgradeable {
    /// Base gas to refund
    uint256 public constant REFUND_BASE_GAS = 36000;

    // Max priority fee used for refunds
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    /// Max gas units that will be refunded to a caller
    uint256 public constant MAX_REFUND_GAS_USED = 200_000;

    /// Max base fee to refund a caller
    uint256 public constant MAX_REFUND_BASE_FEE = 200 gwei;

    // The ERC721 token address that is being bid on
    IERC721 public token;

    // The auction house address
    INounsAuctionHouse public auctionHouse;

    // The last token id that was bid on
    uint256 public lastTokenId;

    // The config for this bidder
    Config internal config;

    // The last bidder for each token id
    mapping(uint256 => address) internal lastBidderForToken;

    /// @notice do not leave impl uninitialized
    constructor() {
        _disableInitializers();
    }

    /// @notice initializer; can only be called once
    function initialize(IERC721 t, INounsAuctionHouse ah, address _owner, Config memory cfg)
        external
        payable
        initializer
    {
        __Ownable_init();
        __Pausable_init();

        token = t;
        auctionHouse = ah;
        config = cfg;

        if (msg.sender != _owner) {
            _transferOwnership(_owner);
        }
    }

    /// @notice Submit a bid to the auction house
    function bid() external whenNotPaused returns (uint256, uint256) {
        uint256 startGas = gasleft();

        (uint256 nounId, uint256 amount,, uint256 endTime, address bidder,) = auctionHouse.auction();

        if (block.timestamp + config.bidWindow < endTime) {
            revert NotInBidWindow();
        }

        if (bidder == address(this)) {
            revert AlreadyHighestBidder();
        }

        uint256 value;
        if (amount > 0) {
            value = amount + ((amount * auctionHouse.minBidIncrementPercentage()) / 100);
        } else {
            value = auctionHouse.reservePrice();
        }

        if (value < config.minBid) {
            value = config.minBid;
        }

        if (value > config.maxBid) {
            revert MaxBidExceeded();
        }

        auctionHouse.createBid{value: value}(nounId);

        lastBidderForToken[nounId] = tx.origin;
        lastTokenId = nounId;

        emit BidMade(tx.origin, nounId, value);

        _refundGas(startGas);

        return (nounId, value);
    }

    /// @notice Withdraw the given token id from this contract
    function withdraw(uint256 tId) external {
        uint256 startGas = gasleft();

        address lb = lastBidderForToken[tId];
        if (lb == address(0)) {
            revert NoBidFoundForToken(tId);
        }

        token.transferFrom(address(this), config.receiver, tId);

        _tip(tId, lb);

        _refundGas(startGas);
    }

    /**
     * @notice Ensures that the last auction has been settled and that if an
     * auction was ever won all debts have been paid
     */
    modifier allDebtsPaid() {
        // auction that was last bid on has been settled
        (uint256 nounId,,,,,) = auctionHouse.auction();
        if (nounId == lastTokenId) {
            revert AuctionNotSettled();
        }

        // if this contract owns any tokens it means a tip has not been paid
        if (token.balanceOf(address(this)) > 0) {
            revert TipOwed();
        }

        _;
    }

    /// @notice Withdraw contract balance
    function withdrawBalance() external onlyOwner allDebtsPaid {
        (bool sent,) = owner().call{value: address(this).balance}("");
        require(sent, "failed to withdraw ether");
    }

    /// @notice Handles updating the config for this bidder
    function setConfig(Config calldata cfg) external onlyOwner allDebtsPaid {
        if (cfg.receiver == address(0)) {
            revert InvalidReceiver();
        }

        config = cfg;
        emit ConfigUpdate(cfg);
    }

    /// @notice Locks the contract to withdraw its balance or update config
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unlocks the contract to allow bidding
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Returns the config for this bidder
    function getConfig() external view returns (Config memory) {
        return config;
    }

    /// @notice Returns the last bidder for the given token id
    function getLastBidder(uint256 tId) external view returns (address) {
        return lastBidderForToken[tId];
    }

    /// @notice Sends tip to address
    function _tip(uint256 tId, address to) internal {
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }

            uint256 tipAmount = min(config.tip, balance);
            SafeTransferLib.forceSafeTransferETH(to, tipAmount);

            emit WithdrawAndTip(msg.sender, to, tId, tipAmount);
        }
    }

    /// @notice Refunds gas spent on transaction to the caller
    function _refundGas(uint256 startGas) internal {
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }

            uint256 basefee = min(block.basefee, MAX_REFUND_BASE_FEE);
            uint256 gasPrice = min(tx.gasprice, basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = min(startGas - gasleft() + REFUND_BASE_GAS, MAX_REFUND_GAS_USED);
            uint256 refundAmount = min(gasPrice * gasUsed, balance);
            (bool refundSent,) = tx.origin.call{value: refundAmount}("");
            emit GasRefund(tx.origin, refundAmount, refundSent);
        }
    }

    /// @notice Returns the min of two integers
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    receive() external payable {}
}