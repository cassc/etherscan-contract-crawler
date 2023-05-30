// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISelfMulticall.sol";

interface IExtendedSelfMulticall is ISelfMulticall {
    function getChainId() external view returns (uint256);

    function getBalance(address account) external view returns (uint256);

    function containsBytecode(address account) external view returns (bool);

    function getBlockNumber() external view returns (uint256);

    function getBlockTimestamp() external view returns (uint256);

    function getBlockBasefee() external view returns (uint256);
}