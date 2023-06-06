// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12; // solhint-disable-line compiler-version

// this interface is defined because ConvexStakingWrapper has incompatible 0.6.12
// original file is contracts/interfaces/ISiloRepository.sol
interface ISiloRepository0612Like {
    function getSilo(address _asset) external returns (address);
    function owner() external returns (address);
    function router() external returns (address);
    function siloRepositoryPing() external returns (bytes4);
}