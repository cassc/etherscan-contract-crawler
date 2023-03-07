/*
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.18;

import "../openzeppelin/utils/ContextUpgradeable.sol";
import "../openzeppelin/proxy/utils/Initializable.sol";

contract Stakable is Initializable, ContextUpgradeable {
    struct Stake {
        uint256 amountLBSKR;
        uint256 amountBSKR;
        uint256 sharesLBSKR;
        uint256 sharesBSKR;
        uint256 since;
    }

    struct Stakeholder {
        address user;
        Stake[] userStakes;
    }

    Stakeholder[] public stakeholders;
    mapping(address => uint256) internal _stakeIndexMap;
    uint256 public totalBSKRShares;
    uint256 public totalBSKRStakes;
    uint256 public totalLBSKRShares;
    uint256 public totalLBSKRStakes;

    /**
     * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
    event Staked(
        address indexed user,
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR,
        uint256 stakeIndex,
        uint256 since
    );

    /**
     * @notice Unstaked event is triggered whenever a user unstakes tokens, address is indexed to make it filterable
     */
    event Unstaked(
        address indexed user,
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR,
        uint256 since,
        uint256 till
    );

    function __Stakable_init() internal onlyInitializing {
        __Stakable_init_unchained();
    }

    function __Stakable_init_unchained() internal onlyInitializing {
        // This push is needed so we avoid index 0 causing bug of index-1

        if (stakeholders.length == 0) {
            stakeholders.push();
        }
    }

    /**
     * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 stakerIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[stakerIndex].user = staker;
        // Add index to the stakeholders
        _stakeIndexMap[staker] = stakerIndex;
        return stakerIndex;
    }

    function _getCurrStake(uint256 stakerIndex, uint256 stakeIndex)
        internal
        view
        returns (Stake memory currStake)
    {
        require(
            stakeIndex < stakeholders[stakerIndex].userStakes.length,
            "S: Stake index incorrect!"
        );
        require(
            stakeholders[stakerIndex].user == _msgSender(),
            "S: Not your stake!"
        );

        currStake = stakeholders[stakerIndex].userStakes[stakeIndex];

        return currStake;
    }

    function _stake(
        uint256 amountLBSKR,
        uint256 amountBSKR,
        uint256 sharesLBSKR,
        uint256 sharesBSKR
    ) internal {
        // Simple check so that user does not stake 0
        require(amountLBSKR != 0, "S: Cannot stake nothing");

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 stakerIndex = _stakeIndexMap[_msgSender()];
        uint256 since = block.timestamp;

        // See if the staker already has a staked index or if its the first time
        if (stakerIndex == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the stakeholders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            stakerIndex = _addStakeholder(_msgSender());
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[stakerIndex].userStakes.push(
            Stake(amountLBSKR, amountBSKR, sharesLBSKR, sharesBSKR, since)
        );

        totalLBSKRStakes += amountLBSKR;
        totalBSKRStakes += amountBSKR;
        totalLBSKRShares += sharesLBSKR;
        totalBSKRShares += sharesBSKR;

        // Emit an event that the stake has occured
        emit Staked(
            _msgSender(),
            amountLBSKR,
            amountBSKR,
            sharesLBSKR,
            sharesBSKR,
            stakeholders[stakerIndex].userStakes.length - 1,
            since
        );
    }

    function _withdrawStake(uint256 stakeIndex, uint256 unstakeAmount)
        internal
        returns (
            Stake memory currStake,
            uint256 lbskrShares2Deduct,
            uint256 bskrShares2Deduct,
            uint256 bskrAmount2Deduct
        )
    {
        uint256 stakerIndex = _stakeIndexMap[_msgSender()];
        currStake = _getCurrStake(stakerIndex, stakeIndex);

        require(
            stakerIndex != 1 || stakeIndex != 0,
            "S: Cannot remove the first stake"
        );

        require(
            currStake.amountLBSKR >= unstakeAmount,
            "S: Cannot withdraw more than you have staked"
        );

        // Remove by subtracting the money unstaked
        // Same fraction of shares to be deducted from both BSKR and LBSKR
        lbskrShares2Deduct =
            (unstakeAmount * currStake.sharesLBSKR) /
            currStake.amountLBSKR;
        bskrAmount2Deduct =
            (unstakeAmount * currStake.amountBSKR) /
            currStake.amountLBSKR;
        bskrShares2Deduct =
            (unstakeAmount * currStake.sharesBSKR) /
            currStake.amountLBSKR;

        if (currStake.amountLBSKR == unstakeAmount) {
            if (stakeIndex < stakeholders[stakerIndex].userStakes.length - 1) {
                stakeholders[stakerIndex].userStakes[stakeIndex] = stakeholders[
                    stakerIndex
                ].userStakes[stakeholders[stakerIndex].userStakes.length - 1];
            }
            stakeholders[stakerIndex].userStakes.pop();

            if (stakeholders[stakerIndex].userStakes.length == 0) {
                stakeholders[stakerIndex] = stakeholders[
                    stakeholders.length - 1
                ];
                stakeholders.pop();

                _stakeIndexMap[_msgSender()] = 0;
                _stakeIndexMap[stakeholders[stakerIndex].user] = stakerIndex;
            }
        } else {
            Stake storage updatedStake = stakeholders[stakerIndex].userStakes[
                stakeIndex
            ];
            updatedStake.amountLBSKR -= unstakeAmount;
            updatedStake.amountBSKR -= bskrAmount2Deduct;
            updatedStake.sharesLBSKR -= lbskrShares2Deduct;
            updatedStake.sharesBSKR -= bskrShares2Deduct;
        }

        return (
            currStake,
            lbskrShares2Deduct,
            bskrShares2Deduct,
            bskrAmount2Deduct
        );
    }

    /**
     * @notice Returns the total number of stake holders
     */
    function getTotalStakeholders() external view returns (uint256) {
        return stakeholders.length - 1;
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return __totalStakes The aggregated stakes from all stakeholders.
     */
    function getTotalStakes() external view returns (uint256 __totalStakes) {
        // uint256 __totalStakes;
        for (
            uint256 stakerIndex;
            stakerIndex < stakeholders.length;
            ++stakerIndex
        ) {
            __totalStakes =
                __totalStakes +
                stakeholders[stakerIndex].userStakes.length;
        }

        return __totalStakes;
    }

    /**
     * @notice Returns the stakes of a stakeholder
     */
    function stakesOf(address stakeholder)
        external
        view
        returns (Stake[] memory userStakes)
    {
        uint256 stakerIndex = _stakeIndexMap[stakeholder];
        if (stakerIndex > 0) {
            return stakeholders[stakerIndex].userStakes;
        }

        return userStakes;
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}