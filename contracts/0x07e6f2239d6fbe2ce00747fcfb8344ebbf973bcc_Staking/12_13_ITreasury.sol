//SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token
    ) external;

    function depositEther() external payable;

    function withdraw(
        uint256 _amount,
        address _token
    ) external;

    function withdrawTo(
        uint256 _amount,
        address _token,
        address _to
    ) external;

    function withdrawEther(
        uint256 _amount
    ) external;
}