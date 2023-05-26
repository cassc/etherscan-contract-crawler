// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../ERC721Auction.sol";
import "../../managers/TradeTokenManager.sol";

/**
 * @notice Mock Contract of ERC721Auction
 */
contract ERC721AuctionMock is ERC721Auction {
    uint256 public fakeBlockTimeStamp = 100;

    /**
     * @notice Auction Constructor
     * @param _serviceFeeProxy service fee proxy
     */
    constructor(
        address _serviceFeeProxy,
        address _tradeTokenManager
    ) ERC721Auction(_serviceFeeProxy, _tradeTokenManager)
    public {}

    function setBlockTimeStamp(uint256 _now) external {
        fakeBlockTimeStamp = _now;
    }

    function _getNow() internal override view returns (uint256) {
        return fakeBlockTimeStamp;
    }
}