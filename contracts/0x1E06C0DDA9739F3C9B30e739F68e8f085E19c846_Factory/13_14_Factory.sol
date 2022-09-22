// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./lib/ITemplate.sol";

contract Factory is AccessControlUpgradeable {
    /*************
     * Constants *
     *************/

    /// Contract code version
    uint256 public constant CODE_VERSION = 1_01_00;
    /// Contract administrator role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    /// Transaction signer role
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    /**********
     * Events *
     **********/

    // A new version of a template implementation has been added to the Factory
    event TemplateAdded(string name, uint256 version, address implementation);

    // An instance of a template has been deployed
    event TemplateDeployed(string name, uint256 version, address destination);

    // Permissions for address `operator` to operate contract `instance` has
    // changed to `allowed`
    event OperatorChanged(address instance, address operator, bool allowed);

    /***********
     * Storage *
     ***********/

    /// Template names
    string[] private _templateNames;

    /// Latest template implementations
    mapping(string => address) public latestImplementation;

    /// Contracts that are whitelisted for proxy calls
    mapping(address => bool) public whitelisted;

    /// Deployment fee
    uint256 public deploymentFee;

    /// Call fee
    uint256 public callFee;

    // Current contract version
    uint256 public version;

    // Latest template versions
    mapping(string => uint256) public latestVersion;

    // All template versions
    mapping(string => uint256[]) private _templateVersions;

    // Implementation addresses for all template versions
    mapping(string => mapping(uint256 => address))
        private _templateImplementations;

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
        if (version < 1_01_00) {
            // Iterate over all templates
            for (uint256 i = 0; i < _templateNames.length; i++) {
                string memory templateName = _templateNames[i];

                // Get the latest implementation address
                address implementationAddress = latestImplementation[
                    templateName
                ];
                ITemplate template = ITemplate(implementationAddress);

                // Get the latest implementation version
                uint256 templateVersion = template.VERSION();

                // Store the information
                _setTemplate(
                    templateName,
                    templateVersion,
                    implementationAddress
                );
            }
        }
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
        _deploy(name, latestVersion[name], initdata);
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
        string calldata templateName,
        bytes calldata initdata,
        bytes calldata signature
    )
        external
        payable
        signedOnly(
            abi.encodePacked(msg.sender, templateName, initdata),
            signature
        )
    {
        _deploy(templateName, latestVersion[templateName], initdata);
    }

    /**
     * Deploy a specific version of a template
     */
    function deploy(
        string calldata templateName,
        uint256 templateVersion,
        bytes calldata initdata,
        bytes calldata signature
    )
        external
        payable
        signedOnly(
            abi.encodePacked(
                msg.sender,
                templateName,
                templateVersion,
                initdata
            ),
            signature
        )
    {
        _deploy(templateName, templateVersion, initdata);
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
        uint256 count = _templateNames.length;
        templateNames = new string[](count);

        for (uint256 i = 0; i < count; i++) {
            templateNames[i] = _templateNames[i];
        }
    }

    /**
     * Get a list of all registered versions of a template
     */
    function versions(string memory templateName)
        external
        view
        returns (uint256[] memory templateVersions)
    {
        uint256 count = _templateVersions[templateName].length;
        templateVersions = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            templateVersions[i] = _templateVersions[templateName][i];
        }
    }

    /**
     * Get the implementation address of a specific version of a template
     */
    function implementation(string memory templateName, uint256 templateVersion)
        external
        view
        returns (address)
    {
        return _templateImplementations[templateName][templateVersion];
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
     * Add a new implementation
     */
    function registerTemplate(address implementationAddress)
        public
        onlyRole(ADMIN_ROLE)
    {
        require(
            Address.isContract(implementationAddress),
            "Not a valid contract"
        );

        // Read template information from the implementation contract
        ITemplate templateImplementation = ITemplate(implementationAddress);
        string memory templateName = templateImplementation.NAME();
        uint256 templateVersion = templateImplementation.VERSION();

        // Store the template information
        _setTemplate(templateName, templateVersion, implementationAddress);
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

    function _setTemplate(
        string memory templateName,
        uint256 templateVersion,
        address implementationAddress
    ) internal {
        require(
            _templateImplementations[templateName][templateVersion] ==
                address(0),
            "Version already exists"
        );

        // Store the template implementation address
        _templateImplementations[templateName][
            templateVersion
        ] = implementationAddress;

        // Update the list of available versions for a template
        _templateVersions[templateName].push(templateVersion);

        // Check if we're adding a new template and update template list if needed
        if (latestImplementation[templateName] == address(0)) {
            _templateNames.push(templateName);
        }

        // Update the current implementation version & address if needed
        if (templateVersion > latestVersion[templateName]) {
            latestVersion[templateName] = templateVersion;
            latestImplementation[templateName] = implementationAddress;
        }

        emit TemplateAdded(
            templateName,
            templateVersion,
            implementationAddress
        );
    }

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

    function _deploy(
        string calldata templateName,
        uint256 templateVersion,
        bytes calldata initdata
    ) internal {
        address implementationAddress = _templateImplementations[templateName][
            templateVersion
        ];
        require(implementationAddress != address(0), "Missing implementation");

        address clone = Clones.clone(implementationAddress);
        emit TemplateDeployed(templateName, templateVersion, clone);

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