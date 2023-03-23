// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IJBTokenUriResolver} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol";
import {IJBProjects} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {JBUriOperations} from "./Libraries/JBUriOperations.sol";
import {JBOperatable, IJBOperatorStore} from "@jbx-protocol/juice-contracts-v3/contracts/abstract/JBOperatable.sol";

/**
 * @title Juicebox TokenUriResolver Registry
 * @notice The registry serves metadata for all Juciebox Protocol v2 projects.
 * @dev The default metadata for all projects can be updated by the contract owner.
 * @dev Juicebox project owners and operators can override the default metadata for their project with their own IJBTokenUriResolver contracts.
 */
contract TokenUriResolver is IJBTokenUriResolver, JBOperatable, Ownable {
    /**
     * @notice The address of the Juicebox Projects contract.
     */
    IJBProjects public immutable projects;

    /**
     * @notice The maximum amount of gas used by a resolver, to allow falling back on the default resolver.
     */
    uint256 constant MAX_RESOLVER_GAS_USAGE = 50_000_000;

    /**
     * @notice Emitted when the default IJBTokenUriResolver is set.
     */
    event DefaultTokenUriResolverSet(IJBTokenUriResolver indexed tokenUriResolver);

    /**
     * @notice Emitted when the Token Uri Resolver for a project is set.
     */
    event ProjectTokenUriResolverSet(uint256 indexed projectId, IJBTokenUriResolver indexed tokenUriResolver);

    /**
     * @notice Each project's IJBTokenUriResolver metadata contract.
     * @dev Mapping of projectId => tokenUriResolver
     * @dev projectId 0 returns the default resolver address.
     * @return IJBTokenUriResolver The address of the IJBTokenUriResolver for the project, or 0 if none is set.
     */
    mapping(uint256 => IJBTokenUriResolver) public tokenUriResolvers;

    /**
     * @notice TokenUriResolver constructor.
     * @dev Sets the default IJBTokenUriResolver. This resolver is used for all projects that do not have a custom resolver. 
     * @dev Sets immutable references to JBProjects and JBOperatorStore contracts.
     * @param _projects The address of the Juicebox Projects contract.
     * @param _operatorStore The address of the JBOperatorStore contract.
     * @param _defaultTokenUriResolver The address of the default IJBTokenUriResolver.
     */
    constructor(
        IJBProjects _projects,
        IJBOperatorStore _operatorStore,
        IJBTokenUriResolver _defaultTokenUriResolver
    ) JBOperatable(_operatorStore) {
        projects = _projects;
        tokenUriResolvers[0] = IJBTokenUriResolver(_defaultTokenUriResolver);
    }
    
    /**
     *  @notice Get the token uri for a project.
     *  @dev Called by `JBProjects.tokenUri(uint256)`. If a project has a custom IJBTokenUriResolver, it is used instead of the default resolver.
     *  @param _projectId The id of the project.
     *  @return tokenUri The token uri for the project.
     *  @inheritdoc IJBTokenUriResolver
     */
    function getUri(uint256 _projectId) external view override returns (string memory tokenUri) {
        address _resolver = address(tokenUriResolvers[_projectId]);

        if (_resolver == address(0)) {
            return tokenUriResolvers[0].getUri(_projectId);
        }

        // If the getUri call to _resolver exceeds the MAX_RESOLVER_GAS_USAGE, fall back to the default resolver. 
        try IJBTokenUriResolver(_resolver).getUri{gas: MAX_RESOLVER_GAS_USAGE}(_projectId) returns (
            string memory _tokenUri
        ) {
            return _tokenUri;
        } catch {
            return tokenUriResolvers[0].getUri(_projectId);
        }
    }

    /**
     * @notice Set the IJBTokenUriResolver for a project. This function is restricted to the project's owner and operators.
     * @dev Set the IJBTokenUriResolver for a project to 0 to use the default resolver.
     * @param _projectId The id of the project.
     * @param _resolver The address of the IJBTokenUriResolver, or 0 to restore the default setting.
     */
    function setTokenUriResolverForProject(
        uint256 _projectId,
        IJBTokenUriResolver _resolver
    ) external requirePermission(projects.ownerOf(_projectId), _projectId, JBUriOperations.SET_TOKEN_URI) {
        tokenUriResolvers[_projectId] = _resolver;
        emit ProjectTokenUriResolverSet(_projectId, _resolver);
    }

    /**
     * @notice Set the default IJBTokenUriResolver.
     * @dev Only available to this contract's owner.
     * @param _resolver The address of the default token uri resolver.
     */
    function setDefaultTokenUriResolver(IJBTokenUriResolver _resolver) external onlyOwner {
        tokenUriResolvers[0] = IJBTokenUriResolver(_resolver);

        emit DefaultTokenUriResolverSet(_resolver);
    }

    /**
     * @notice Get the default IJBTokenUriResolver address.
     * @dev Convenience function for browsing contracts on block explorers.
     * @return IJBTokenURiResolver The address of the default token uri resolver.
     */
    function defaultTokenUriResolver() external view returns (IJBTokenUriResolver) {
        return tokenUriResolvers[0];
    }
}