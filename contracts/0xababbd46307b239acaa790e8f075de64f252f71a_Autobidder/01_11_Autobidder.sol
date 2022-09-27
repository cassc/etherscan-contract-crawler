// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INounsToken} from "./interfaces/INounsToken.sol";
import {INounsAuctionHouse} from "./interfaces/INounsAuctionHouse.sol";

// Contact: https://twitter.com/w1nt3r_eth/
contract Autobidder is Ownable2Step {
    struct Config {
        uint96 maxBid;
        uint96 maxGasPrice;
        uint48 maxSecondsBeforeEndTime;
        uint16 feePointsPer10k;
        address receiver;
    }

    error PermissionDenied();
    error NoBiddingAgainstOurselves();
    error BidTooLarge(uint256 bid, uint256 maxBid);
    error GasTooHigh(uint256 gasPrice, uint256 maxGasPrice);
    error TooEarly();
    error WithdrawingNounsRequiresFee();
    error InvalidReceiver();

    event ConfigChanged(Config config);

    INounsToken internal immutable nouns;
    INounsAuctionHouse internal immutable auction;

    address public relay;

    Config public config;
    mapping(uint256 => uint256) public fees;

    constructor(INounsToken _nouns, INounsAuctionHouse _auction, address _owner, address _relay, Config memory _config)
        payable
    {
        nouns = _nouns;
        auction = _auction;
        relay = _relay;
        config = _config;

        if (_config.receiver == address(0)) {
            revert InvalidReceiver();
        }

        if (msg.sender != _owner) {
            _transferOwnership(_owner);
        }
    }

    modifier refundsGas() {
        uint256 refund;
        unchecked {
            refund = gasleft() + 25_562;
        }

        _;

        assembly {
            refund := mul(sub(refund, gas()), gasprice())
        }
        payable(tx.origin).transfer(refund);
    }

    modifier onlyOwnerOrRelay() {
        if (msg.sender != relay && msg.sender != owner()) {
            revert PermissionDenied();
        }

        _;
    }

    function configure(Config calldata _config) external onlyOwner {
        if (_config.receiver == address(0)) {
            revert InvalidReceiver();
        }

        config = _config;
        emit ConfigChanged(_config);
    }

    function createBid(uint256 _nounId) external refundsGas onlyOwnerOrRelay {
        (, uint256 amount,, uint256 endTime, address bidder,) = auction.auction();
        Config memory cfg = config;

        uint256 value;

        if (amount == 0) {
            value = auction.reservePrice();
        } else {
            value = amount + ((amount * auction.minBidIncrementPercentage()) / 100);
        }

        if (bidder == address(this) || bidder == owner() || bidder == cfg.receiver) {
            revert NoBiddingAgainstOurselves();
        }

        if (value > cfg.maxBid) {
            revert BidTooLarge(value, cfg.maxBid);
        }

        if (tx.gasprice > cfg.maxGasPrice) {
            revert GasTooHigh(tx.gasprice, cfg.maxGasPrice);
        }

        if (block.timestamp + cfg.maxSecondsBeforeEndTime < endTime) {
            revert TooEarly();
        }

        auction.createBid{value: value}(_nounId);

        // Reserve service fee
        fees[_nounId] = (value * cfg.feePointsPer10k) / 10_000;
    }

    function withdrawNoun(uint256 _nounId) external payable refundsGas onlyOwnerOrRelay {
        address receiver = config.receiver;
        address to = config.receiver != address(0) ? receiver : owner();

        nouns.safeTransferFrom(address(this), to, _nounId);
        payable(relay).transfer(fees[_nounId]);
        fees[_nounId] = 0;
    }

    function execTransaction(address target, bytes calldata data, uint256 value) external payable onlyOwner {
        if (target == address(nouns)) {
            revert WithdrawingNounsRequiresFee();
        }

        (bool success, bytes memory reason) = target.call{value: value}(data);
        require(success, string(reason));
    }

    receive() external payable {}
}