// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IBondCalculator.sol";

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function tokenPerformanceUpdate() external;

    function baseSupply() external view returns (uint256);

    function deltaTokenPrice() external view returns (int256);

    function deltaTreasuryYield() external view returns (int256);

    function getTheoBondingCalculator() external view returns (IBondCalculator);

    function setTheoBondingCalculator(address _theoBondingCalculator) external;
}