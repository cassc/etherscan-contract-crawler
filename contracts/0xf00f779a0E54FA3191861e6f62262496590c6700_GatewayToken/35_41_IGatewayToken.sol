// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/Charge.sol";

interface IGatewayToken {
    /**
    * @dev Emitted when GatewayToken DAO Manager transferred to `newDAOManager` address.
    */
    event DAOManagerTransferred(address previousDAOManager, address newDAOManager, uint256 network);

    /**
    * @dev Triggers to get all information relating to gateway `tokenId`
    * @param tokenId Gateway token id
    */
    function getToken(uint256 tokenId) 
        external 
        view  
        returns (
            address owner,
            uint8 state,
            string memory identity,
            uint256 expiration,
            uint256 bitmask
        );

    /**
    * @dev Triggers to verify if address has a GATEKEEPER role. 
    * @param gatekeeper Gatekeeper address
    * @param network GatekeeperNetwork id
    */
    function isGatekeeper(address gatekeeper, uint256 network) external returns (bool);

    function createNetwork(uint256 network, string memory name, bool daoGoverned, address daoManager) external;

    function renameNetwork(uint256 network, string memory name) external;

    function getNetwork(uint256 network) external view returns (string memory);

    /**
    * @dev Triggers to add new network authority into the system. 
    * @param authority Network Authority address
    * @param network GatekeeperNetwork id
    *
    * @notice Only triggered by Identity.com Admin
    */
    function addNetworkAuthority(address authority, uint256 network) external;

    /**
    * @dev Triggers to remove existing network authority from gateway token. 
    * @param authority Network Authority address
    * @param network GatekeeperNetwork id
    *
    * @notice Only triggered by Identity.com Admin
    */
    function removeNetworkAuthority(address authority, uint256 network) external;

    /**
    * @dev Triggers to verify if authority has a NETWORK_AUTHORITY_ROLE role. 
    * @param authority Network Authority address
    * @param network GatekeeperNetwork id
    */
    function isNetworkAuthority(address authority, uint256 network) external returns (bool);

    /**
    * @dev Transfers Gateway Token DAO Manager access from daoManager to `newManager`
    * @param newManager Address to transfer DAO Manager role for.
    */
    function transferDAOManager(address previousManager, address newManager, uint256 network) external;

    function mint(address to, uint256 network, uint256 expiration, uint256 mask, Charge calldata charge) external;
}