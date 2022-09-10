// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestOracle is Ownable  {
    
    //solhint-disable-next-line no-empty-blocks
    constructor() public Ownable() { }

    uint80 public _roundId = 92233720368547768165;
    int256 public  _answer = 344698605527;
    uint256 public  _startedAt = 1631220008;
    uint256 public  _updatedAt = 1631220008;
    uint80 public  _answeredInRound = 92233720368547768165;

    function setLatestRoundData(uint80 roundId, 
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound) external onlyOwner {
          _roundId = roundId;
          _answer = answer;
          _startedAt = startedAt;
          _updatedAt = updatedAt;
          _answeredInRound = answeredInRound;
      }

    function latestRoundData()
        public
        view
    returns (
      uint80 roundId, 
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (_roundId, _answer, _startedAt, _updatedAt, _answeredInRound);
  }
}