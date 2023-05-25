/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6 <0.9.0;

interface IPositionHandler {
    struct PerpPosition {
        uint256 entryMarkPrice;
        uint256 entryIndexPrice;
        uint256 entryAmount;
        bool isShort;
        bool isActive;
    }

    function openPosition(
        bool _isShort,
        uint256 _amount,
        uint24 _slippage
    ) external;

    function closePosition(uint24 _slippage) external;

    function withdraw(
        uint256 amountOut,
        address allowanceTarget,
        address socketRegistry,
        bytes calldata socketData
    ) external;

    function sweep(address _token) external;
}