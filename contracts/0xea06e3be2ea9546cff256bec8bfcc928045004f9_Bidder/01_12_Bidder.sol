// SPDX-License-Identifier: GPL-3.0

import "./Doc.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {INounsAuctionHouse} from "./external/interfaces/INounsAuctionHouse.sol";
import {IBidder} from "./IBidder.sol";
import {ENSResolver} from "./ENSResolver.sol";

pragma solidity 0.8.19;

contract Bidder is IBidder, OwnableUpgradeable, PausableUpgradeable {
    /// The name of this contract
    string public constant name = "Federation AutoBidder v0.2";

    /// Base gas to refund
    uint256 public constant REFUND_BASE_GAS = 36000;

    /// Max priority fee used for refunds
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    /// Max gas units that will be refunded to a caller
    uint256 public constant MAX_REFUND_GAS_USED = 200_000;

    /// Max base fee to refund a caller
    uint256 public constant MAX_REFUND_BASE_FEE = 200 gwei;

    /// The ERC721 token address that we expect to win at auction
    IERC721 public token;

    /// The last block a bid was placed
    uint256 public lastBidBlock;

    /// The auction house address
    INounsAuctionHouse public auctionHouse;

    // The address for the ENS resolver
    address public ensResolver;

    /// The config for this bidder
    Config internal config;

    /// Do not leave implementation uninitialized
    constructor() {
        _disableInitializers();
    }

    /// Can only be called once
    function initialize(IERC721 t, INounsAuctionHouse ah, address _owner, address _ensResolver, Config memory cfg)
        external
        payable
        initializer
    {
        __Ownable_init();
        __Pausable_init();

        token = t;
        auctionHouse = ah;
        config = cfg;
        ensResolver = _ensResolver;

        if (msg.sender != _owner) {
            _transferOwnership(_owner);
        }
    }

    /// Submit a bid to the auction house
    /// @notice refunds gas and tips the caller
    function bid() external whenNotPaused returns (uint256, uint256) {
        uint256 startGas = gasleft();

        if (lastBidBlock == block.number) {
            revert ExistingBidInBlock();
        }

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

        emit BidMade(tx.origin, nounId, value);

        lastBidBlock = block.number;

        _refundGasAndTip(startGas);

        return (nounId, value);
    }

    /// Withdraw the given token id from this contract
    /// @notice refunds gas and tips the caller
    function withdraw(uint256 tId) external {
        uint256 startGas = gasleft();

        token.transferFrom(address(this), config.receiver, tId);

        _refundGasAndTip(startGas);
    }

    /// Withdraw contract balance
    function withdrawBalance() external onlyOwner {
        (bool sent,) = owner().call{value: address(this).balance}("");
        require(sent, "failed to withdraw ether");
    }

    /// Handles updating the config for this bidder
    function setConfig(Config calldata cfg) external onlyOwner {
        if (cfg.receiver == address(0)) {
            revert InvalidReceiver();
        }

        config = cfg;
        emit ConfigUpdate(cfg);
    }

    /// Claims an ENS reverse record for this contract address
    /// To remove an existing record call this fn with an empty name
    function setENSReverseRecord(string memory _name) external onlyOwner {
        bytes32 node = ENSResolver(ensResolver).setName(_name);
        emit ENSReverseRecordChanged(node, _name);
    }

    /// Sets the ENS resolver address
    /// Default on mainnet is: 0x084b1c3C81545d370f3634392De611CaaBFf8148
    function setENSResolver(address _resolver) external onlyOwner {
        ensResolver = _resolver;
        emit ENSResolverChanged(_resolver);
    }

    /// Locks the contract to prevent bidding
    function pause() external onlyOwner {
        _pause();
    }

    /// Unlocks the contract to allow bidding
    function unpause() external onlyOwner {
        _unpause();
    }

    /// Returns the config for this bidder
    function getConfig() external view returns (Config memory) {
        return config;
    }

    /// Refunds gas spent on tx to the caller; also provides a tip
    function _refundGasAndTip(uint256 startGas) internal {
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }

            uint256 basefee = min(block.basefee, MAX_REFUND_BASE_FEE);
            uint256 gasPrice = min(tx.gasprice, basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = min(startGas - gasleft() + REFUND_BASE_GAS, MAX_REFUND_GAS_USED);
            uint256 refundAmount = min(gasPrice * gasUsed, balance);
            uint256 refundAmountWithTip = min(refundAmount + config.tip, balance);
            (bool refundSent,) = tx.origin.call{value: refundAmountWithTip}("");
            emit GasRefund(tx.origin, refundAmountWithTip, refundSent);
        }
    }

    /// Returns the min of two integers
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// Can receive ETH
    receive() external payable {}
}