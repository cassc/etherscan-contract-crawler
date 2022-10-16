// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {KeeperCompatibleInterface} from "../interfaces/KeeperCompatibleInterface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IGaugeVoterV2} from "../interfaces/IGaugeVoterV2.sol";
import {IFeeDistributor} from "../interfaces/IFeeDistributor.sol";
import {Epoch} from "../utils/Epoch.sol";
import {console} from "hardhat/console.sol";

/**
 * @dev This keeper contract rewards the caller with MAHA and distributes the
 * staking rewards every week.
 */
contract StakingRewardsKeeper is Epoch, KeeperCompatibleInterface {
    IFeeDistributor[] public distributors;
    IERC20[] public tokens;
    uint256[] public tokenRates;

    IERC20 public maha;
    uint256 public mahaRewardPerEpoch;

    constructor(
        IFeeDistributor[] memory _distributors,
        IERC20[] memory _tokens,
        uint256[] memory _tokenRates,
        IERC20 _maha,
        uint256 _mahaRewardPerEpoch
    ) Epoch(86400 * 7, block.timestamp, 0) {
        distributors = _distributors;
        tokens = _tokens;
        maha = _maha;
        mahaRewardPerEpoch = _mahaRewardPerEpoch;
        tokenRates = _tokenRates;
    }

    function updateMahaReward(uint256 reward) external onlyOwner {
        mahaRewardPerEpoch = reward;
    }

    function addDistributor(
        address _distributor,
        address _token,
        uint256 _tokenRate
    ) external onlyOwner {
        distributors.push(IFeeDistributor(_distributor));
        tokens.push(IERC20(_token));
        tokenRates.push(_tokenRate);
    }

    function updateDistributorReward(uint256 _tokenIndex, uint256 _tokenRate)
        external
        onlyOwner
    {
        tokenRates[_tokenIndex] = _tokenRate;
    }

    function checkUpkeep(bytes calldata _checkData)
        external
        view
        override
        returns (bool, bytes memory)
    {
        return (_callable(), "");
    }

    function performUpkeep(bytes calldata performData)
        external
        override
        checkEpoch
    {
        for (uint256 index = 0; index < distributors.length; index++) {
            if (tokenRates[index] == 0) continue;
            tokens[index].transfer(
                address(distributors[index]),
                tokenRates[index]
            );
        }

        // give out maha rewards for upgrading the epoch
        if (performData.length > 0) {
            console.log(performData.length);

            require(
                maha.balanceOf(address(this)) >= mahaRewardPerEpoch,
                "not enough maha for rewards"
            );
            maha.transfer(msg.sender, mahaRewardPerEpoch);
        }
    }

    function refund(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}