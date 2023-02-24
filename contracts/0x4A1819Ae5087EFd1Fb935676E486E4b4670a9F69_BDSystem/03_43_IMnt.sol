// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ILinkageLeaf.sol";

interface IMnt is IERC20Upgradeable, IERC165, IAccessControlUpgradeable, ILinkageLeaf {
    event MaxNonVotingPeriodChanged(uint256 oldPeriod, uint256 newPeriod);
    event NewGovernor(address governor);
    event VotesUpdated(address account, uint256 oldVotingWeight, uint256 newVotingWeight);
    event TotalVotesUpdated(uint256 oldTotalVotes, uint256 newTotalVotes);

    /**
     * @notice get governor
     */
    function governor() external view returns (address);

    /**
     * @notice returns votingWeight for user
     */
    function votingWeight(address) external view returns (uint256);

    /**
     * @notice get total voting weight
     */
    function totalVotingWeight() external view returns (uint256);

    /**
     * @notice Updates voting power of the account
     */
    function updateVotingWeight(address account) external;

    /**
     * @notice Creates new total voting weight checkpoint
     * @dev RESTRICTION: Governor only.
     */
    function updateTotalWeightCheckpoint() external;

    /**
     * @notice Checks user activity for the last `maxNonVotingPeriod` blocks
     * @param account_ The address of the account
     * @return returns true if the user voted or his delegatee voted for the last maxNonVotingPeriod blocks,
     * otherwise returns false
     */
    function isParticipantActive(address account_) external view returns (bool);

    /**
     * @notice Updates last voting timestamp of the account
     * @dev RESTRICTION: Governor only.
     */
    function updateVoteTimestamp(address account) external;

    /**
     * @notice Gets the latest voting timestamp for account.
     * @dev If the user delegated his votes, then it also checks the timestamp of the last vote of the delegatee
     * @param account The address of the account
     * @return latest voting timestamp for account
     */
    function lastActivityTimestamp(address account) external view returns (uint256);

    /**
     * @notice set new governor
     * @dev RESTRICTION: Admin only.
     */
    function setGovernor(address newGovernor) external;

    /**
     * @notice Sets the maxNonVotingPeriod
     * @dev Admin function to set maxNonVotingPeriod
     * @param newPeriod_ The new maxNonVotingPeriod (in sec). Must be greater than 90 days and lower than 2 years.
     * @dev RESTRICTION: Admin only.
     */
    function setMaxNonVotingPeriod(uint256 newPeriod_) external;
}