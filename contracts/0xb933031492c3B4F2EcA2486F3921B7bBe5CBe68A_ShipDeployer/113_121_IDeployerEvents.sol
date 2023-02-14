// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import {SetupReturnVars} from "szns/interfaces/IDeployerActions.sol";

interface IDeployerEvents {
    /// @notice When the the ship is created
    event NewShipCreated(
        uint256 timestamp,
        address captain,
        address[] targetedNFTs,
        uint256 minRaise,
        string name,
        string symbol,
        uint256 endDuration,
        SetupReturnVars addresses
    );
}