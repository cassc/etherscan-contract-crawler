// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ITOSValueCalculator {

    /// @dev                     initializes addresses
    /// @param _tos              address of TOS
    /// @param _weth             address of WETH
    /// @param _npm              address of NonFungibleManager of UniswapV3
    /// @param _basicpool        address of WETH-TOS pool
    /// @param _uniswapV3factory address of UniswapV3Factory
    function initialize(
        address _tos,
        address _weth,
        address _npm,
        address _basicpool,
        address _uniswapV3factory
    ) external;

    /// @dev           gets the TOS price from the WETH-TOS pool
    /// @return price  returns price of TOS per 1 WETH
    function getWETHPoolTOSPrice() external view returns (uint256 price);

    /// @dev                  returns information about TOS-token0 pool using token0 address 
    /// @param _erc20Addresss pool address
    /// @param _fee           fee of pool
    /// @return uint          returns 0 if token0 is TOS, returns 1 if token1 is TOS, returns 2 if the pool does not exist, returns 3 if it is not a TOS pool
    function getTOStoken0(address _erc20Addresss, uint24 _fee) external view returns (uint);

    /// @dev                returns information about TOS-token pool using pool address
    /// @param _poolAddress pool address
    /// @return uint        returns 0 if token0 is TOS, returns 1 if token1 is TOS, returns 3 if it is not a TOS pool
    function getTOStoken(address _poolAddress) external view returns (uint);

    /// @dev               returns the pool price of token0
    /// @param poolAddress pool address
    /// @return priceX96   returns token0's price of pool
    function getPriceToken0(address poolAddress) external view returns (uint256 priceX96);

    /// @dev               returns the pool price of token1
    /// @param poolAddress pool address
    /// @return priceX96   returns token1's price of pool
    function getPriceToken1(address poolAddress) external view returns(uint256 priceX96);

    /// @dev          returns the price of TOS per ETH
    /// @return price returns TOS price per 1 ETH
    function getTOSPricePerETH() external view returns (uint256 price);

    /// @dev          returns the price of ETH per TOS
    /// @return price returns ETH price per 1 TOS token
    function getETHPricePerTOS() external view returns (uint256 price);

    /// @dev          returns the price of TOS per _asset
    /// @param _asset _asset's token address
    /// @return price returns TOS price per 1 _asset token
    function getTOSPricePerAsset(address _asset) external view returns (uint256 price);

    /// @dev          returns the price of _asset per TOS
    /// @param _asset _asset's token address
    /// @return price returns _asset price per 1 TOS
    function getAssetPricePerTOS(address _asset) external view returns (uint256 price);

    /// @dev
    /// @param tokenA  first token used to create the pool
    /// @param tokenB  second token used to create the pool
    /// @param _fee    fee used to create the pool
    /// @return isWeth true if WETH pool
    /// @return isTos  true if it is a TOS pool
    /// @return pool   pool address
    /// @return token0 address of token0
    /// @return token1 address of token1
    function existPool(address tokenA, address tokenB, uint24 _fee)
        external view returns (bool isWeth, bool isTos, address pool, address token0, address token1);

    /// @dev           used to compute the pool address of token0 and token1
    /// @param tokenA  first token used to create the pool
    /// @param tokenB  second token used to create the pool
    /// @param _fee    fee used to create the pool
    /// @return pool   pool address
    /// @return token0 address of token0
    /// @return token1 address of token1
    function computePoolAddress(address tokenA, address tokenB, uint24 _fee)
        external view returns (address pool, address token0, address token1);

    /// @dev                            used to calculate the price of the asset in in ETH or TOS
    /// @param _asset                   _asset's token address
    /// @param _amount                  amount of token
    /// @return  existedWethPool        true is assigned when an Ether-specific token pool exists, which will indicate the amount in Ether basis
    /// @return  existedTosPool         true is assigned when an TOS-specific token pool exists, which will indicate the amount in TOS basis
    /// @return  priceWethOrTosPerAsset ETH price per token or TOS price per token
    /// @return  convertedAmount        amount of ether or TOS
    function convertAssetBalanceToWethOrTos(address _asset, uint256 _amount)
        external view
        returns (bool existedWethPool, bool existedTosPool,  uint256 priceWethOrTosPerAsset, uint256 convertedAmount);

}