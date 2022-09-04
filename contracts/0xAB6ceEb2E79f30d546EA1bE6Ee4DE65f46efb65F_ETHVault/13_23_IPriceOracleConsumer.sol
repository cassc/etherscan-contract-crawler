// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPriceOracleConsumer {

    function decimals() external view returns(uint8);

    function stEthPriceInEth() external view returns(uint);
    function wstEthPriceInEth() external view returns(uint);
    function rEthPriceInEth() external view returns(uint);
    function wEthPriceInEth() external view returns(uint);
    function sEthPriceInEth() external view returns(uint);
    function sEth2PriceInEth() external view returns(uint);
    function rEth2PriceInEth() external view returns (uint);

    function ethPriceInUsd() external view returns(uint);
    function stEthPriceInUsd() external view returns(uint);
    function wstEthPriceInUsd() external view returns(uint);
    function rEthPriceInUsd() external view returns(uint);
    function wEthPriceInUsd() external view returns(uint);
    function sEth2PriceInUsd() external view returns(uint);
    function rEth2PriceInUsd() external view returns (uint);

    function priceInEth(address _asset) external view returns(uint);
    function priceInUSD(address _asset) external view returns(uint);

    function valueInEth(address _asset,uint _amount) external view returns(uint);
    function valueInUsd(address _asset,uint _amount) external view returns(uint);

    function valueInTargetToken(address _fromToken, uint256 _amount, address _toToken) external view returns(uint256);

}