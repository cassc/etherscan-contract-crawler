// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import './Subwallet.sol';

/**
* @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
*/
contract Vestingable {


    /**
    * @notice Constructor since this contract is not ment to be used without inheritance
    * push once to stakeholders for it to work proplerly
     */
    constructor() {

    }
    /**
     * @notice
     * A stake struct is used to represent the way we store stakes,
     * A Stake will contain the users address, the amount staked and a timestamp,
     * Since which is when the stake was made
     */
    struct Vest {
        address user;
        uint256 amount;
        uint256 until;
        // This claimable field is new and used to tell how big of a reward is currently available
    }
    /**
    * @notice Stakeholder is a staker that has active stakes
     */
    struct Vestholder {
        address user;
        Vest[] address_vests;

    }
    /**
    * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */
    struct VestingSummary {
        uint256 total_amount;
        Vest[] vests;
    }


    /**
    * @notice
    *   This is a array where we store all Stakes that are performed on the Contract
    *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
    */
    Vestholder[] public vestholders;

    /**
    * @notice
    * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal vests;

    /**
    * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addVester(address staker) internal returns (uint256){
        // Push a empty item to the Array to make space for our new stakeholder
        vestholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = vestholders.length - 1;
        // Assign the address to the new index
        vestholders[userIndex].user = staker;
        // Add index to the stakeHolders
        vests[staker] = userIndex;
        return userIndex;
    }

    /**
    * @notice
    * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    * StakeID
    */
    function _vest(address sender, uint256 _amount, uint256 _cliffUntil ) public {
        // Simple check so that user does not stake 0
        require(_amount > 0, "Cannot stake nothing");
        require(_amount / 10 * 10 == _amount, "amount has to be dividiable by 10");


        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = vests[sender];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if (index == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addVester(sender);
        }
        for (uint i = 0; i < 10; i++) {
            uint daysCount = (i + 1) * 30 days;
            vestholders[index].address_vests.push(Vest(sender, _amount / 10, maxLocal(block.timestamp, _cliffUntil)  +  daysCount  ));
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        // Emit an event that the stake has occured
    }




    /**
    * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function sumVesting(address _vester) public view returns (uint){
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount = 0;
        // Itterate all stakes and grab amount of stakes
        if (vests[_vester] != 0) {
            VestingSummary memory summary = VestingSummary(0, vestholders[vests[_vester]].address_vests);
            for (uint256 s = 0; s < summary.vests.length; s += 1) {
                if ( block.timestamp < summary.vests[s].until) {
                    totalStakeAmount += summary.vests[s].amount;
                }
            }
        }

        return totalStakeAmount;
    }


    function maxLocal(uint256 a, uint256 b) private view returns (uint256) {
        return a >= b ? a : b;
    }
}




