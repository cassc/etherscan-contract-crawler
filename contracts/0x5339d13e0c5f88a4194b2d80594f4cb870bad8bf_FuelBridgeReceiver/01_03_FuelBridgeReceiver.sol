// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFuelBridgeReceiver} from "./interfaces/IFuelBridgeReceiver.sol";

/**
 * @title  Fuel Bridge Receiver on Ethereum
 * @notice Exited GET is sent to the contract to be sent to the staking contracts.
 * @author GET Protocol DAO
 */
contract FuelBridgeReceiver is IFuelBridgeReceiver {
    IERC20 public rootToken;
    address public destination;
    uint256 private locked = 1; // Used in reentrancy check.

    constructor(address rootToken_, address destination_) {
        rootToken = IERC20(rootToken_);
        destination = destination_;
    }

    /*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
    ░░░░                         Public Functions                          ░░░░
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*/

    /**
     * @inheritdoc IFuelBridgeReceiver
     */
    function transferToStakers() external override {
        uint256 rootTokenBalance_ = rootToken.balanceOf(address(this));

        require(rootToken.transfer(destination, rootTokenBalance_), "FBR:TRANSFER_FAILED");

        emit TransferredToStakers(rootTokenBalance_);
    }
}