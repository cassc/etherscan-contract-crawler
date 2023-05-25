// SPDX-License-Identifier: PROPRIERTARY

// Author: Ilya A. Shlyakhovoy
// Email: [email protected]

pragma solidity 0.8.17;

interface IRights {
    event AdminAdded(address indexed admin);
    event AdminDefined(address indexed admin, address indexed contractHash);
    event AdminRemoved(address indexed admin);
    event AdminCleared(address indexed admin, address indexed contractHash);

    /**
@notice Add a new admin for the Rigths contract
@param admin_ New admin address
*/

    function addAdmin(address admin_) external;

    /**
@notice Add a new admin for the any other contract
@param contract_ Contract address packed into address
@param admin_ New admin address
*/

    function addAdmin(address contract_, address admin_) external;

    /**
@notice Remove the existing admin from the Rigths contract
@param admin_ Admin address
*/

    function removeAdmin(address admin_) external;

    /**
@notice Add a new admin for the any other contract
@param contract_ Contract address packed into address
@param admin_ New admin address
*/

    function removeAdmin(address contract_, address admin_) external;

    /**
@notice Get the rights for the contract for the caller
@param contract_ Contract address packed into address
@return have rights or not
*/
    function haveRights(address contract_) external view returns (bool);

    /**
@notice Get the rights for the contract
@param contract_ Contract address packed into address
@param admin_ Admin address
@return have rights or not
*/
    function haveRights(address contract_, address admin_)
        external
        view
        returns (bool);
}