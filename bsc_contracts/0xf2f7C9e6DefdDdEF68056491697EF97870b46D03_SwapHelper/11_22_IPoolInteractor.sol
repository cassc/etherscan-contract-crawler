// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/SaferERC20.sol";
import "hardhat/console.sol";

interface IPoolInteractor {
    event Burn(address lpTokenAddress, uint256 amount);

    function burn(
        address lpTokenAddress,
        uint256 amount,
        address self
    ) external payable returns (address[] memory, uint256[] memory);

    function mint(
        address toMint,
        address[] memory underlyingTokens,
        uint256[] memory underlyingAmounts,
        address receiver,
        address self
    ) external payable returns (uint256);

    function simulateMint(
        address toMint,
        address[] memory underlyingTokens,
        uint[] memory underlyingAmounts
    ) external view returns (uint);

    function testSupported(address lpToken) external view returns (bool);

    function getUnderlyingAmount(
        address lpTokenAddress,
        uint amount
    ) external view returns (address[] memory underlying, uint[] memory amounts);

    function getUnderlyingTokens(address poolAddress) external view returns (address[] memory, uint[] memory);
}