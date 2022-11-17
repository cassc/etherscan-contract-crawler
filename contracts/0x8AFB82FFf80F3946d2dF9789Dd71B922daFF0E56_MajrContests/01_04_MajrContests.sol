// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MajrContests is Ownable {
  /// @notice OpenZeppelin libraries
  using Counters for Counters.Counter;

  /// @notice Tracks the ID of the next contest data to be added
  Counters.Counter public contestCount;

  /// @notice The struct that holds the contest data
  struct ContestData {
    uint256 id;
    string contestDataURI;
    string contestRulesURI;
    uint256 timestamp;
  }

  /// @notice Mapping from the contest id to the contest data
  mapping(uint256 => ContestData) public contests;

  /// @notice An array containing all the contest data ever added
  ContestData[] public allContests;

  /// @notice An event emitted when the data for the new contest is added
  event ContestAdded(uint256 id, string contestDataURI, string contestRulesURI, uint256 timestamp);

  /**
   * @notice Posts the contest data for the most recent MAJR contest to the blockchain
   * @param _contestDataURI string calldata (the URI of the contest data, which is stored on the IPFS)
   * @param _contestRulesURI string calldata (the URI of the contest rules, which is stored on the IPFS)
   * @dev Only owner can call it
   */
  function postContestData(string calldata _contestDataURI, string calldata _contestRulesURI) external onlyOwner {
    uint256 currentContestCount = contestCount.current();

    ContestData memory contest = ContestData({
      id: currentContestCount,
      contestDataURI: _contestDataURI,
      contestRulesURI: _contestRulesURI,
      timestamp: block.timestamp
    });

    contests[currentContestCount] = contest;

    allContests.push(contest);

    contestCount.increment();

    emit ContestAdded(currentContestCount, _contestDataURI, _contestRulesURI, block.timestamp);
  }

  /**
   * @notice Returns the contest data with the given contest id
   * @param _id address
   * @return Contest memory
   */
  function getContestData(uint256 _id) external view returns (ContestData memory) {
    require(contestCount.current() > _id, "MajrContests: ContestData id is out of bounds.");

    return contests[_id];
  }

  /**
   * @notice Returns an array of all contest data ever added
   * @return Contest[] memory
   */
  function getAllContestData() external view returns (ContestData[] memory) {
    return allContests;
  }
}