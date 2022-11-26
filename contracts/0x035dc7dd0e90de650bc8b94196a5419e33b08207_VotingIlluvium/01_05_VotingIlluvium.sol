// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IERC20} from "./interfaces/staking/IERC20.sol";
import {ICorePoolV1, V1Stake} from "./interfaces/staking/ICorePoolV1.sol";
import {ICorePoolV2, V2Stake, V2User} from "./interfaces/staking/ICorePoolV2.sol";
import {IVesting} from "./interfaces/vesting/IVesting.sol";

contract VotingIlluvium {
    string public constant name = "Voting Illuvium";
    string public constant symbol = "vILV";

    uint256 public constant decimals = 18;

    address public constant ILV = 0x767FE9EDC9E0dF98E07454847909b5E959D7ca0E;
    address public constant ILV_POOL =
        0x25121EDDf746c884ddE4619b573A7B10714E2a36;
    address public constant ILV_POOL_V2 =
        0x7f5f854FfB6b7701540a00C69c4AB2De2B34291D;
    address public constant LP_POOL =
        0x8B4d8443a0229349A9892D4F7CbE89eF5f843F72;
    address public constant LP_POOL_V2 =
        0xe98477bDc16126bB0877c6e3882e3Edd72571Cc2;
    address public constant VESTING =
        0x6Bd2814426f9a6abaA427D2ad3FC898D2A57aDC6;

    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant MAX_WEIGHT_MULTIPLIER = 2e6;
    uint256 internal constant BASE_WEIGHT = 1e6;
    uint256 internal constant MAX_STAKE_PERIOD = 365 days;

    function balanceOf(address _account)
        external
        view
        returns (uint256 balance)
    {
        // Get balance staked as deposits + yield in the v2 ilv pool
        uint256 ilvPoolV2Balance = ICorePoolV2(ILV_POOL_V2).balanceOf(_account);

        // Now we need to get deposits + yield in v1.
        // Copy the v2 user struct to memory and number of stakes in v2.
        V2User memory user = ICorePoolV2(ILV_POOL_V2).users(_account);
        // Get number of stakes in v2
        uint256 userStakesLength = ICorePoolV2(ILV_POOL_V2).getStakesLength(
            _account
        );

        // Loop over each stake, compute its weight and add to v2StakedWeight
        uint256 v2StakedWeight;
        for (uint256 i = 0; i < userStakesLength; i++) {
            // Read stake in ilv pool v2 contract
            V2Stake memory stake = ICorePoolV2(ILV_POOL_V2).getStake(
                _account,
                i
            );
            // Computes stake weight based on lock period and balance
            uint256 stakeWeight = _getStakeWeight(stake);
            v2StakedWeight += stakeWeight;
        }
        // V1 yield balance can be determined by the difference of
        // the user total weight and the v2 staked weight.
        // any extra weight that isn't coming from v2 = v1YieldWeight
        uint256 v1YieldBalance = user.totalWeight > v2StakedWeight
            ? (user.totalWeight - v2StakedWeight) / MAX_WEIGHT_MULTIPLIER
            : 0;

        // To finalize, we need to get the total amount of deposits
        // that are still in v1
        uint256 v1DepositBalance;
        // Loop over each v1StakeId stored in V2 contract.
        // Each stake id represents a deposit in v1
        for (uint256 i = 0; i < user.v1IdsLength; i++) {
            uint256 v1StakeId = ICorePoolV2(ILV_POOL_V2).getV1StakeId(
                _account,
                i
            );
            // Call v1 contract for deposit balance
            v1DepositBalance += (
                ICorePoolV1(ILV_POOL).getDeposit(_account, v1StakeId)
            ).tokenAmount;
        }

        // Now sum the queried ilv pool v2 balance with
        // the v1 yield balance and the v1 deposit balance
        // to have the final result
        uint256 totalILVPoolsBalance = ilvPoolV2Balance +
            v1YieldBalance +
            v1DepositBalance;

        // And simply query ILV normalized values from LP pools
        // V1 and V2
        uint256 lpPoolBalance = _lpToILV(
            ICorePoolV1(LP_POOL).balanceOf(_account)
        );
        uint256 lpPoolV2Balance = _lpToILV(
            ICorePoolV2(LP_POOL_V2).balanceOf(_account)
        );

        // We manually query index 0 because current vesting state in L1 is one position per address
        // If this changes we need to change the approach
        uint256 vestingBalance;

        try IVesting(VESTING).tokenOfOwnerByIndex(_account, 0) returns (
            uint256 vestingPositionId
        ) {
            vestingBalance = (IVesting(VESTING).positions(vestingPositionId))
                .balance;
        } catch Error(string memory) {}

        balance =
            totalILVPoolsBalance +
            lpPoolBalance +
            lpPoolV2Balance +
            vestingBalance;
    }

    function totalSupply() external view returns (uint256) {
        return IERC20(ILV).totalSupply();
    }

    function _lpToILV(uint256 _lpBalance)
        internal
        view
        returns (uint256 ilvAmount)
    {
        address _poolToken = ICorePoolV2(LP_POOL).poolToken();

        uint256 totalLP = IERC20(_poolToken).totalSupply();
        uint256 ilvInLP = IERC20(ILV).balanceOf(_poolToken);
        ilvAmount = (ilvInLP * _lpBalance) / totalLP;
    }

    function _getStakeWeight(V2Stake memory _stake)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(
                (((_stake.lockedUntil - _stake.lockedFrom) *
                    WEIGHT_MULTIPLIER) /
                    MAX_STAKE_PERIOD +
                    BASE_WEIGHT) * _stake.value
            );
    }
}