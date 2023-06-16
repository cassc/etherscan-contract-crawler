// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBaseStrategy {
    function vault() external view returns (address _vault);

    function strategist() external view returns (address _strategist);

    function rewards() external view returns (address _rewards);

    function keeper() external view returns (address _keeper);

    function want() external view returns (address _want);

    function name() external view returns (string memory _name);

    // Setters
    function setStrategist(address _strategist) external;

    function setKeeper(address _keeper) external;

    function setRewards(address _rewards) external;

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;
}