pragma solidity 0.5.17;

// interface for contract_v6/UniswapOracle.sol
interface IUniswapOracle {
    function update() external returns (bool success);

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}