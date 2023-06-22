//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

library FactoryValidator {
    function validate(address _uniswapFactory, address _pool, address _tidePool) public view returns (address validatedPool) {
        require(_tidePool == address(0),"AE");

        IUniswapV3Pool pool = IUniswapV3Pool(_pool); 
        validatedPool = IUniswapV3Factory(_uniswapFactory).getPool(pool.token0(), pool.token1(), pool.fee());
        require(validatedPool != address(0),"NP");
    }
}