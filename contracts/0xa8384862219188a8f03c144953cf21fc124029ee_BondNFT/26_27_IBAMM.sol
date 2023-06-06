// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;


interface IBAMM {
    function deposit(uint256 lusdAmount) external;

    function withdraw(uint256 lusdAmount, address to) external;

    function swap(uint lusdAmount, uint minEthReturn, address payable dest) external returns(uint);

    function getSwapEthAmount(uint lusdQty) external view returns(uint ethAmount, uint feeLusdAmount);

    function getLUSDValue() external view returns (uint256, uint256, uint256);

    function setChicken(address _chicken) external;
}