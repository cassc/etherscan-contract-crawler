//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/**
 * A utility contract which logs events pertaining to Fractal DAO metadata.
 */
interface IFractalRegistry {

    /**
     * Updates a DAO's registered "name". This is a simple string
     * with no restrictions or validation for uniqueness.
     *
     * @param _name new DAO name
     */
    function updateDAOName(string memory _name) external;

    /**
     * Declares an address as a subDAO of the caller's address.
     *
     * This declaration has no binding logic, and serves only
     * to allow us to find the list of "potential" subDAOs of any 
     * given Safe address.
     *
     * Given the list of declaring events, we can then check each
     * Safe still has a [FractalModule](../FractalModule.md) attached.
     *
     * If no FractalModule is attached, we'll exclude it from the
     * DAO hierarchy.
     *
     * In the case of a Safe attaching a FractalModule without calling 
     * to declare it, we would unfortunately not know to display it 
     * as a subDAO.
     *
     * @param _subDAOAddress address of the subDAO to declare 
     *      as a child of the caller
     */
    function declareSubDAO(address _subDAOAddress) external;
}