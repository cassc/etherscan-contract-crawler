// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error GenerationAlreadyLoaded();
error GenerationNotLoaded();
error GenerationNotEnabled();
error InvalidLayerId();

contract MimeticMetadataBase is Ownable {
    using Strings for uint256;

    struct Generation {
        bool loaded;
        bool enabled;
        string baseURI;
    }

    // layerId => Generation
    mapping(uint256 => Generation) public generations;

    // tokenId => layerId
    mapping(uint256 => uint256) public tokenToGeneration;

    event GenerationEvolved(uint256 indexed _tokenId, uint256 indexed _layerId);
    event GenerationEnabled(uint256 indexed _layerId);

    constructor(string memory _initialURI) {
        loadGeneration(0, _initialURI);
        enableGeneration(0);
    }

    function loadGeneration(uint256 _layerId, string memory _baseURI) public virtual onlyOwner {
        if (_layerId < 0) revert InvalidLayerId();

        Generation storage generation = generations[_layerId];

        // Make sure that we are not overwriting an existing layer.
        if (generation.loaded) revert GenerationAlreadyLoaded();

        generations[_layerId] = Generation({ loaded: true, enabled: false, baseURI: _baseURI });
    }

    function enableGeneration(uint256 _layerId) public virtual onlyOwner {
        if (_layerId < 0) revert InvalidLayerId();

        Generation storage generation = generations[_layerId];

        // Make sure that the generation is loaded.
        if (!generation.loaded) revert GenerationNotLoaded();

        generation.enabled = true;

        emit GenerationEnabled(_layerId);
    }

    function _tokenURI(uint256 _tokenId) internal view virtual returns (string memory) {
        uint256 activeGenerationLayer = tokenToGeneration[_tokenId];

        // Make sure that the token has been revealed
        Generation memory activeGeneration = generations[activeGenerationLayer];

        return string(abi.encodePacked(activeGeneration.baseURI, _tokenId.toString()));
    }

    /**
     * @notice Evolves the token to the next generation
     * @dev It should be allowed only to the token owner
     * @param _tokenId the id of the token to evolve
     */
    function _evolve(uint256 _tokenId) internal virtual {
        uint256 _currentLayerId = tokenToGeneration[_tokenId];

        Generation memory nextGeneration = generations[_currentLayerId + 1];

        if (nextGeneration.loaded == false) revert GenerationNotLoaded();
        if (nextGeneration.enabled == false) revert GenerationNotEnabled();

        tokenToGeneration[_tokenId] = _currentLayerId + 1;

        emit GenerationEvolved(_tokenId, _currentLayerId + 1);
    }
}