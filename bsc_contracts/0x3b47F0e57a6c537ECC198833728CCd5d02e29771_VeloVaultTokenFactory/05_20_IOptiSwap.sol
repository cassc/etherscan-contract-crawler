// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IOptiSwap {
    function weth() external view returns (address);

    function bridgeFromTokens(uint256 index) external view returns (address token);

    function bridgeFromTokensLength() external view returns (uint256);

    function getBridgeToken(address _token) external view returns (address bridgeToken);

    function addBridgeToken(address _token, address _bridgeToken) external;

    function getDexInfo(uint256 index) external view returns (address dex, address handler);

    function dexListLength() external view returns (uint256);

    function indexOfDex(address _dex) external view returns (uint256);

    function getDexEnabled(address _dex) external view returns (bool);

    function addDex(address _dex, address _handler) external;

    function removeDex(address _dex) external;

    function getBestAmountOut(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (address pair, uint256 amountOut);
}