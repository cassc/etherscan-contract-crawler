/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LyraAdapter} from "@lyrafinance/protocol/contracts/periphery/LyraAdapter.sol";

interface IPositionHandler {
    function wantTokenL2() external view returns (address);

    function positionInWantToken() external view returns (uint256, uint256);

    function openPosition(
        uint256 listingId,
        bool isCall,
        uint256 amount,
        bool updateExistingPosition
    ) external returns (LyraAdapter.TradeResult memory);

    function closePosition(bool toSettle) external;

    function deposit() external;

    function withdraw(
        uint256 amountOut,
        address socketRegistry,
        bytes calldata socketData
    ) external;

    function sweep(address _token) external;

    function isCurrentPositionActive() external view returns (bool);
}