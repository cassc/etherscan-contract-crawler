// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {Epoch} from "./utils/Epoch.sol";
import {IGaugeVoter} from "./interfaces/IGaugeVoter.sol";
import {IRegistry} from "./interfaces/IRegistry.sol";
import {IEmissionController} from "./interfaces/IEmissionController.sol";

contract EmissionController is IEmissionController, Epoch {
    IRegistry public registry;

    uint256 public ratePerEpoch;
    mapping(address => address) public tokenStakingPool;

    event RateUpdated(uint256 old, uint256 rate);

    constructor(address _registry, uint256 _ratePerEpoch)
        Epoch(7 days, block.timestamp, 0)
    {
        registry = IRegistry(_registry);
        ratePerEpoch = _ratePerEpoch;
    }

    function allocateEmission() external override checkEpoch {
        uint256 mahaBalance = IERC20(registry.maha()).balanceOf(address(this));

        // figure out how much tokens to send
        uint256 balanceToSend;

        // if a rate was not set, then we send everything in the contract
        if (ratePerEpoch == 0)
            balanceToSend = mahaBalance;

            // if a rate was set, then we send as much as we can
        else balanceToSend = Math.min(mahaBalance, ratePerEpoch);

        require(balanceToSend > 0, "no maha to send");

        // approve token and notify the gauge voter
        IERC20(registry.maha()).transfer(registry.gaugeVoter(), balanceToSend);
        IGaugeVoter(registry.gaugeVoter()).notifyRewardAmount(balanceToSend);
    }

    function updateRate(uint256 epochRate) external onlyOwner {
        emit RateUpdated(ratePerEpoch, epochRate);
        ratePerEpoch = epochRate;
    }
}