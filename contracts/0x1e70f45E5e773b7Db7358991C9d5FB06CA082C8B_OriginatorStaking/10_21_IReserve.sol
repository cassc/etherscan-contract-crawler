// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

interface IReserve {
    event Transfer(address indexed to, uint256 amount);
    event RescueFunds(address token, address indexed to, uint256 amount);

    function balance() external view returns (uint256);

    function transfer(address payable _to, uint256 _value) external returns (bool);

    function rescueFunds(
        address _tokenToRescue,
        address _to,
        uint256 _amount
    ) external;
}