// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStrategy {
    function rebalance()
        external
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        );

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function feeCollector() external view returns (address);

    function isReservedToken(address _token) external view returns (bool);

    function keepers() external view returns (address[] memory);

    function migrate(address _newStrategy) external;

    function token() external view returns (address);

    function pool() external view returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function VERSION() external view returns (string memory);

    function collateral() external view returns (address);
}