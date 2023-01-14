// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./FlexvisERC20.sol";

contract Flexvis is FlexvisERC20("Flexvis", "FLX") {
    uint256 public constant DEVELOPMENT = 1_000_000E18;
    uint256 public constant MARKETING = 850_000E18;
    uint256 public constant TREASURY = 900_000E18;
    uint256 public constant RESERVE_FUND = 1_250_000E18;
    uint256 public constant PRIVATE_SALE = 1_000_000E18;
    uint256 public constant PUBLIC_SALE = 400_000E18;
    uint256 public constant LIQUIDITY = 600_000E18;
    uint256 public constant INVESTMENT_REWARDS = 1_500_000E18;
    uint256 public constant UTILITY_REWARDING_SYSTEM = 2_500_000E18;

    constructor(
        address _development,
        address _marketing,
        address _treasury,
        address _reserve_fund,
        address _private_sale,
        address _public_sale,
        address _liquidity,
        address investment_reward,
        address utility_rewarding_system
    ) {
        _mint(_development, DEVELOPMENT);
        _mint(_treasury, TREASURY);
        _mint(_marketing, MARKETING);
        _mint(_reserve_fund, RESERVE_FUND);
        _mint(_private_sale, PRIVATE_SALE);
        _mint(_public_sale, PUBLIC_SALE);
        _mint(_liquidity, LIQUIDITY);
        _mint(investment_reward, INVESTMENT_REWARDS);
        _mint(utility_rewarding_system, UTILITY_REWARDING_SYSTEM);
    }

 
}