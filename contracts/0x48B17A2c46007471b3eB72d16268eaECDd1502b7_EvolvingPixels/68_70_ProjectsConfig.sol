// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.17;

/**
 * @notice PROOF Curated: Evolving Pixels - Projects configuration.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract ProjectsConfig {
    /**
     * @notice The number of longform projects.
     */
    uint8 internal constant _NUM_LONGFORM_PROJECTS = 4;

    /**
     * @notice The number of pre-curated projects.
     */
    uint8 internal constant _NUM_CURATED_PROJECTS = 6;

    /**
     * @notice The total number of projects.
     */
    uint8 public constant _NUM_PROJECTS = _NUM_LONGFORM_PROJECTS + _NUM_CURATED_PROJECTS;

    /**
     * @notice Returns the ArtBlocks engine project IDs for the longform projects.
     */
    function artblocksProjectIds() external pure returns (uint8[_NUM_LONGFORM_PROJECTS] memory) {
        return _artblocksProjectIds();
    }

    /**
     * @notice Returns the number of projects than can be minted per project.
     */
    function projectSizes() external pure virtual returns (uint256[] memory) {
        return _projectSizes();
    }

    /**
     * @notice Returns the ArtBlocks engine project IDs for the longform projects.
     */
    function _artblocksProjectIds() internal pure virtual returns (uint8[_NUM_LONGFORM_PROJECTS] memory) {
        return [1, 3, 2, 4];
    }

    /**
     * @notice Returns the number of projects than can be minted per project.
     */
    function _projectSizes() internal pure virtual returns (uint256[] memory) {
        uint256[] memory sizes = new uint256[](_NUM_PROJECTS);
        // Longform
        sizes[0] = 100; // Fingacode
        sizes[1] = 19; // Lars Wander
        sizes[2] = 150; // Juan Rodriguez Garcia
        sizes[3] = 100; // Nan Zhao + Xin Liu
        // Curated
        sizes[4] = 150; // Cory Haber
        sizes[5] = 75; // Dean Blacc
        sizes[6] = 32; // Entangled Others
        sizes[7] = 101; // Helena Sarin
        sizes[8] = 64; // Ivona Tau
        sizes[9] = 100; // Sasha Stiles
        return sizes;
    }

    /**
     * @notice The different types of projects.
     */
    enum ProjectType {
        Longform,
        Curated
    }

    /**
     * @notice Returns the project type for a given project ID.
     */
    function _projectType(uint8 projectId) internal pure returns (ProjectType) {
        if (projectId < _NUM_LONGFORM_PROJECTS) return ProjectType.Longform;

        return ProjectType.Curated;
    }

    /**
     * @notice Returns true iff the project is a longform project.
     */
    function _isLongformProject(uint8 projectId) internal pure virtual returns (bool) {
        return _projectType(projectId) == ProjectType.Longform;
    }

    /**
     * @notice Returns the ArtBlocks engine project ID for a given EvolvingPixels project ID.
     * @dev Reverts if the project is not long-form.
     */
    function _artblocksProjectId(uint8 projectId) internal pure returns (uint256) {
        assert(_isLongformProject(projectId));
        return _artblocksProjectIds()[projectId];
    }
}