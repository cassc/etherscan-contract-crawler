// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";
import "./interfaces/IRewardsDistribution.sol";

// Internal references
import "./interfaces/IERC20.sol";

// Original contract can be found under the following link:
// https://github.com/Synthetixio/synthetix/blob/master/contracts/RewardsDistribution.sol
contract RewardsDistribution is Owned, IRewardsDistribution {
    /**
     * @notice Authorised address able to call distributeRewards
     */
    address public authority;

    /**
     * @notice Address of the rewards token
     */
    address public rewardsToken;

    /**
     * @notice An array of addresses and amounts to send
     */
    DistributionData[] public distributions;

    /**
     * @dev _authority maybe the rewards distribution operator
     */
    constructor(
        address _owner,
        address _authority,
        address _rewardsToken
    ) Owned(_owner) {
        authority = _authority;
        rewardsToken = _rewardsToken;
    }

    // ========== EXTERNAL SETTERS ==========

    function setRewardToken(address _rewardsToken) external onlyOwner {
        rewardsToken = _rewardsToken;
    }

    /**
     * @notice Set the address of the contract authorised to call distributeRewards()
     * @param _authority Address of the authorised calling contract.
     */
    function setAuthority(address _authority) external onlyOwner {
        authority = _authority;
    }

    // ========== EXTERNAL FUNCTIONS ==========

    /**
     * @notice Adds a Rewards DistributionData struct to the distributions
     * array. Any entries here will be iterated and rewards distributed to
     * each address when tokens are sent to this contract and distributeRewards()
     * is called by the autority.
     * @param destination An address to send rewards tokens too
     * @param amount The amount of rewards tokens to send
     */
    function addRewardDistribution(address destination, uint amount) external onlyOwner returns (bool) {
        require(destination != address(0), "Cant add a zero address");
        require(amount != 0, "Cant add a zero amount");

        DistributionData memory rewardsDistribution = DistributionData(destination, amount);
        distributions.push(rewardsDistribution);

        emit RewardDistributionAdded(distributions.length - 1, destination, amount);
        return true;
    }

    /**
     * @notice Deletes a RewardDistribution from the distributions
     * so it will no longer be included in the call to distributeRewards()
     * @param index The index of the DistributionData to delete
     */
    function removeRewardDistribution(uint index) external onlyOwner {
        require(index <= distributions.length - 1, "index out of bounds");

        // shift distributions indexes across
        for (uint i = index; i < distributions.length - 1; i++) {
            distributions[i] = distributions[i + 1];
        }
        distributions.pop();

        // Since this function must shift all later entries down to fill the
        // gap from the one it removed, it could in principle consume an
        // unbounded amount of gas. However, the number of entries will
        // presumably always be very low.
    }

    /**
     * @notice Edits a RewardDistribution in the distributions array.
     * @param index The index of the DistributionData to edit
     * @param destination The destination address. Send the same address to keep or different address to change it.
     * @param amount The amount of tokens to edit. Send the same number to keep or change the amount of tokens to send.
     */
    function editRewardDistribution(
        uint index,
        address destination,
        uint amount
    ) external onlyOwner returns (bool) {
        require(index <= distributions.length - 1, "index out of bounds");

        distributions[index].destination = destination;
        distributions[index].amount = amount;

        return true;
    }

    function distributeRewards() external override returns (bool) {
        require(msg.sender == authority, "Caller is not authorised");
        require(rewardsToken != address(0), "RewardsToken is not set");

        uint amount = 0;

        // Iterate the array of distributions sending the configured amounts
        for (uint i = 0; i < distributions.length; i++) {
            if (distributions[i].destination != address(0) && distributions[i].amount != 0) {
                amount += distributions[i].amount;
                
                // Transfer the rewards token
                IERC20(rewardsToken).transfer(distributions[i].destination, distributions[i].amount);

                // Inform staking contract how much rewards tokens is received
                bytes memory payload = abi.encodeWithSignature("notifyRewardAmount(uint256)", distributions[i].amount);

                // solhint-disable avoid-low-level-calls
                (bool success, ) = distributions[i].destination.call(payload);

                require(success, "Rewards distribution unsuccessful");
            }
        }

        require(amount > 0, "Nothing to distribute");

        emit RewardsDistributed(amount);
        return true;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Retrieve the length of the distributions array
     */
    function distributionsLength() external view override returns (uint) {
        return distributions.length;
    }

    /* ========== Events ========== */

    event RewardDistributionAdded(uint index, address destination, uint amount);
    event RewardsDistributed(uint amount);
}