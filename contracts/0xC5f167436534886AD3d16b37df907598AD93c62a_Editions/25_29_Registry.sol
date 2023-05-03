// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████▓▀██████████████████████████████████████████████
// ██████████████████████████████████  ╙███████████████████████████████████████████
// ███████████████████████████████████    ╙████████████████████████████████████████
// ████████████████████████████████████      ╙▀████████████████████████████████████
// ████████████████████████████████████▌        ╙▀█████████████████████████████████
// ████████████████████████████████████▌           ╙███████████████████████████████
// ████████████████████████████████████▌            ███████████████████████████████
// ████████████████████████████████████▌         ▄█████████████████████████████████
// ████████████████████████████████████       ▄████████████████████████████████████
// ███████████████████████████████████▀   ,▄███████████████████████████████████████
// ██████████████████████████████████▀ ,▄██████████████████████████████████████████
// █████████████████████████████████▄▓█████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████

contract Registry {
    bytes4 public constant REGISTER_STORAGE_ROLE =
        bytes4(keccak256("REGISTER_STORAGE_ROLE"));
    bytes4 public constant REGISTER_PLUGIN_ROLE =
        bytes4(keccak256("REGISTER_PLUGIN_ROLE"));

    mapping(address => bool) public adminPermissions; // only admins
    mapping(address => bool) public contractPermissions; // trusted router contracts
    mapping(address => mapping(address => bool)) public operatorPermissions; // operate on behalf of a certain user
    mapping(address => mapping(address => mapping(bytes4 => bool)))
        public rolePermissions;

    uint64 immutable chainAndNetworkId;

    mapping(uint64 => address) public storageContracts;
    mapping(uint64 => address) public pluginContracts;
    mapping(address => uint64) public ownerNonces;
    mapping(uint64 => address) public idOwners;

    event AdminPermissionChanged(address indexed admin, bool isAuthorized);
    event ContractPermissionChanged(
        address indexed contractAddress,
        bool isAuthorized
    );
    event OperatorPermissionChanged(
        address indexed user,
        address indexed operator,
        bool isAuthorized
    );
    event UserRoleChanged(
        address indexed user,
        address indexed operator,
        bytes4 indexed role,
        bool isAuthorized
    );
    event IdRegistered(
        uint64 indexed id,
        address indexed owner,
        address indexed storageContract
    );
    event PluginConnected(uint64 indexed id, address indexed pluginContract);
    event StorageContractMigrated(
        uint64 indexed id,
        address indexed oldStorageContract,
        address indexed newStorageContract
    );
    event PluginContractMigrated(
        uint64 indexed id,
        address indexed oldPluginContract,
        address indexed newPluginContract
    );

    constructor(address[] memory _initialAdmins) {
        chainAndNetworkId = uint64(
            uint16(bytes2(keccak256(abi.encodePacked(block.chainid))))
        );
        for (uint64 i = 0; i < _initialAdmins.length; ++i) {
            adminPermissions[_initialAdmins[i]] = true;
            emit AdminPermissionChanged(_initialAdmins[i], true);
        }
    }

    /**
     * @notice Set admini permissions
     * @param _admin The address of the administrator
     * @param _isAuthorized A boolean to indicate if the administrator is authorized
     */
    function setAdmin(address _admin, bool _isAuthorized) public onlyAdmins {
        adminPermissions[_admin] = _isAuthorized;
        emit AdminPermissionChanged(_admin, _isAuthorized);
    }

    /**
     * @notice Set contract permissions
     * @param _contract The address of the contract
     * @param _isAuthorized A boolean to indicate if the contract is authorized
     */
    function setContractPermission(
        address _contract,
        bool _isAuthorized
    ) public onlyAdmins {
        contractPermissions[_contract] = _isAuthorized;
        emit ContractPermissionChanged(_contract, _isAuthorized);
    }

    /**
     * @notice Set operator permissions
     * @param _operator The address of the operator
     * @param _isAuthorized A boolean to indicate if the operator is authorized
     */
    function setOperatorPermission(
        address _operator,
        bool _isAuthorized
    ) public {
        operatorPermissions[msg.sender][_operator] = _isAuthorized;
        emit OperatorPermissionChanged(msg.sender, _operator, _isAuthorized);
    }

    /**
     * @notice Set user role permissions
     * @param _operator The address of the user
     * @param _role The role associated with the user
     * @param _isAuthorized A boolean to indicate if the user role is authorized
     */
    function setUserRolePermission(
        address _operator,
        bytes4 _role,
        bool _isAuthorized
    ) public {
        rolePermissions[msg.sender][_operator][_role] = _isAuthorized;
        emit UserRoleChanged(msg.sender, _operator, _role, _isAuthorized);
    }

    /**
     * @notice Set user role permissions for an operator in batch
     * @param _user The address of the user for whom the roles are being set
     * @param _operator The address of the operator being granted the roles
     * @param _roles The array of roles associated with the user and operator
     * @param _isAuthorized A boolean to indicate if the user roles are authorized
     */
    function setBatchUserRolePermissions(
        address _user,
        address _operator,
        bytes4[] memory _roles,
        bool _isAuthorized
    ) public {
        for (uint256 i = 0; i < _roles.length; ++i) {
            rolePermissions[_user][_operator][_roles[i]] = _isAuthorized;
            emit UserRoleChanged(_user, _operator, _roles[i], _isAuthorized);
        }
    }

    /**
     * @notice Check if a user is an admin
     * @param _user The address of the user
     * @return A boolean indicating if the user is an admin
     */
    function isAdmin(address _user) public view returns (bool) {
        return adminPermissions[_user];
    }

    /**
     * @notice Check if an address is an operator for a user
     * @param _user The address of the user
     * @param _operator The address of the operator
     * @return A boolean indicating if the address is an operator for the user
     */
    function isOperator(
        address _user,
        address _operator
    ) public view returns (bool) {
        return operatorPermissions[_user][_operator];
    }

    /**
     * @notice Check if an operator is authorized for a specific role
     * @param _user The address of the user
     * @param _operator The address of the operator
     * @param _role The role to check for authorization
     * @return A boolean indicating if the operator is authorized for the specified role
     */
    function isAuthorized(
        address _user,
        address _operator,
        bytes4 _role
    ) public view returns (bool) {
        if (adminPermissions[_operator] || _user == _operator) {
            return true;
        }
        if (operatorPermissions[_user][_operator]) {
            return true;
        }
        if (rolePermissions[_user][_operator][_role]) {
            return true;
        }
        if (contractPermissions[_operator]) {
            return true;
        }
        return false;
    }

    /**
     * @notice Check if an operator is authorized for a specific role by ID
     * @param _id The ID to check for authorization
     * @param _operator The address of the operator
     * @param _role The role to check for authorization
     * @return A boolean indicating if the operator is authorized for the specified role by ID
     */
    function isAuthorizedById(
        uint64 _id,
        address _operator,
        bytes4 _role
    ) public view returns (bool) {
        address _user = idOwners[_id];
        return isAuthorized(_user, _operator, _role);
    }

    /**
     * @notice Check if an operator is authorized for an array of specific roles
     * @param _user The address of the user
     * @param _operator The address of the operator
     * @param _roles The array of roles to check for authorization
     * @return A boolean indicating if the operator is authorized for all specified roles
     */
    function isAuthorizedForRoles(
        address _user,
        address _operator,
        bytes4[] memory _roles
    ) public view returns (bool) {
        if (adminPermissions[_operator] || _user == _operator) {
            return true;
        }
        if (operatorPermissions[_user][_operator]) {
            return true;
        }
        if (contractPermissions[_operator]) {
            return true;
        }
        for (uint256 i = 0; i < _roles.length; ++i) {
            if (!rolePermissions[_user][_operator][_roles[i]]) {
                return false;
            }
        }
        return false;
    }

    /**
     * @notice Get the owner of an ID
     * @param _id The ID to get the owner of
     * @return The address of the owner
     */
    function getIdOwner(uint64 _id) external view returns (address) {
        return idOwners[_id];
    }

    /**
     * @notice Get the storage contract for an ID
     * @param _id The ID to get the storage contract of
     * @return The address of the storage contract
     */
    function getStorageContract(uint64 _id) external view returns (address) {
        return storageContracts[_id];
    }

    /**
     * @notice Get the plugin for an ID
     * @param _id The ID to get the plugin of
     * @return The address of the plugin
     */
    function getPlugin(uint64 _id) external view returns (address) {
        return pluginContracts[_id];
    }

    /**
     * @notice Register a storage contract
     * @param _owner The address of the storage contract owner
     * @param _salt The salt for generating the ID
     * @return The ID of the registered storage contract
     */
    function registerStorageContract(
        address _owner,
        uint8 _salt
    )
        external
        onlyAuthorizedByUser(_owner, REGISTER_STORAGE_ROLE)
        returns (uint64)
    {
        uint64 id = calculateIdWithSalt(_owner, _salt);
        require(storageContracts[id] == address(0), "ID_ALREADY_REGISTERED");
        ownerNonces[_owner] += 1;
        storageContracts[id] = msg.sender;
        idOwners[id] = _owner;
        emit IdRegistered(id, _owner, msg.sender);
        return id;
    }

    /**
     * @notice Connect a plugin contract to an ID
     * @param _id The ID to connect the plugin contract to
     */
    function connectPluginContract(
        uint64 _id
    ) external onlyAuthorizedByUser(idOwners[_id], REGISTER_PLUGIN_ROLE) {
        require(storageContracts[_id] != address(0), "ID_NOT_REGISTERED");
        require(
            pluginContracts[_id] == address(0),
            "PLUGIN_ALREADY_REGISTERED"
        );
        pluginContracts[_id] = msg.sender;
        emit PluginConnected(_id, msg.sender);
    }

    /**
     * @notice Migrate a storage contract to a new address
     * @param _id The ID of the storage contract to migrate
     * @param _newStorageContract The address of the new storage contract
     * @return A boolean indicating if the migration was successful
     */
    function migrateStorageContract(
        uint64 _id,
        address _newStorageContract
    ) external onlyStorageContracts(_id) returns (bool) {
        address oldStorageContract = storageContracts[_id];
        require(oldStorageContract != address(0), "ID_NOT_REGISTERED");
        storageContracts[_id] = _newStorageContract;

        emit StorageContractMigrated(
            _id,
            oldStorageContract,
            _newStorageContract
        );

        return true;
    }

    /**
     * @notice Migrate a plugin contract to a new address
     * @param _id The ID of the plugin contract to migrate
     * @param _newPluginContract The address of the new plugin contract
     * @return A boolean indicating if the migration was successful
     */
    function migratePluginContract(
        uint64 _id,
        address _newPluginContract
    ) external onlyPluginContracts(_id) returns (bool) {
        address oldPluginContract = pluginContracts[_id];
        require(oldPluginContract != address(0), "ID_NOT_CONNECTED_TO_PLUGIN");
        pluginContracts[_id] = _newPluginContract;

        emit PluginContractMigrated(_id, oldPluginContract, _newPluginContract);

        return true;
    }

    /**
     * @notice Calculate the ID with the provided owner and salt
     * @param _owner The address of the owner
     * @param _salt The salt for generating the ID
     * @return The calculated ID
     */
    function calculateIdWithSalt(
        address _owner,
        uint8 _salt
    ) public view returns (uint64) {
        return
            (uint64(
                bytes8(
                    keccak256(
                        abi.encodePacked(_owner, ownerNonces[_owner], _salt)
                    )
                )
            ) << 16) | chainAndNetworkId;
    }

    /**
     * @notice Calculate the ID with the provided owner, nonce, and salt
     * @param _owner The address of the owner
     * @param _nonce The nonce for generating the ID
     * @param _salt The salt for generating the ID
     * @return The calculated ID
     */
    function calculateIdWithSaltAndNonce(
        address _owner,
        uint64 _nonce,
        uint8 _salt
    ) public view returns (uint64) {
        return
            (uint64(
                bytes8(keccak256(abi.encodePacked(_owner, _nonce, _salt)))
            ) << 16) | chainAndNetworkId;
    }

    modifier onlyAdmins() {
        require(adminPermissions[msg.sender], "NOT_AN_ADMIN");
        _;
    }

    modifier onlyOperators(address _user) {
        require(
            adminPermissions[msg.sender] ||
                operatorPermissions[_user][msg.sender],
            "NOT_AN_OPERATOR"
        );
        _;
    }

    modifier onlyStorageContracts(uint64 _id) {
        require(
            isAdmin(msg.sender) || storageContracts[_id] == msg.sender,
            "NOT_A_STORAGE_CONTRACT"
        );
        _;
    }

    modifier onlyPluginContracts(uint64 _id) {
        require(
            isAdmin(msg.sender) || pluginContracts[_id] == msg.sender,
            "NOT_A_PLUGIN_CONTRACT"
        );
        _;
    }

    modifier onlyAuthorizedByUser(address _user, bytes4 _role) {
        require(isAuthorized(_user, msg.sender, _role), "UNAUTHORIZED");
        _;
    }
}