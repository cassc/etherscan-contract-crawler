// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IWETH} from "./IWETH.sol";
import {ILendPool} from "./ILendPool.sol";
import {IAaveLendPool} from "./IAaveLendPool.sol";

interface IDownpayment {
    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function WETH() external view returns (IWETH);

    function getFee(address adapter) external view returns (uint256);

    function getFeeCollector() external view returns (address);

    function getBendLendPool() external view returns (ILendPool);

    function getAaveLendPool() external view returns (IAaveLendPool);

    function nonces(address owner) external view returns (uint256);

    function isAdapterWhitelisted(address adapter) external view returns (bool);

    function viewCountWhitelistedAdapters() external view returns (uint256);

    function viewWhitelistedAdapters(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function buy(
        address adapter,
        uint256 borrowAmount,
        bytes calldata data,
        Sig calldata sig
    ) external payable;

    function addAdapter(address adapter) external;

    function removeAdapter(address adapter) external;
}