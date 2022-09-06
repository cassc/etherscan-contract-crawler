//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDAOFactory {
    struct CreateDAOParams {
        address daoImplementation;
        address daoFactory;
        address accessControlImplementation;
        string daoName;
        string[] roles;
        string[] rolesAdmins;
        address[][] members;
        string[] daoFunctionDescs;
        string[][] daoActionRoles;
    }

    event DAOCreated(address indexed daoAddress, address indexed accessControl, address indexed sender, address creator);

    /// @notice Creates a DAO with an access control contract
    /// @param creator Address of the Dao Creator
    /// @param createDAOParams Struct of all the parameters required to create a DAO
    /// @return dao The address of the deployed DAO proxy contract
    /// @return accessControl The address of the deployed access control proxy contract
    function createDAO(address creator, CreateDAOParams calldata createDAOParams)
        external
        returns (address, address);
}