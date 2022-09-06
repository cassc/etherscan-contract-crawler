// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {KeeperCompatibleInterface} from "../interfaces/KeeperCompatibleInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGMUOracle} from "../interfaces/IGMUOracle.sol";

/**
 * @dev This keeper contract rewards the caller with a certain amount of MAHA based on their
 * contribution to keeping the oracle up-to-date
 */
contract MahaKeeper is Ownable, KeeperCompatibleInterface {
    IGMUOracle public gmuOracle;
    IERC20 public maha;
    uint256 mahaRewardPerEpoch;

    constructor(
        IGMUOracle _gmuOracle,
        uint256 _mahaRewardPerEpoch,
        IERC20 _maha
    ) {
        gmuOracle = _gmuOracle;
        mahaRewardPerEpoch = _mahaRewardPerEpoch;
        maha = _maha;
    }

    function updateMahaReward(uint256 reward) external onlyOwner {
        mahaRewardPerEpoch = reward;
    }

    function checkUpkeep(bytes calldata _checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (gmuOracle.callable()) upkeepNeeded = true;
        else upkeepNeeded = false;
    }

    function performUpkeep(bytes calldata performData) external override {
        require(
            maha.balanceOf(address(this)) >= mahaRewardPerEpoch,
            "not enough maha for rewards"
        );
        gmuOracle.updatePrice();
        maha.transfer(msg.sender, mahaRewardPerEpoch);
    }
}