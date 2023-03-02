// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IUniswapV2Router01.sol";

// beats library
abstract contract IContractsLibrary {

    function BUSD() external view virtual returns (address);

    function WBNB() external view virtual returns (address);

    function ROUTER() external view virtual returns (IUniswapV2Router01);
    
    function getBusdToBNBToToken(address token, uint _amount) external view virtual returns(uint256);

}