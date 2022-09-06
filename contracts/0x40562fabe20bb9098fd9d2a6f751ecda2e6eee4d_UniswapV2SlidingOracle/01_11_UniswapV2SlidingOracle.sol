pragma solidity =0.6.6;

import "../lib/v2-periphery/contracts/examples/ExampleSlidingWindowOracle.sol";
import "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract UniswapV2SlidingOracle is ExampleSlidingWindowOracle {
    constructor(IUniswapV2Factory uniswapFactory)
        public
        ExampleSlidingWindowOracle(address(uniswapFactory), 6 hours, 6)
    {}
}