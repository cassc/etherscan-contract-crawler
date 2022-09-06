// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Wagies } from "./Wagies.sol";

contract ETHPriceIndicator is Ownable {
    /* Errors */

    error DataTooOld();
    error NotAuthorized();

    /* Constants */

    address constant FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    uint256 constant DECIMALS = 1e3;

    /* Storage */

    Wagies immutable _nft;
    AggregatorV3Interface _feed = AggregatorV3Interface(FEED);

    mapping(address => bool) _isUpdater;

    uint256 _requiredDifference = 10 * DECIMALS;
    uint256 maxRecordedPrice;

    bool _enableSale = true;

    constructor(Wagies nft) {
        _nft = nft;
    }

    /* Modifiers */

    modifier onlyUpdater() {
        if (!(_isUpdater[msg.sender] || msg.sender == owner())) revert NotAuthorized();
        _;
    }

    /* Non-view functions */

    function requestUpdate() external onlyUpdater {
        (, int256 price, , uint256 updatedAt, ) = _feed.latestRoundData();
        if (updatedAt + 1 hours < block.timestamp) revert DataTooOld();

        _checkDifference(uint256(price));
    }

    function setIsUpdater(address updater, bool value) public onlyOwner {
        _isUpdater[updater] = value;
    }

    /* View functions */

    function getRequiredDifference() external view returns (uint256) {
        return _requiredDifference;
    }

    /* onlyOwner functions */

    function setFeed(AggregatorV3Interface feed) external onlyOwner {
        _feed = feed;
    }

    function changeRequiredDifference(uint256 requiredDifference) public onlyOwner {
        _requiredDifference = requiredDifference;
    }

    function toggleEnableSale() external onlyOwner {
        _enableSale = !_enableSale;
    }

    /* Internal functions */

    function _checkDifference(uint256 currentPrice) internal {
        if (currentPrice >= maxRecordedPrice) {
            maxRecordedPrice = currentPrice;
            return;
        }

        uint256 difference = ((maxRecordedPrice - currentPrice) * 100 * DECIMALS) / maxRecordedPrice;
        if (difference >= _requiredDifference) {
            if(_enableSale) _nft.ethPriceIndicatorEnable(difference);
            maxRecordedPrice = currentPrice;
        }
    }
}