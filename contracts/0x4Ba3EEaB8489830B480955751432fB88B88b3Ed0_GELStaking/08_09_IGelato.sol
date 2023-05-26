// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGelato {
    function removeExecutorSigners(
        address[] calldata executorSigners_
    ) external;

    function owner() external view returns (address);

    function isExecutorSigner(
        address _executorSigner
    ) external view returns (bool);

    function executorSigners() external view returns (address[] memory);
}