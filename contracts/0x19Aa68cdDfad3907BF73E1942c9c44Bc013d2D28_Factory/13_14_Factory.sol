// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Factory is AccessControlUpgradeable {
    /*************
     * Constants *
     *************/

    /// Contract code version
    uint256 public constant CODE_VERSION = 1_00_01;
    /// Contract administrator role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /// Transaction signer role
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    /**********
     * Events *
     **********/

    /// Template `name` has been created with an implementation at address
    /// `implementation`
    event TemplateCreated(string name, address implementation);

    /// Template `name` has been updated to a new implementation at address
    /// `newImplementation`
    event TemplateUpdated(
        string name,
        address oldImplementation,
        address newImplementation
    );

    /// An instance of template `name` with implementation at address
    /// `implementation` has been deployed to address `destination`
    event TemplateDeployed(
        string name,
        address implementation,
        address destination
    );

    /// Permissions for address `operator` to operate contract `instance` has
    /// changed to `allowed`
    event OperatorChanged(address instance, address operator, bool allowed);

    /***********
     * Storage *
     ***********/

    /// Template names
    string[] private _templates;

    /// Template implementation addresses
    mapping(string => address) public implementations;

    /// Contracts that are whitelisted for proxy calls
    mapping(address => bool) public whitelisted;

    /// Deployment fee
    uint256 public deploymentFee;

    /// Call fee
    uint256 public callFee;

    // Current contract version
    uint256 public version;

    /****************************
     * Contract init & upgrades *
     ****************************/

    constructor() initializer {}

    function initialize(address factoryOwner, address factorySigner)
        public
        initializer
    {
        _grantRole(ADMIN_ROLE, factoryOwner);
        _grantRole(SIGNER_ROLE, factorySigner);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(SIGNER_ROLE, ADMIN_ROLE);
    }

    function upgrade() external {
        require(version < CODE_VERSION, "Already upgraded");

        /* Start migration code */
        /* End migration code */

        version = CODE_VERSION;
    }

    /***********
     * Actions *
     ***********/

    /**
     * Deploy a new contract instance
     */
    function deploy(string calldata name, bytes calldata initdata)
        external
        payable
        paidOnly(deploymentFee)
    {
        _deploy(name, initdata);
    }

    /**
     * Proxy a call to a deployed contract instance
     */
    function call(address instance, bytes calldata data)
        external
        payable
        operatorOnly(instance)
        paidOnly(callFee)
    {
        _call(instance, data, msg.value - callFee);
    }

    /**
     * Deploy a new contract instance
     * with additional signatue verification
     */
    function deploy(
        string calldata name,
        bytes calldata initdata,
        bytes calldata signature
    )
        external
        payable
        signedOnly(abi.encodePacked(msg.sender, name, initdata), signature)
    {
        _deploy(name, initdata);
    }

    /**
     * Proxy a call to a deployed contract instance
     * with additional signatue verification
     */
    function call(
        address instance,
        bytes calldata data,
        bytes calldata signature
    )
        external
        payable
        operatorOnly(instance)
        signedOnly(abi.encodePacked(msg.sender, instance, data), signature)
    {
        _call(instance, data, msg.value);
    }

    /**
     * Manage permissions for an address to operate a deployed contract
     */
    function setOperator(
        address instance,
        address operator,
        bool allowed
    ) external operatorOnly(instance) {
        require(msg.sender != operator, "Cannot change own role");

        _setOperator(instance, operator, allowed);
    }

    /******************
     * View functions *
     ******************/

    /**
     * Get a list of all templates registered with the factory
     */
    function templates() external view returns (string[] memory templateNames) {
        uint256 count = _templates.length;
        templateNames = new string[](count);

        for (uint256 i = 0; i < count; i++) {
            templateNames[i] = _templates[i];
        }
    }

    /**
     * Check if an address is allowed to operate a deployed contract
     */
    function isOperator(address instance, address operator)
        public
        view
        returns (bool)
    {
        return hasRole(OPERATOR_ROLE(instance), operator);
    }

    /**
     * Update deployment fee
     */
    function setDeploymentFee(uint256 newFee) external onlyRole(ADMIN_ROLE) {
        deploymentFee = newFee;
    }

    /**
     * Update proxied call fee
     */
    function setCallFee(uint256 newFee) external onlyRole(ADMIN_ROLE) {
        callFee = newFee;
    }

    /**
     * Get the operator role for specified instance
     */
    function OPERATOR_ROLE(address instance) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(instance, "OPERATOR"));
    }

    /*******************
     * Admin functions *
     *******************/

    /**
     * Set implementation address
     */
    function setImplementation(string calldata name, address newImplementation)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(Address.isContract(newImplementation), "Not a contract");

        address oldImplementation = implementations[name];
        implementations[name] = newImplementation;

        if (oldImplementation == address(0)) {
            _templates.push(name);
            emit TemplateCreated(name, newImplementation);
        } else {
            emit TemplateUpdated(name, oldImplementation, newImplementation);
        }
    }

    /**
     * Update contract whitelist status
     */
    function setWhitelisted(address instance, bool newStatus)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setWhitelisted(instance, newStatus);
    }

    /**
     * Withdraw all fees from the contract to an address
     */
    function withdrawFees(address to) external onlyRole(ADMIN_ROLE) {
        Address.sendValue(payable(to), address(this).balance);
    }

    /*************
     * Internals *
     *************/

    function _setWhitelisted(address instance, bool newStatus) internal {
        whitelisted[instance] = newStatus;
    }

    function _setOperator(
        address instance,
        address operator,
        bool allowed
    ) internal {
        if (allowed) {
            _grantRole(OPERATOR_ROLE(instance), operator);
        } else {
            _revokeRole(OPERATOR_ROLE(instance), operator);
        }

        emit OperatorChanged(instance, operator, allowed);
    }

    function _deploy(string calldata name, bytes calldata initdata) internal {
        address implementation = implementations[name];
        require(implementation != address(0), "Missing implementation");

        address clone = Clones.clone(implementation);
        emit TemplateDeployed(name, implementation, clone);

        _setOperator(clone, msg.sender, true);
        _setWhitelisted(clone, true);

        _call(clone, initdata, 0);
    }

    function _call(
        address instance,
        bytes calldata data,
        uint256 value
    ) internal {
        require(whitelisted[instance], "Contract not whitelisted");

        assembly {
            let _calldata := mload(0x40)
            calldatacopy(_calldata, data.offset, data.length)

            let result := call(
                gas(),
                instance,
                value,
                _calldata,
                data.length,
                0,
                0
            )

            let returndata := mload(0x40)
            let size := returndatasize()
            returndatacopy(returndata, 0, size)

            switch result
            case 0 {
                revert(returndata, size)
            }
            default {
                return(returndata, size)
            }
        }
    }

    /*************
     * Modifiers *
     *************/

    modifier operatorOnly(address instance) {
        require(isOperator(instance, msg.sender), "Access denied");
        _;
    }

    modifier signedOnly(bytes memory message, bytes calldata signature) {
        address messageSigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(message),
            signature
        );

        require(hasRole(SIGNER_ROLE, messageSigner), "Signer not recognized");

        _;
    }

    modifier paidOnly(uint256 fee) {
        require(msg.value >= fee, "Insufficient payment");
        _;
    }
}