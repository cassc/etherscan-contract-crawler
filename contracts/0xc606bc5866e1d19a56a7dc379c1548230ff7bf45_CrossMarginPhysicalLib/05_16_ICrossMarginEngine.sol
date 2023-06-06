// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Balance} from "../config/types.sol";

interface ICrossMarginEngine {
    /**
     * how the short should be settled
     */
    function getBatchSettlementForShorts(uint256[] calldata _tokenIds, uint256[] calldata _amounts)
        external
        view
        returns (Balance[] memory debts, Balance[] memory payouts);
}