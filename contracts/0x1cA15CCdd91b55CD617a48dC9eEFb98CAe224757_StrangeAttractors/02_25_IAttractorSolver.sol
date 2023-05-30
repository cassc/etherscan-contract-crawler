// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 David Huber (@cxkoda)
// All Rights Reserved

pragma solidity >=0.8.0 <0.9.0;

import "./AttractorSolution.sol";

/**
 * @notice Parameters going to the numerical ODE solver.
 * @param numberOfIterations Total number of iterations.
 * @param dt Timestep increment in each iteration
 * @param skip Amount of iterations between storing two points.
 * @dev `numberOfIterations` has to be dividable without rest by `skip`.
 */
struct SolverParameters {
    uint256 numberOfIterations;
    uint256 dt;
    uint8 skip;
}

/**
 * @notice Parameters going to the projection routines.
 * @dev The lengths of all fields have to match the dimensionality of the
 * considered system.
 * @param axis1 First projection axis (horizontal image coordinate)
 * @param axis2 Second projection axis (vertical image coordinate)
 * @param offset Offset applied before projecting.
 */
struct ProjectionParameters {
    int256[] axis1;
    int256[] axis2;
    int256[] offset;
}

/**
 * @notice Starting point for the numerical simulation
 * @dev The length of the starting point has to match the dimensionality of the
 * considered system.
 * I agree, this struct looks kinda dumb, but I really like speaking types.
 * So as long as we don't have typedefs for non-elementary types, we are stuck
 * with this cruelty.
 */
struct StartingPoint {
    int256[] startingPoint;
}

/**
 * @notice Interface for simulators of chaotic systems.
 * @dev Implementations of this interface will contain the mathematical
 * description of the underlying differential equations, deal with its numerical
 * solution and the 2D projection of the results.
 * Implementations will internally use fixed-point numbers with a precision of
 * 96 bits by convention.
 * @author David Huber (@cxkoda)
 */
interface IAttractorSolver {
    /**
     * @notice Simulates the evolution of a chaotic system.
     * @dev This is the core piece of this class that performs everything
     * at once. All relevant algorithm for the evaluation of the ODEs
     * the numerical scheme, the projection and storage are contained within
     * this method for performance reasons.
     * @return An `AttractorSolution` containing already projected 2D points
     * and tangents to them.
     */
    function computeSolution(
        SolverParameters calldata,
        StartingPoint calldata,
        ProjectionParameters calldata
    ) external pure returns (AttractorSolution memory);

    /**
     * @notice Generates a random starting point for the system.
     */
    function getRandomStartingPoint(uint256 randomSeed)
        external
        view
        returns (StartingPoint memory);

    /**
     * @notice Generates the default projection for a given edition of the
     * system.
     */
    function getDefaultProjectionParameters(uint256 editionId)
        external
        view
        returns (ProjectionParameters memory);

    /**
     * @notice Returns the type/name of the dynamical system.
     */
    function getSystemType() external pure returns (string memory);

    /**
     * @notice Returns the dimensionality of the dynamical system (number of
     * ODEs).
     */
    function getDimensionality() external pure returns (uint8);

    /**
     * @notice Returns the precision of the internally used fixed-point numbers.
     * @dev The solvers operate on fixed-point numbers with a given PRECISION,
     * i.e. the amount of bits reserved for decimal places.
     * By convention, this method will return 96 throughout the project.
     */
    function getFixedPointPrecision() external pure returns (uint8);

    /**
     * @notice Checks if given `ProjectionParameters` are valid`
     */
    function isValidProjectionParameters(ProjectionParameters memory)
        external
        pure
        returns (bool);
}