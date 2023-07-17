// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {EventType} from "./CollectionStructsAndEnums.sol";

interface IPoolActivityMonitor is IERC165 {
    /**
     * @dev This hook allows pool owners (i.e. owner of the LP token) to observe
     * changes to pools initiated by third-parties, i.e. swaps and deposits.
     *
     * @param amounts If `eventType` is a swap, then `amounts` is an array with
     * 3 elements. The first is the number of nfts swapped. The second is the
     * price of the last NFT swapped (after all fees are applied, i.e. input or
     * output amount if quantity were 1). The third is the total value of the
     * swap with fees included. If `eventType` is not a swap, then amounts is a
     * length 1 array of the amount of token/NFT deposited/withdrawn.
     */
    function onBalancesChanged(address poolAddress, EventType eventType, uint256[] memory amounts) external;
}