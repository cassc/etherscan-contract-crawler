/**
 *Submitted for verification at Etherscan.io on 2023-05-10
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
// File: @chainlink/contracts/src/v0.8/ChainlinkClient.sol

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
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
// File: chain.sol

pragma solidity ^0.8.0;

contract memeBettingMarket {
    address public admin;
    struct Coin {
        uint256 predictionEndTime;
        uint256 targetPrice;
        uint256 currentPrice;
        mapping(address => uint256) betsHigher;
        mapping(address => uint256) betsLower;
    }

    mapping(address => Coin) public coins;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setupNewPrediction(
        address coinAddress, 
        uint256 _predictionEndTime,
        uint256 _targetPrice,
        uint256 _initialPrice
    )
        external 
        onlyAdmin
    {
        Coin storage coin = coins[coinAddress];
        coin.predictionEndTime = _predictionEndTime;
        coin.targetPrice = _targetPrice;
        coin.currentPrice = _initialPrice;
    }

   
}