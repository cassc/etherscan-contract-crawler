// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IERC20 {
    event Approval(address indexed _src, address indexed _dst, uint256 _amount);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _whom) external view returns (uint256);

    function allowance(address _src, address _dst)
        external
        view
        returns (uint256);

    function approve(address _dst, uint256 _amount) external returns (bool);

    function transfer(address _dst, uint256 _amount) external returns (bool);

    function transferFrom(
        address _src,
        address _dst,
        uint256 _amount
    ) external returns (bool);
}