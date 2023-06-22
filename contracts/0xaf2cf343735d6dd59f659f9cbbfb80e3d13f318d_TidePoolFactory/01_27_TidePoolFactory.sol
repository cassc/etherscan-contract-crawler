//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;
pragma abicoder v2;

import "./TidePool.sol";
import "./libraries/FactoryValidator.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract TidePoolFactory {
    address public immutable uniswapFactory;
    address public immutable treasury;

    event TidePoolCreated(address indexed tidePool);

    // input a UniswapV3 pool, return a TidePool
    mapping(address => address) public getTidePool;
    // array of tidePools to avoid a Subgraph
    address[] public tidePools;

    constructor(address _factory, address _treasury) {
        treasury = _treasury;
        uniswapFactory = _factory;
    }

    function deploy(address _pool) external returns (address validatedPool) {
        validatedPool = FactoryValidator.validate(uniswapFactory, _pool, getTidePool[_pool]);
        address tp = address(new TidePool(IUniswapV3Pool(validatedPool), treasury));
        getTidePool[validatedPool] = tp;
        tidePools.push(tp);
        emit TidePoolCreated(tp);
    }
}