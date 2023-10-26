// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IAavePool {
    function aave() external view returns (address);
    function convertEthTo(uint256 _amount,address _token,uint256 _decimals) external view returns (uint256);
    function convertToEth(uint256 _amount,address _token,uint256 _decimals) external view returns (uint256);
    function getCollateral(address _user) external view returns (uint256);
    function getDebt(address _user) external view returns (uint256);
    function getCollateralAndDebt(address _user)external view returns (uint256 _collateral, uint256 _debt);
    function getCollateralTo(address _user,address _token,uint256 _decimals) external view returns (uint256);

    function getDebtTo(address _user,address _token,uint256 _decimals) external view returns (uint256);
    function getCollateralAndDebtTo(address _user,address _token,uint256 _decimals)external view returns (uint256 _collateral, uint256 _debt);

}