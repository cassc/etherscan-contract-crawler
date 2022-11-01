// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDogsExchangeHelper {
    function addDogsBNBLiquidity(uint256 nativeAmount) external payable returns (uint256 lpAmount, uint256 unusedEth, uint256 unusedToken);
    function addDogsLiquidity(address baseTokenAddress, uint256 baseAmount, uint256 dogsAmount) external returns (uint256 lpAmount, uint256 unusedEth, uint256 unusedToken);
    function buyDogsBNB(uint256 _minAmountOut, address[] memory _path) external payable returns(uint256 amountDogsBought);
    function buyDogs(uint256 _tokenAmount, uint256 _minAmountOut, address[] memory _path) external returns(uint256 amountDogsBought);
}