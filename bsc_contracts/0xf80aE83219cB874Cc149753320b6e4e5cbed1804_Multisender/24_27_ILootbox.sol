// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./INftFactory.sol";

interface ILootbox {

    function open(uint256 _quantity) external;

    function recoverTokens(address _token, uint256 _amount) external;

    function recoverTokensFor(address _token, address _to, uint256 _amount) external;

    function setLimit(uint256 _limit) external;

    function resetCounter() external;

    function setToken(IERC20 _token0, IERC20 _token1) external;

    function setPrice(uint256 _price) external;

    function setFactory(INftFactory _factory) external;

    function setRouter(IUniswapV2Router02 _router) external;

    function setNftBankAdress(address _nftBankAdress) external;

    function setLotteryAddress(address _lotteryAdress) external;

    function updateLotteryRate(uint256 _lotteryRate) external;

    function setChances(uint256[] calldata _chances) external;

    function setItems(address[] calldata _items) external;

}