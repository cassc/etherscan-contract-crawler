pragma solidity ^0.5.16;

import "./BasicRebaser.sol";
import "./ChainlinkOracle.sol";
import "./UniswapOracle.sol";

contract Rebaser is BasicRebaser, UniswapOracle, ChainlinkOracle {

  constructor (address router, address usdc, address wNative, address token, address _treasury, address oracle, address _taxManager)
  BasicRebaser(token, _treasury, _taxManager)
  ChainlinkOracle(oracle)
  UniswapOracle(router, usdc, wNative, token) public {
  }

}