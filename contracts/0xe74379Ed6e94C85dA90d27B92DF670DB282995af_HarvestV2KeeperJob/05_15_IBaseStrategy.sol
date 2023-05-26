// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IBaseStrategy {
    // Events

    event Harvested(uint256 _profit, uint256 _loss, uint256 _debtPayment, uint256 _debtOutstanding);

    // Views

    function vault() external view returns (address _vault);

    function strategist() external view returns (address _strategist);

    function rewards() external view returns (address _rewards);

    function keeper() external view returns (address _keeper);

    function want() external view returns (address _want);

    function name() external view returns (string memory _name);

    function harvestTrigger(uint256 _callCost) external view returns (bool);

    // Methods

    function harvest() external;
}