// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ICurvePool.sol";

interface IFrxEthStableSwap is ICurvePool {
    function price_oracle() external view returns (uint256);
}