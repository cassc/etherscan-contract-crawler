// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ISmartInvoiceFactory.sol";
import "./interfaces/ISmartInvoice.sol";

contract SmartInvoiceFactory is ISmartInvoiceFactory, AccessControl {
    uint256 public invoiceCount = 0;
    // store invoice as struct by address? struct would be imp info;
    mapping(uint256 => address) internal _invoices;

    mapping(address => uint256) public resolutionRates;

    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev marks a deployed contract as a suitable implementation for additional escrow invoices formats

    // Implementation Storage
    mapping(bytes32 => mapping(uint256 => address)) public implementations;
    /** @dev mapping(implementationType => mapping(implementationVersion => address)) */
    mapping(bytes32 => uint256) public currentVersions;

    address public immutable wrappedNativeToken;

    event LogNewInvoice(
        uint256 indexed index,
        address indexed invoice,
        uint256[] amounts,
        bytes32 invoiceType,
        uint256 version
    );
    event UpdateResolutionRate(
        address indexed resolver,
        uint256 indexed resolutionRate,
        bytes32 details
    );
    event AddImplementation(
        bytes32 indexed name,
        uint256 indexed version,
        address implementation
    );

    constructor(address _wrappedNativeToken) {
        require(
            _wrappedNativeToken != address(0),
            "invalid wrappedNativeToken"
        );
        wrappedNativeToken = _wrappedNativeToken;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    function _init(
        address _invoiceAddress,
        address _recipient,
        uint256[] calldata _amounts,
        bytes calldata _data,
        bytes32 _type,
        uint256 _version
    ) internal {
        ISmartInvoice(_invoiceAddress).init(_recipient, _amounts, _data);

        uint256 invoiceId = invoiceCount;
        _invoices[invoiceId] = _invoiceAddress;
        invoiceCount = invoiceCount + 1;

        emit LogNewInvoice(
            invoiceId,
            _invoiceAddress,
            _amounts,
            _type,
            _version
        );
    }

    // ******************
    // Create
    // ******************

    function create(
        address _recipient,
        uint256[] calldata _amounts,
        bytes calldata _data,
        bytes32 _type
    ) external override returns (address) {
        uint256 _version = currentVersions[_type];
        address _implementation = implementations[_type][_version];
        require(_implementation != address(0), "Implementation does not exist");

        address invoiceAddress = Clones.clone(_implementation);

        _init(invoiceAddress, _recipient, _amounts, _data, _type, _version);

        return invoiceAddress;
    }

    function predictDeterministicAddress(bytes32 _type, bytes32 _salt)
        external
        view
        override
        returns (address)
    {
        uint256 _version = currentVersions[_type];
        address _implementation = implementations[_type][_version];
        return Clones.predictDeterministicAddress(_implementation, _salt);
    }

    function createDeterministic(
        address _recipient,
        uint256[] calldata _amounts,
        bytes calldata _data,
        bytes32 _type,
        bytes32 _salt
    ) external override returns (address) {
        uint256 _version = currentVersions[_type];
        address _implementation = implementations[_type][_version];
        require(_implementation != address(0), "Implementation does not exist");

        address invoiceAddress = Clones.cloneDeterministic(
            _implementation,
            _salt
        );

        _init(invoiceAddress, _recipient, _amounts, _data, _type, _version);

        return invoiceAddress;
    }

    /** @dev marks a deployed contract as a suitable implementation for additional escrow invoices formats */

    // ******************
    // Getters
    // ******************

    function getImplementation(
        bytes32 _implementationType,
        uint256 _implementationVersion
    ) external view returns (address) {
        return implementations[_implementationType][_implementationVersion];
    }

    function getInvoiceAddress(uint256 index) external view returns (address) {
        return _invoices[index];
    }

    // ******************
    // Arbitration
    // ******************

    function updateResolutionRate(uint256 _resolutionRate, bytes32 _details)
        external
    {
        resolutionRates[msg.sender] = _resolutionRate;
        emit UpdateResolutionRate(msg.sender, _resolutionRate, _details);
    }

    function resolutionRateOf(address _resolver)
        external
        view
        override
        returns (uint256)
    {
        return resolutionRates[_resolver];
    }

    /** @dev marks a deployed contract as a suitable implementation for additional escrow invoices formats */

    function addImplementation(bytes32 _type, address _implementation)
        external
        onlyRole(ADMIN)
    {
        require(_implementation != address(0), "implemenation is zero address");

        uint256 _version = currentVersions[_type];
        address currentImplementation = implementations[_type][_version];

        if (currentImplementation == address(0)) {
            implementations[_type][_version] = _implementation;
        } else {
            _version += 1;
            implementations[_type][_version] = _implementation;
            currentVersions[_type] = _version;
        }

        emit AddImplementation(_type, _version, _implementation);
    }
}