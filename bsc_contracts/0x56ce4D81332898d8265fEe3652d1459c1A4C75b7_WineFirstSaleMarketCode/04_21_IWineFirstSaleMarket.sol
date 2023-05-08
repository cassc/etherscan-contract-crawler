// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineFirstSaleMarket {

    function initialize(
        address manager_,
        address firstSaleCurrency_
    ) external;

    function firstSaleCurrency() external view returns(address);

//////////////////////////////////////// Treasury

    event NewFirstSaleCurrency(address indexed firstSaleCurrency);

    function _editFirstSaleCurrency(address firstSaleCurrency_) external;

    function _treasuryGetBalance(address currency) external view returns (uint256);

    function _withdrawFromTreasury(address currency, uint256 amount, address to) external;

//////////////////////////////////////// Token

    function buyToken(uint256[] memory poolId, address newTokenOwner) external;

}