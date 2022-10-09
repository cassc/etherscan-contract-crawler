// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRematicAdmin {

    function setBalance(address payable account, uint256 newBalance, uint256 _txAmount) external;

    function recordTransactionHistoryForHoldersPartition(address payable account, uint256 _txAmount, bool isSell) external;

    function startLiquidate() external;

    function pancakeSwapPair() external returns(address);
    function pancakeSwapRouter02Address() external returns(address);

    function _excludeFromDividendsByRematic(address _address) external;

    function isLiquidationProcessing() external returns(bool);

    function mintDividendTrackerToken(address account, uint256 amount) external;
}