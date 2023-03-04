// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../../interfaces/internal/routes/INFTDropMarketFixedPriceSale.sol";

import "../NFTMarketRouterCore.sol";

/**
 * @title Wraps external calls to the NFTDropMarket contract.
 * @dev Each call uses standard APIs and params, along with the msg.sender appended to the calldata. They will decode
 * return values as appropriate. If any of these calls fail, the tx will revert with the original reason.
 * @author HardlyDifficult & reggieag
 */
abstract contract NFTDropMarketRouterAPIs is NFTMarketRouterCore {
  function _createFixedPriceSaleV3(
    address nftContract,
    uint256 exhibitionId,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 txDeadlineTime
  ) internal {
    _routeCallFromMsgSender(
      nftDropMarket,
      abi.encodeWithSelector(
        INFTDropMarketFixedPriceSale.createFixedPriceSaleV3.selector,
        nftContract,
        exhibitionId,
        price,
        limitPerAccount,
        generalAvailabilityStartTime,
        txDeadlineTime
      )
    );
  }
}