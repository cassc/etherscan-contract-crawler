pragma solidity ^0.8.7;

interface IAddLiquidityContract {
    function addLiquidity(
        uint256 _amountADesired,
        uint256 _amountBDesired,
        address _to,
        uint256 _deadline
    ) external;
}