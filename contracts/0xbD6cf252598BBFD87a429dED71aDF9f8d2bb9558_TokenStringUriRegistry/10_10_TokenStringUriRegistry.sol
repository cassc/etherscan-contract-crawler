// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IJBTokenUriResolver} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol";
import {JBOperatable, IJBOperatorStore} from "@jbx-protocol/juice-contracts-v3/contracts/abstract/JBOperatable.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";

contract TokenStringUriRegistry is IJBTokenUriResolver, JBOperatable {
    /**
     * @notice Emitted when the uri for a project is set.
     */
    event ProjectTokenUriResolverSet(
        uint256 indexed projectId,
        string indexed uri
    );

    IJBProjects public immutable projects;
    uint public constant SET_TOKEN_URI = 20;

    /**
     * @notice The custom URIs corresponding to each project. Should return ERC721 tokenUri compliant JSON.
     */
    mapping(uint256 => string) public uri;

    constructor(
        IJBProjects _projects,
        IJBOperatorStore _operatorStore
    ) JBOperatable(_operatorStore) {
        projects = _projects;
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param Documents a parameter just like in doxygen (must be followed by parameter name)
    /// @return Documents the return variables of a contract’s function state variable
    /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)

    /**
     * @notice Get the URI for a given project
     * @param _projectId The project to get the URI for
     * @return tokenUri The URI for the given project
     * @inheritdoc	IJBTokenUriResolver
     */
    function getUri(
        uint256 _projectId
    ) external view returns (string memory tokenUri) {
        return uri[_projectId];
    }

    /**
     * @notice Set the URI for a given project
     * @dev Only callable by the owner of the project
     * @param _projectId The project to set the URI for
     * @param _uri The URI to set
     */
    function setUri(
        uint256 _projectId,
        string memory _uri
    )
        external
        requirePermission(
            projects.ownerOf(_projectId),
            _projectId,
            SET_TOKEN_URI
        )
    {
        uri[_projectId] = _uri;
        emit ProjectTokenUriResolverSet(_projectId, _uri);
    }
}