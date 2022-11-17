pragma solidity ^0.8.0;

import {Address} from "../openzeppelin/utils/Address.sol";
import {ClonesUpgradeable} from "../openzeppelin/upgradeable/proxy/ClonesUpgradeable.sol";
import {IERC721Metadata} from "./../openzeppelin/token/ERC721/IERC721Metadata.sol";
import {IStaking} from "../../interfaces/IStaking.sol";
import {ITreasury} from "../../interfaces/ITreasury.sol";
import {ISettings} from "../../interfaces/ISettings.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IERC20} from "../openzeppelin/token/ERC20/IERC20.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";

library TokenVaultStakingLogic {
    uint256 constant REWARD_PER_SHARE_PRECISION = 10**24;

    //
    function newStakingInstance(
        address settings,
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) external returns (address) {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(string,string,uint256,address,uint256,uint256)",
            name,
            symbol,
            totalSupply,
            address(this),
            ISettings(settings).term1Duration(),
            ISettings(settings).term2Duration()
        );
        address staking = ClonesUpgradeable.clone(
            ISettings(settings).stakingTpl()
        );
        Address.functionCall(staking, _initializationCalldata);
        return staking;
    }

    function addRewardToken(address staking, address token) external {
        IStaking(staking).addRewardToken(token);
    }

    /**
     * for estimate withdraw amount
     */
    function estimateWithdrawAmount(
        DataTypes.EstimateWithdrawAmountParams memory params
    ) external pure returns (uint256) {
        require(params.withdrawAmount > 0, "zero amount");
        uint256 tokenAmt = params.withdrawAmount;
        require(params.stakingAmount >= tokenAmt, "invalid amount balance");

        if (params.infoSharedPerToken == 0) {
            params.infoSharedPerToken = REWARD_PER_SHARE_PRECISION;
        }
        uint256 rewardAmt;
        if (params.poolId == 1) {
            rewardAmt =
                (
                    (tokenAmt *
                        (params.sharedPerToken1 - params.infoSharedPerToken))
                ) /
                REWARD_PER_SHARE_PRECISION;
        } else if (params.poolId == 2) {
            rewardAmt =
                (
                    (tokenAmt *
                        (params.sharedPerToken2 - params.infoSharedPerToken))
                ) /
                REWARD_PER_SHARE_PRECISION;
        }
        uint256 withdrawAmt = rewardAmt;
        if (address(params.withdrawToken) == address(params.stakingToken)) {
            withdrawAmt += tokenAmt;
        }
        return withdrawAmt;
    }

    function estimateNewSharedRewardAmount(
        DataTypes.EstimateNewSharedRewardAmount memory params
    )
        public
        pure
        returns (uint256 newSharedPerTokenPool1, uint256 newSharedPerTokenPool2)
    {
        if (params.poolBalance1 > 0 || params.poolBalance2 > 0) {
            if (params.newRewardAmt > 0) {
                uint256 sharedAmt = (params.newRewardAmt *
                    REWARD_PER_SHARE_PRECISION *
                    10000) /
                    (params.poolBalance1 *
                        params.ratio1 +
                        params.poolBalance2 *
                        params.ratio2);
                if (params.poolBalance1 > 0) {
                    uint256 sharedTotal1 = (params.poolBalance1 *
                        sharedAmt *
                        params.ratio1) / 10000;
                    newSharedPerTokenPool1 = (sharedTotal1 /
                        params.poolBalance1);
                }
                if (params.poolBalance2 > 0) {
                    uint256 sharedTotal2 = (params.poolBalance2 *
                        sharedAmt *
                        params.ratio2) / 10000;
                    newSharedPerTokenPool2 = (sharedTotal2 /
                        params.poolBalance2);
                }
            }
        }
        return (newSharedPerTokenPool1, newSharedPerTokenPool2);
    }

    function getSharedPerToken(DataTypes.GetSharedPerTokenParams memory params)
        external
        view
        returns (uint256 sharedPerToken1, uint256 sharedPerToken2)
    {
        sharedPerToken1 = params.sharedPerToken1;
        sharedPerToken2 = params.sharedPerToken2;
        uint256 principalBalance = params.poolBalance1 + params.poolBalance2;
        if (principalBalance > 0) {
            uint256 newBalance = params.token.balanceOf(address(this));
            // check staking token
            if (address(params.token) == address(params.stakingToken)) {
                require(
                    newBalance >= params.totalUserFToken,
                    Errors.VAULT_STAKING_INVALID_BALANCE
                );
                newBalance = newBalance - params.totalUserFToken;
                require(
                    newBalance >= principalBalance,
                    Errors.VAULT_STAKING_INVALID_BALANCE
                );
                newBalance -= principalBalance;
            }
            require(
                newBalance >= params.currentRewardBalance,
                Errors.VAULT_STAKING_INVALID_BALANCE
            );
            uint256 rewardAmt = newBalance - params.currentRewardBalance;
            uint256 poolSharedAmt;
            uint256 incomeSharedAmt;
            (poolSharedAmt, incomeSharedAmt, ) = ITreasury(
                IVault(params.stakingToken).treasury()
            ).getNewSharedToken(params.token);
            rewardAmt += (poolSharedAmt + incomeSharedAmt);
            if (rewardAmt > 0) {
                uint256 newSharedPerTokenPool1;
                uint256 newSharedPerTokenPool2;
                (
                    newSharedPerTokenPool1,
                    newSharedPerTokenPool2
                ) = estimateNewSharedRewardAmount(
                    DataTypes.EstimateNewSharedRewardAmount({
                        newRewardAmt: rewardAmt,
                        poolBalance1: params.poolBalance1,
                        ratio1: params.ratio1,
                        poolBalance2: params.poolBalance2,
                        ratio2: params.ratio2
                    })
                );
                if (newSharedPerTokenPool1 > 0) {
                    sharedPerToken1 += newSharedPerTokenPool1;
                }
                if (newSharedPerTokenPool2 > 0) {
                    sharedPerToken2 += newSharedPerTokenPool2;
                }
            }
        }
        return (sharedPerToken1, sharedPerToken2);
    }
}