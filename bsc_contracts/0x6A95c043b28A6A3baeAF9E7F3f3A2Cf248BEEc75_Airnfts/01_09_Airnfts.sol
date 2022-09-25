// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {Aggregator, Address} from "./Aggregator.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/**
 * @title Airnfts Aggregator
 * @author Fibswap <[email protected]>
 * @notice Airnft nft marketplace aggregator
 */
contract Airnfts is Aggregator, ERC721Holder {
  constructor(address _fibswap, address _target) Aggregator(_fibswap, _target) {}

  // ============ Modifiers =============

  // ============ Public Functions =============

  /**
   */
  function buyProxy(
    uint256 _id,
    address _receipt /*onlyFibswap*/
  ) external payable returns (bool) {
    require(Address.isContract(target), "!contract");

    // Try to execute the callData
    // the low level call will return `false` if its execution reverts
    bool success;
    (success, ) = target.call{value: msg.value}(abi.encodeWithSignature("buy(uint256)", _id));

    // Handle failure cases
    require(success, "!success");

    // send nft to receipt
    IERC721(target).safeTransferFrom(address(this), _receipt, _id, "");
    return success;
  }
}