// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IVault {
    function token() external view returns (address);

    function reportHarvest(uint256 _harvestedAmount) external;

    function reportAdditionalToken(address _token) external;

    // Fees
    function performanceFeeGovernance() external view returns (uint256);

    function performanceFeeStrategist() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    // Actors
    function governance() external view returns (address);

    function keeper() external view returns (address);

    function guardian() external view returns (address);

    function strategist() external view returns (address);

    function treasury() external view returns (address);

    // External
    function deposit(uint256 _amount) external;

    function depositFor(address _recipient, uint256 _amount) external;

    function totalSupply() external returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function balance() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);
}