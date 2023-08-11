// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;

interface IHarvestDeposit {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;

    function getPricePerFullShare() external view returns (uint256);

    function underlying() external view returns (address);

    function decimals() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function balanceOf(address account) external view returns (uint256);
}