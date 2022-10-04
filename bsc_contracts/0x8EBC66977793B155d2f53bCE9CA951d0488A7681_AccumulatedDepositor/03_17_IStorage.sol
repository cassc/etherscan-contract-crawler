// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IStorage {
    function takeToken(uint256 amount, address token) external;

    function returnToken(uint256 amount, address token) external;

    function addEarn(uint256 amount) external;

    function _isUsedToken(address _token) external returns (bool);

    function getTokenDeposit(address account, address token)
        external
        view
        returns (uint256);

    function getTotalDeposit() external view returns (uint256);

    function getTokenBalance(address token) external view returns (uint256);

    function getTokenDeposited(address token) external view returns (uint256);

    function depositOnBehalf(
        uint256 amount,
        address token,
        address accountAddress
    ) external;
}