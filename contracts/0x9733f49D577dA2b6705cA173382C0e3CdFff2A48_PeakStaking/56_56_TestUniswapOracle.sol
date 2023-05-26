pragma solidity 0.5.17;

contract TestUniswapOracle {
    function update() external returns (bool success) {
        return true;
    }

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        return 3 * 10**5; // 1 PEAK = 0.30 USDC
    }
}