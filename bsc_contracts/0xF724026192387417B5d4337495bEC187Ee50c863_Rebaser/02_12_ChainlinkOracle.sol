pragma solidity ^0.5.16;

import "./openzeppelin/SafeMath.sol";
import "./interfaces/AggregatorV3Interface.sol";

contract ChainlinkOracle {

  using SafeMath for uint256;

  address public oracle; // Address on polyscan 0x187c42f6C0e7395AeA00B1B30CB0fF807ef86d5d;
  constructor (address _oracle) public {
    oracle = _oracle;
  }

  function getPriceSNP() public view returns (bool, uint256) {
    // answer has 8 decimals, it is the price of SPY.US which is 1/10th of SNP500
    // if the round is not completed, updated at is 0
    (,int256 answer,,uint256 updatedAt,) = AggregatorV3Interface(oracle).latestRoundData();
    // add 10 decimals at the end
    return (updatedAt != 0, uint256(answer).mul(1e10));
  }
}