// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "../../../interfaces/internal/routes/INFTCollectionFactoryTimedEditions.sol";
import "../../../libraries/AddressLibrary.sol";

import "../NFTMarketRouterCore.sol";

/**
 * @title Wraps external calls to the NFTCollectionFactory contract.
 * @dev Each call uses standard APIs and params, along with the msg.sender appended to the calldata. They will decode
 * return values as appropriate. If any of these calls fail, the tx will revert with the original reason.
 * @author HardlyDifficult & reggieag
 */
abstract contract NFTCollectionFactoryRouterAPIs is NFTMarketRouterCore {
  function _createNFTTimedEditionCollection(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce
  ) internal returns (address collection) {
    bytes memory returnData = _routeCallFromMsgSender(
      nftCollectionFactory,
      abi.encodeWithSelector(
        INFTCollectionFactoryTimedEditions.createNFTTimedEditionCollection.selector,
        name,
        symbol,
        tokenURI,
        mintEndTime,
        approvedMinter,
        nonce
      )
    );
    collection = abi.decode(returnData, (address));
  }

  function _createNFTTimedEditionCollectionWithPaymentFactory(
    string calldata name,
    string calldata symbol,
    string calldata tokenURI,
    uint256 mintEndTime,
    address approvedMinter,
    uint96 nonce,
    CallWithoutValue calldata paymentAddressFactoryCall
  ) internal returns (address collection) {
    bytes memory returnData = _routeCallFromMsgSender(
      nftCollectionFactory,
      abi.encodeWithSelector(
        INFTCollectionFactoryTimedEditions.createNFTTimedEditionCollectionWithPaymentFactory.selector,
        name,
        symbol,
        tokenURI,
        mintEndTime,
        approvedMinter,
        nonce,
        paymentAddressFactoryCall
      )
    );
    collection = abi.decode(returnData, (address));
  }
}