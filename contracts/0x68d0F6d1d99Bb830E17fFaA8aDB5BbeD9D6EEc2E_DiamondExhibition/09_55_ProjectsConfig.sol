// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.17;

/**
 * @notice Diamond Exhibition - Projects configuration.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
contract ProjectsConfig {
    /**
     * @notice The number of longform projects.
     */
    uint8 internal constant _NUM_LONGFORM_PROJECTS = 11;

    /**
     * @notice The number of pre-curated projects.
     */
    uint8 internal constant _NUM_CURATED_PROJECTS = 10;

    /**
     * @notice The total number of projects.
     */
    uint8 public constant NUM_PROJECTS = _NUM_LONGFORM_PROJECTS + _NUM_CURATED_PROJECTS;

    /**
     * @notice Returns the number of projects than can be minted per project.
     */
    function _maxNumPerProject() internal pure virtual returns (uint256[NUM_PROJECTS] memory sizes) {
        return [
            // Longform
            uint256(600), // Impossible Distance
            600, // cathedral study
            600, // Deja Vu
            800, // WaveShapes
            1000, // Ephemeral Tides
            600, // StackSlash
            450, // Viridaria
            1000, // Windwoven
            256, // Memory Loss
            1000, // The Collector's Room
            1000, // Extrañezas
            // Pre-curated
            100, // Everydays: Group Effort
            100, // Kid Heart
            100, // BEHEADED (SELF PORTRAIT)
            1127, // End Transmissions
            77, // DES CHOSES™
            100, // A Wintry Night in Chinatown
            100, // Penthouse
            200, // Hands of Umbra
            100, // Solitaire
            100 // Remnants of a Distant Dream
        ];
    }

    /**
     * @notice Returns the number of projects than can be minted per project.
     */
    function maxNumPerProject() external pure returns (uint256[NUM_PROJECTS] memory) {
        return _maxNumPerProject();
    }

    // =========================================================================
    //                          Project Types
    // =========================================================================

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
    function projectType(uint8 projectId) public pure returns (ProjectType) {
        return projectId < _NUM_LONGFORM_PROJECTS ? ProjectType.Longform : ProjectType.Curated;
    }

    /**
     * @notice Returns true iff the project is a longform project.
     */
    function _isLongformProject(uint8 projectId) internal pure virtual returns (bool) {
        return projectType(projectId) == ProjectType.Longform;
    }

    // =========================================================================
    //                          Artblocks
    // =========================================================================

    /**
     * @notice Returns the ArtBlocks engine project IDs for the longform projects.
     */
    function _artblocksProjectIds() internal pure virtual returns (uint8[_NUM_LONGFORM_PROJECTS] memory) {
        return [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
    }

    /**
     * @notice Returns the ArtBlocks engine project IDs for the longform projects.
     */
    function artblocksProjectIds() external pure returns (uint8[_NUM_LONGFORM_PROJECTS] memory) {
        return _artblocksProjectIds();
    }

    /**
     * @notice Returns the ArtBlocks engine project ID for a given project ID.
     * @dev Reverts if the project is not long-form.
     */
    function _artblocksProjectId(uint8 projectId) internal pure returns (uint256) {
        assert(_isLongformProject(projectId));
        return _artblocksProjectIds()[projectId];
    }
}