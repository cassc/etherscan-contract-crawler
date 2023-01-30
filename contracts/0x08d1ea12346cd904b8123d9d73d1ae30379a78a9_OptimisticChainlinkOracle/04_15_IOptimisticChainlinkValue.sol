// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IOptimisticChainlinkValue {
    function value(address token)
        external
        view
        returns (uint256 value_, bytes memory data);
}