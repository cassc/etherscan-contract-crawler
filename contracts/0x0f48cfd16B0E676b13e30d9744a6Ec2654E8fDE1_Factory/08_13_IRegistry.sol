// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

enum VaultType {DEFAULT, AUTOMATED, FIXED_TERM, EXPERIMENTAL}

interface IRegistry {
    function newExperimentalVault(
        address _token,
        address _governance,
        address _guardian,
        address _rewards,
        string calldata _name,
        string calldata _symbol,
        uint256 _releaseDelta
    ) external returns (address);

    function isRegistered(address token) external view returns (bool);

    function latestVault(address token) external view returns (address);


    function endorseVault(
        address _vault,
        uint256 _releaseDelta
    ) external;

    function owner() external view returns(address);
}