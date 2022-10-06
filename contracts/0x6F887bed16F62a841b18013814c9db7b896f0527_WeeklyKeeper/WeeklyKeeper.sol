/**
 *Submitted for verification at Etherscan.io on 2022-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}






interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}


interface IMinter {
  function active_period() external view returns (uint);
  function update_period() external returns (uint);
}

contract WeeklyKeeper is KeeperCompatibleInterface {
    IMinter public minter;

    constructor(address _minter) public {
      minter = IMinter(_minter);
    }

    function checkUpkeep(bytes calldata)
      external
      override
      returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = computeAction();
    }

    function computeAction() public view returns(bool){
      if(block.timestamp >= minter.active_period() + 7 days){
        return true;
      }else {
        return false;
      }
    }

    function performUpkeep(bytes calldata) external override {
      minter.update_period();
    }
}