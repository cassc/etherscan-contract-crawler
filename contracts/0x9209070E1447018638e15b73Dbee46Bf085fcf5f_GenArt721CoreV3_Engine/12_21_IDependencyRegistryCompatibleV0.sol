// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.19;

interface IDependencyRegistryCompatibleV0 {
    /// Dependency registry managed by Art Blocks
    function artblocksDependencyRegistryAddress()
        external
        view
        returns (address);

    /**
     * @notice Returns script information for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return scriptTypeAndVersion Project's script type and version
     * (e.g. "p5js(atSymbol)1.0.0")
     * @return aspectRatio Aspect ratio of project (e.g. "1" for square,
     * "1.77777778" for 16:9, etc.)
     * @return scriptCount Count of scripts for project
     */
    function projectScriptDetails(
        uint256 _projectId
    )
        external
        view
        returns (
            string memory scriptTypeAndVersion,
            string memory aspectRatio,
            uint256 scriptCount
        );
}