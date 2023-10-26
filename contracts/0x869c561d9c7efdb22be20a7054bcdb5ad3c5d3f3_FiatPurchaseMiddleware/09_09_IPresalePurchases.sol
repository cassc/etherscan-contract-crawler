// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPresalePurchases {
    function buyWithUSD(uint256 _amount, uint256 _referrerId) external;

    function getPrice(uint256 _amount) external view returns (uint256 priceInETH, uint256 priceInUSDT);

    function claim() external;

    function purchasedTokens(address _user) external view returns(uint256);

    function saleToken() external view returns(address);
}