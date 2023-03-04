// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../../interfaces/internal/routes/INFTMarketBuyNow.sol";
import "../../../interfaces/internal/routes/INFTMarketReserveAuction.sol";

import "../NFTMarketRouterCore.sol";

/**
 * @title Wraps external calls to the NFTMarket contract.
 * @dev Each call uses standard APIs and params, along with the msg.sender appended to the calldata. They will decode
 * return values as appropriate. If any of these calls fail, the tx will revert with the original reason.
 * @author HardlyDifficult
 */
abstract contract NFTMarketRouterAPIs is NFTMarketRouterCore {
  function _createReserveAuctionV2(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice,
    uint256 exhibitionId
  ) internal returns (uint auctionId) {
    bytes memory returnData = _routeCallFromMsgSender(
      nftMarket,
      abi.encodeWithSelector(
        INFTMarketReserveAuction.createReserveAuctionV2.selector,
        nftContract,
        tokenId,
        reservePrice,
        exhibitionId
      )
    );
    auctionId = abi.decode(returnData, (uint256));
  }

  function _setBuyPrice(address nftContract, uint256 tokenId, uint256 price) internal {
    _routeCallFromMsgSender(
      nftMarket,
      abi.encodeWithSelector(INFTMarketBuyNow.setBuyPrice.selector, nftContract, tokenId, price)
    );
  }
}