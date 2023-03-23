// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IFlagsStorage {

    /**
    * @dev Emitted when DAO Controller is updated from `prevDAOController` to `daoController`.
    */
    event SuperAdminUpdated(
        address indexed prevSuperAdmin,
        address indexed superAdmin
    );

    /**
    * @dev Emitted when new flag is added with `flag` short code and `index`.
    */
    event FlagAdded(bytes32 indexed flag, uint8 index);

    /**
    * @dev Emitted when existing flag is removed from FlagsStorage by `flag` short code.
    */
    event FlagRemoved(bytes32 indexed flag);

    /**
    * @dev Triggers to add new flag into gateway token system
    * @param _flag Flag short identifier
    * @param _index Flag index (limited to 255)
    * @notice Only executed by existing DAO Manager
    */
    function addFlag(bytes32 _flag, uint8 _index) external;

    /**
    * @dev Triggers to add multiple flags into gateway token system
    * @param _flags Array of flag short identifiers
    * @param _indexes Array of flag indexes (limited to 255)
    * @notice Only executed by existing DAO Manager
    */
    function addFlags(bytes32[] memory _flags, uint8[] memory _indexes) external;

    /**
    * @dev Triggers to get DAO Controller address
    */
    function superAdmin() external view returns (address);

    /**
    * @dev Triggers to get flag index from flags mapping
    */
    function flagIndexes(bytes32) external view returns (uint8);

    /**
    * @dev Triggers to check if a particular flag is supported
    * @param _flag Flag short identifier
    * @return Boolean for flag support
    */
    function isFlagSupported(bytes32 _flag) external view returns (bool);

    /**
    * @dev Triggers to remove existing flag from gateway token system
    * @param _flag Flag short identifier
    * @notice Only executed by existing DAO Manager
    */
    function removeFlag(bytes32 _flag) external;

    /**
    * @dev Triggers to remove multiple existing flags from gateway token system
    * @param _flags Array of flag short identifiers
    * @notice Only executed by existing DAO Manager
    */
    function removeFlags(bytes32[] memory _flags) external;

    /**
    * @dev Triggers to get bitmask of all supported flags
    */
    function supportedFlagsMask() external view returns (uint256);

    /**
    * @dev Triggers to transfer ownership of this contract to new DAO Controller, reverts on zero address and wallet addresses
    * @param _newSuperAdmin New DAO Controller contract address
    * @notice Only executed by existing DAO Manager
    */
    function updateSuperAdmin(address _newSuperAdmin) external;
}