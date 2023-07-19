// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface ICentaurRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function onlyEOAEnabled() external pure returns (bool);
    function whitelistContracts(address _address) external view returns (bool);

    function addLiquidity(
        address _baseToken,
        uint _amount,
        address _to,
        uint _minLiquidity,
        uint _deadline
    ) external returns (uint amount, uint liquidity);
    function addLiquidityETH(
        address _to,
        uint _minLiquidity,
        uint _deadline
    ) external payable returns (uint amount, uint liquidity);
    function removeLiquidity(
        address _baseToken,
        uint _liquidity,
        address _to,
        uint _minAmount,
        uint _deadline
    ) external returns (uint amount);
    function removeLiquidityETH(
        uint _liquidity,
        address _to,
        uint _minAmount,
        uint _deadline
    ) external returns (uint amount);
    function swapExactTokensForTokens(
        address _fromToken,
        uint _amountIn,
        address _toToken,
        uint _amountOutMin,
        address to,
        uint _deadline
    ) external;
    function swapExactETHForTokens(
        address _toToken,
        uint _amountOutMin,
        address to,
        uint _deadline
    ) external payable;
    function swapTokensForExactTokens(
        address _fromToken,
        uint _amountInMax,
        address _toToken,
        uint _amountOut,
        address _to,
        uint _deadline
    ) external;
    function swapETHForExactTokens(
        address _toToken,
        uint _amountOut,
        address _to,
        uint _deadline
    ) external payable;

    function swapSettle(address _sender, address _pool) external returns (uint amount, address receiver);
    function swapSettleMultiple(address _sender, address[] memory _pools) external;

    function validatePools(address _fromToken, address _toToken) external view returns (address inputTokenPool, address outputTokenPool);
    function getAmountOut(address _fromToken, address _toToken, uint _amountIn) external view returns (uint amountOut);
    function getAmountIn(address _fromToken, address _toToken, uint _amountOut) external view returns (uint amountIn);

    function setFactory(address) external;
    function setOnlyEOAEnabled(bool) external;
    function addContractToWhitelist(address) external;
    function removeContractFromWhitelist(address) external;

}