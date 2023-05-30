// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../interfaces/0.8.x/IMinterFilterV0.sol";
import "../../interfaces/0.8.x/IFilteredMinterV0.sol";
import "../../interfaces/0.8.x/IAdminACLV0.sol";
import "../../interfaces/0.8.x/IGenArt721CoreContractV3.sol";

import "../../libs/0.8.x/Bytes32Strings.sol";

import "@openzeppelin-4.5/contracts/utils/structs/EnumerableMap.sol";

pragma solidity 0.8.19;

/**
 * @title Minter filter contract that allows filtered minters to be set
 * on a per-project basis.
 * This is designed to be used with IGenArt721CoreContractV3 contracts.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with limited powers.
 * Privileged roles and abilities are controlled by the core contract's Admin
 * ACL contract and a project's artist. Both of these roles hold extensive
 * power and can modify a project's current minter.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the core contract's Admin ACL
 * contract:
 * - addApprovedMinter
 * - removeApprovedMinter
 * - removeMintersForProjects
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the core contract's Admin ACL
 * contract or a project's artist:
 * - setMinterForProject
 * - removeMinterForProject
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on minters
 */
contract MinterFilterV1 is IMinterFilterV0 {
    // add Enumerable Map methods
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    // add Bytes32Strings methods
    using Bytes32Strings for bytes32;

    /// version & type of this core contract
    bytes32 constant MINTER_FILTER_VERSION = "v1.0.1";

    function minterFilterVersion() external pure returns (string memory) {
        return MINTER_FILTER_VERSION.toString();
    }

    bytes32 constant MINTER_FILTER_TYPE = "MinterFilterV1";

    function minterFilterType() external pure returns (string memory) {
        return MINTER_FILTER_TYPE.toString();
    }

    /// Core contract address this minter interacts with
    address public immutable genArt721CoreAddress;

    /// This contract integrates with the IV3 core contract
    IGenArt721CoreContractV3 private immutable genArtCoreContract;

    /// projectId => minter address
    EnumerableMap.UintToAddressMap private minterForProject;

    /// minter address => qty projects currently using minter
    mapping(address => uint256) public numProjectsUsingMinter;

    /// minter address => is an approved minter?
    mapping(address => bool) public isApprovedMinter;

    function _onlyNonZeroAddress(address _address) internal pure {
        require(_address != address(0), "Must input non-zero address");
    }

    // function to restrict access to only AdminACL allowed calls
    // @dev defers which ACL contract is used to the core contract
    function _onlyCoreAdminACL(bytes4 _selector) internal {
        require(_coreAdminACLAllowed(_selector), "Only Core AdminACL allowed");
    }

    // function to restrict access to only the artist of `_projectId`, or
    // AdminACL allowed calls
    // @dev defers which ACL contract is used to the core contract
    function _onlyCoreAdminACLOrArtist(
        uint256 _projectId,
        bytes4 _selector
    ) internal {
        require(
            msg.sender ==
                genArtCoreContract.projectIdToArtistAddress(_projectId) ||
                _coreAdminACLAllowed(_selector),
            "Only Core AdminACL or Artist"
        );
    }

    function _onlyValidProjectId(uint256 _projectId) internal view {
        require(
            _projectId < genArtCoreContract.nextProjectId(),
            "Only existing projects"
        );
    }

    function _usingApprovedMinter(address _minterAddress) internal view {
        require(
            isApprovedMinter[_minterAddress],
            "Only approved minters are allowed"
        );
    }

    /**
     * @notice Initializes contract to be a Minter for `_genArt721Address`.
     * @param _genArt721Address Art Blocks core contract address
     * this contract will be a minter for. Can never be updated.
     */
    constructor(address _genArt721Address) {
        _onlyNonZeroAddress(_genArt721Address);
        genArt721CoreAddress = _genArt721Address;
        genArtCoreContract = IGenArt721CoreContractV3(_genArt721Address);
        emit Deployed();
    }

    /**
     * @notice Internal function that determines if msg.sender is allowed to
     * call a function on this contract. Defers to core contract's
     * adminACLAllowed function.
     */
    function _coreAdminACLAllowed(bytes4 _selector) internal returns (bool) {
        return
            genArtCoreContract.adminACLAllowed(
                msg.sender,
                address(this),
                _selector
            );
    }

    /**
     * @notice Approves minter `_minterAddress`.
     * @param _minterAddress Minter to be added as an approved minter.
     */
    function addApprovedMinter(address _minterAddress) external {
        _onlyCoreAdminACL(this.addApprovedMinter.selector);
        _onlyNonZeroAddress(_minterAddress);
        isApprovedMinter[_minterAddress] = true;
        emit MinterApproved(
            _minterAddress,
            IFilteredMinterV0(_minterAddress).minterType()
        );
    }

    /**
     * @notice Removes previously approved minter `_minterAddress`.
     * @param _minterAddress Minter to remove.
     */
    function removeApprovedMinter(address _minterAddress) external {
        _onlyCoreAdminACL(this.removeApprovedMinter.selector);
        require(isApprovedMinter[_minterAddress], "Only approved minters");
        require(
            numProjectsUsingMinter[_minterAddress] == 0,
            "Only unused minters"
        );
        isApprovedMinter[_minterAddress] = false;
        emit MinterRevoked(_minterAddress);
    }

    /**
     * @notice Sets minter for project `_projectId` to minter
     * `_minterAddress`.
     * @param _projectId Project ID to set minter for.
     * @param _minterAddress Minter to be the project's minter.
     */
    function setMinterForProject(
        uint256 _projectId,
        address _minterAddress
    ) external {
        _onlyCoreAdminACLOrArtist(
            _projectId,
            this.setMinterForProject.selector
        );
        _usingApprovedMinter(_minterAddress);
        _onlyValidProjectId(_projectId);
        // decrement number of projects using a previous minter
        (bool hasPreviousMinter, address previousMinter) = minterForProject
            .tryGet(_projectId);
        if (hasPreviousMinter) {
            numProjectsUsingMinter[previousMinter]--;
        }
        // add new minter
        numProjectsUsingMinter[_minterAddress]++;
        minterForProject.set(_projectId, _minterAddress);
        emit ProjectMinterRegistered(
            _projectId,
            _minterAddress,
            IFilteredMinterV0(_minterAddress).minterType()
        );
    }

    /**
     * @notice Updates project `_projectId` to have no configured minter.
     * @param _projectId Project ID to remove minter.
     * @dev requires project to have an assigned minter
     */
    function removeMinterForProject(uint256 _projectId) external {
        _onlyCoreAdminACLOrArtist(
            _projectId,
            this.removeMinterForProject.selector
        );
        _removeMinterForProject(_projectId);
    }

    /**
     * @notice Updates an array of project IDs to have no configured minter.
     * @param _projectIds Array of project IDs to remove minters for.
     * @dev requires all project IDs to have an assigned minter
     * @dev caution with respect to single tx gas limits
     */
    function removeMintersForProjects(uint256[] calldata _projectIds) external {
        _onlyCoreAdminACL(this.removeMintersForProjects.selector);
        uint256 numProjects = _projectIds.length;
        for (uint256 i; i < numProjects; i++) {
            _removeMinterForProject(_projectIds[i]);
        }
    }

    /**
     * @notice Updates project `_projectId` to have no configured minter
     * (reverts tx if project does not have an assigned minter).
     * @param _projectId Project ID to remove minter.
     */
    function _removeMinterForProject(uint256 _projectId) private {
        // remove minter for project and emit
        // `minterForProject.get()` reverts tx if no minter set for project
        numProjectsUsingMinter[minterForProject.get(_projectId)]--;
        minterForProject.remove(_projectId);
        emit ProjectMinterRemoved(_projectId);
    }

    /**
     * @notice Mint a token from project `_projectId` to `_to`, originally
     * purchased by `sender`.
     * @param _to The new token's owner.
     * @param _projectId Project ID to mint a new token on.
     * @param sender Address purchasing a new token.
     * @return _tokenId Token ID of minted token
     * @dev reverts w/nonexistent key error when project has no assigned minter
     */
    function mint(
        address _to,
        uint256 _projectId,
        address sender
    ) external returns (uint256 _tokenId) {
        // CHECKS
        // minter is the project's minter
        require(
            msg.sender == minterForProject.get(_projectId),
            "Only assigned minter"
        );
        // EFFECTS
        uint256 tokenId = genArtCoreContract.mint_Ecf(_to, _projectId, sender);
        return tokenId;
    }

    /**
     * @notice Gets the assigned minter for project `_projectId`.
     * @param _projectId Project ID to query.
     * @return address Minter address assigned to project `_projectId`
     * @dev requires project to have an assigned minter
     */
    function getMinterForProject(
        uint256 _projectId
    ) external view returns (address) {
        _onlyValidProjectId(_projectId);
        (bool _hasMinter, address _currentMinter) = minterForProject.tryGet(
            _projectId
        );
        require(_hasMinter, "No minter assigned");
        return _currentMinter;
    }

    /**
     * @notice Queries if project `_projectId` has an assigned minter.
     * @param _projectId Project ID to query.
     * @return bool true if project has an assigned minter, else false
     */
    function projectHasMinter(uint256 _projectId) external view returns (bool) {
        _onlyValidProjectId(_projectId);
        (bool _hasMinter, ) = minterForProject.tryGet(_projectId);
        return _hasMinter;
    }

    /**
     * @notice Gets quantity of projects that have assigned minters.
     * @return uint256 quantity of projects that have assigned minters
     */
    function getNumProjectsWithMinters() external view returns (uint256) {
        return minterForProject.length();
    }

    /**
     * @notice Get project ID and minter address at index `_index` of
     * enumerable map.
     * @param _index enumerable map index to query.
     * @return projectId project ID at index `_index`
     * @return minterAddress minter address for project at index `_index`
     * @return minterType minter type of minter at minterAddress
     * @dev index must be < quantity of projects that have assigned minters
     */
    function getProjectAndMinterInfoAt(
        uint256 _index
    )
        external
        view
        returns (
            uint256 projectId,
            address minterAddress,
            string memory minterType
        )
    {
        (projectId, minterAddress) = minterForProject.at(_index);
        minterType = IFilteredMinterV0(minterAddress).minterType();
        return (projectId, minterAddress, minterType);
    }
}