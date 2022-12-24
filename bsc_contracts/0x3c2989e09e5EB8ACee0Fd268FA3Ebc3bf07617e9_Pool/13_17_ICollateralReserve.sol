// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ICollateralReserve {
    function fundBalance(address _token) external view returns (uint256);

    function transferTo(address _token, address _receiver, uint256 _amount) external;

    function burnToken(address _token, uint256 _amount) external;

    function receiveCollaterals(uint256 _mainCollateralAmount, uint256 _secondCollateralAmount) external;
}