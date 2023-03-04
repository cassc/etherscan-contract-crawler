// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

error NFTMarketRouterCore_Call_Failed_Without_Revert_Reason();
error NFTMarketRouterCore_NFT_Collection_Factory_Is_Not_A_Contract();
error NFTMarketRouterCore_NFT_Drop_Market_Is_Not_A_Contract();
error NFTMarketRouterCore_NFT_Market_Is_Not_A_Contract();

/**
 * @title Shared logic for NFT Market Router mixins.
 * @author HardlyDifficult
 */
abstract contract NFTMarketRouterCore {
  using AddressUpgradeable for address;

  /**
   * @notice The address of the NFTMarket contract to which requests will be routed.
   */
  address internal immutable nftMarket;

  /**
   * @notice The address of the NFTDropMarket contract to which requests will be routed.
   */
  address internal immutable nftDropMarket;

  /**
   * @notice The address of the NFTCollectionFactory contract to which requests will be routed.
   */
  address internal immutable nftCollectionFactory;

  /**
   * @notice Initialize the template's immutable variables.
   * @param _nftMarket The address of the NFTMarket contract to which requests will be routed.
   * @param _nftDropMarket The address of the NFTDropMarket contract to which requests will be routed.
   * @param _nftCollectionFactory The address of the NFTCollectionFactory contract to which requests will be routed.
   */
  constructor(address _nftMarket, address _nftDropMarket, address _nftCollectionFactory) {
    if (!_nftCollectionFactory.isContract()) {
      revert NFTMarketRouterCore_NFT_Collection_Factory_Is_Not_A_Contract();
    }
    if (!_nftMarket.isContract()) {
      revert NFTMarketRouterCore_NFT_Market_Is_Not_A_Contract();
    }
    if (!_nftDropMarket.isContract()) {
      revert NFTMarketRouterCore_NFT_Drop_Market_Is_Not_A_Contract();
    }
    nftCollectionFactory = _nftCollectionFactory;
    nftDropMarket = _nftDropMarket;
    nftMarket = _nftMarket;
  }

  /**
   * @notice The address of the NFTMarket contract to which requests will be routed.
   * @return market The address of the NFTMarket contract.
   */
  function getNftMarketAddress() external view returns (address market) {
    market = nftMarket;
  }

  /**
   * @notice The address of the NFTDropMarket contract to which requests will be routed.
   * @return market The address of the NFTDropMarket contract.
   */
  function getNfDropMarketAddress() external view returns (address market) {
    market = nftDropMarket;
  }

  /**
   * @notice The address of the NFTCollectionFactory contract to which requests will be routed.
   * @return collectionFactory The address of the NFTCollectionFactory contract.
   */
  function getNftCollectionFactory() external view returns (address collectionFactory) {
    collectionFactory = nftCollectionFactory;
  }

  /**
   * @notice Routes a call to the specified contract, appending the msg.sender to the end of the calldata.
   * If the call reverts, this will revert the transaction and the original reason is bubbled up.
   * @param to The contract address to call.
   * @param callData The call data to use when calling the contract, without the msg.sender.
   */
  function _routeCallFromMsgSender(address to, bytes memory callData) internal returns (bytes memory returnData) {
    // Forward the call, with the packed msg.sender appended, to the specified contract.
    bool success;
    // solhint-disable-next-line avoid-low-level-calls
    (success, returnData) = to.call(abi.encodePacked(callData, msg.sender));

    // If the call failed, bubble up the revert reason.
    if (!success) {
      _revert(returnData);
    }
  }

  /**
   * @notice Bubbles up the original revert reason of a low-level call failure where possible.
   * @dev Copied from OZ's `Address.sol` library, with a minor modification to the final revert scenario.
   * This should only be used when a low-level call fails.
   */
  function _revert(bytes memory returnData) private pure {
    // Look for revert reason and bubble it up if present
    if (returnData.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returnData_size := mload(returnData)
        revert(add(32, returnData), returnData_size)
      }
    } else {
      revert NFTMarketRouterCore_Call_Failed_Without_Revert_Reason();
    }
  }
}