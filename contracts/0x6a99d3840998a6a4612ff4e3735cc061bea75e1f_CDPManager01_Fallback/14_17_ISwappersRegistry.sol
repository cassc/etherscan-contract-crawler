// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "./ISwapper.sol";


interface ISwappersRegistry {
    event SwapperAdded(ISwapper swapper);
    event SwapperRemoved(ISwapper swapper);

    function getSwapperId(ISwapper _swapper) external view returns (uint);
    function getSwapper(uint _id) external view returns (ISwapper);
    function hasSwapper(ISwapper _swapper) external view returns (bool);

    function getSwappersLength() external view returns (uint);
    function getSwappers() external view returns (ISwapper[] memory);
}