// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPoolFactory {
    function pools(address _pool) external view returns (bool);

    function treasury() external view returns (address);

    function poolImplementationAddress() external view returns (address);

    function rollBackImplementation() external view returns (address);

    function allowUpgrade() external view returns (bool);

    function isPaused(address _pool) external view returns (bool);
}