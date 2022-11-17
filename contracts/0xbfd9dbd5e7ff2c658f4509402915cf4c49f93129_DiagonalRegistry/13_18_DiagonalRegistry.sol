// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import { IDiagonalRegistry } from "../../interfaces/core/registry/IDiagonalRegistry.sol";
import { IDiagonalOrgProxy } from "../../interfaces/proxy/IDiagonalOrgProxy.sol";
import { DiagonalOrgProxy } from "../../proxy/DiagonalOrgProxy.sol";

import { ECDSA } from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

import { PausableUpgradeable } from "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

contract DiagonalRegistry is IDiagonalRegistry, Initializable, PausableUpgradeable, UUPSUpgradeable {
    using ECDSA for bytes32;

    /*******************************
     * Errors *
     *******************************/

    error InvalidDiagonalOwnerAddress();
    error InvalidDiagonalAdminAddress();
    error InvalidDiagonalOrgBeaconAddress();
    error InvalidDiagonalOrgImplementationAddress();

    error InvalidOrganisationOwnerAddress();
    error InvalidOrganisationSignerAddress();
    error InvalidOrganisationReceiverAddress();

    error NotDiagonalOwner();
    error NotDiagonalAdmin();

    error DiagonalOrgAlreadyInitialized();
    error DiagonalOrgBadDeployment();

    /*******************************
     * Events *
     *******************************/

    /// Organisation events
    event OrganisationCreated(address indexed organisation, address indexed signer);

    /// Diagonal management events
    event DiagonalOwnerUpdated(address indexed newOwner);
    event DiagonalAdminUpdated(address indexed newAdmin);
    event DiagonalOrgBeaconUpdated(address indexed newOrgBeacon);
    event DiagonalOrgImplementationUpdated(address indexed newOrgImplementation);

    /*******************************
     * Constants *
     *******************************/
    string public constant VERSION = "1.0.0";

    bytes32 private constant ORG_PROXY_INIT_CODEHASH = keccak256(type(DiagonalOrgProxy).creationCode);

    /*******************************
     * State vars *
     *******************************/

    /**
     * @notice DiagonalRegistry contract owner
     * @dev owner can only update the contract, and will be set to be timelock contract
     */
    address public owner;

    /**
     * @notice DiagonalRegistry admin
     * @dev responsible for creating organisations for users
     */
    address public admin;

    /**
     * @notice Address of the organisation beacon
     * @dev used for when creating new organisation contracts
     */
    address public orgBeacon;

    /**
     * @notice Address of the initial organisation implementation
     * @dev used for when creating new organisation contracts
     * this variable is introduced for gas saving purposes on Org contract creation
     */
    address public orgImplementation;

    /*******************************
     * Modifiers *
     *******************************/

    modifier onlyDiagonalOwner() virtual {
        if (msg.sender != owner) revert NotDiagonalOwner();
        _;
    }

    modifier onlyDiagonalAdmin() virtual {
        if (msg.sender != admin) revert NotDiagonalAdmin();
        _;
    }

    /*******************************
     * Constructor *
     *******************************/

    constructor() {
        // Prevent the implementation contract from being initilised and re-initilised
        _disableInitializers();
    }

    /*******************************
     * Functions start *
     *******************************/

    /// ****** Initialization ******

    function initialize(
        address _owner,
        address _admin,
        address _orgBeacon,
        address _orgImplementation
    ) external onlyInitializing {
        if (_owner == address(0)) revert InvalidDiagonalOwnerAddress();
        if (_admin == address(0)) revert InvalidDiagonalAdminAddress();
        if (_orgBeacon.code.length == 0) revert InvalidDiagonalOrgBeaconAddress();
        if (_orgImplementation.code.length == 0) revert InvalidDiagonalOrgImplementationAddress();

        PausableUpgradeable.__Pausable_init();
        UUPSUpgradeable.__UUPSUpgradeable_init();

        owner = _owner;
        admin = _admin;
        orgBeacon = _orgBeacon;
        orgImplementation = _orgImplementation;
    }

    /// ****** Organisation management ******

    function createOrganisation(bytes32 orgId, address orgSigner)
        external
        whenNotPaused
        onlyDiagonalAdmin
        returns (address orgAddress)
    {
        if (orgSigner == address(0)) revert InvalidOrganisationSignerAddress();

        orgAddress = _createOrgContract(orgId, orgSigner);

        emit OrganisationCreated(orgAddress, orgSigner);
    }

    function _createOrgContract(bytes32 orgId, address orgSigner) private returns (address _orgAddress) {
        _orgAddress = address(new DiagonalOrgProxy{ salt: orgId }());
        if (_orgAddress == address(0)) revert DiagonalOrgBadDeployment();

        bytes memory orgInitSignature = abi.encodeWithSignature("initialize(address)", orgSigner);
        IDiagonalOrgProxy(_orgAddress).initializeProxy(orgBeacon, orgImplementation, orgInitSignature);
    }

    /// ****** Diagonal registry management ******

    function pause() public onlyDiagonalOwner {
        _pause();
    }

    function unpause() public onlyDiagonalOwner {
        _unpause();
    }

    function updateDiagonalOwner(address newOwner) external whenNotPaused onlyDiagonalOwner {
        if (newOwner == address(0)) revert InvalidDiagonalOwnerAddress();
        owner = newOwner;
        emit DiagonalOwnerUpdated(newOwner);
    }

    function updateDiagonalAdmin(address newAdmin) external whenNotPaused onlyDiagonalOwner {
        if (newAdmin == address(0)) revert InvalidDiagonalAdminAddress();
        admin = newAdmin;
        emit DiagonalAdminUpdated(newAdmin);
    }

    function updateDiagonalOrgBeacon(address newOrgBeacon) external whenNotPaused onlyDiagonalOwner {
        if (newOrgBeacon.code.length == 0) revert InvalidDiagonalOrgBeaconAddress();
        orgBeacon = newOrgBeacon;
        emit DiagonalOrgBeaconUpdated(newOrgBeacon);
    }

    function updateDiagonalOrgImplementation(address newOrgImplementation) external whenNotPaused onlyDiagonalOwner {
        if (newOrgImplementation.code.length == 0) revert InvalidDiagonalOrgImplementationAddress();
        orgImplementation = newOrgImplementation;
        emit DiagonalOrgImplementationUpdated(newOrgImplementation);
    }

    function getOrgAddress(bytes32 salt) public view returns (address orgAddress) {
        bytes32 _hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, ORG_PROXY_INIT_CODEHASH));
        orgAddress = address(uint160(uint256(_hash)));
    }

    /**
     * @notice _authorizeUpgrade - requirement from the UUPSUpgradeable contract
     */
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyDiagonalOwner {}
}