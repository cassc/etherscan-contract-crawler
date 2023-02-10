// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IMetadata {
    function assembleSVG (address addr, string memory ensName, bytes31 ethyData) external view returns (bytes memory);
    function generateMetadata (uint256 tokenId,
                               address addr,
                               uint8 generation,
                               bytes31 parameters,
                               bytes32 extensions)
        external view returns (string memory);
}

import "./lib/AccessRoles.sol";
/*
 * @title EthyToken
 * @author Ponderware Ltd
 * @dev
 * @notice
 */
contract EthyToken is ERC721Enumerable, AccessRoles {

    constructor (address gen0MetadataContract, uint48 gen0MaxSupply) ERC721("Ethy", unicode"Ξy") {
        Generations.push(Generation(gen0MetadataContract, gen0MaxSupply, gen0MaxSupply));
    }

    struct Details {
        uint8 generation;
        bytes31 parameters;
        bytes32 extensions;
    }

    mapping (uint256 => Details) public TokenDetails;

    struct Generation {
        address metadataContract;
        uint48 maxSupply;
        uint48 availableSupply;
    }

    Generation[] public Generations;

    function currentGeneration () public view returns (uint8) {
        return uint8(Generations.length - 1);
    }

    function generationTotalSupply (uint generationId) public view returns (uint) {
        return Generations[generationId].maxSupply - Generations[generationId].availableSupply;
    }

    function incrementGeneration (address metadataContract, uint48 maxSupply) public onlyAdmin whenNotFrozen {
        require(currentGeneration() < 255, "Generation limit reached");
        Generation storage currentGen = Generations[currentGeneration()];
        currentGen.maxSupply -= currentGen.availableSupply;
        currentGen.availableSupply = 0;
        Generations.push(Generation(metadataContract, maxSupply, maxSupply));
    }

    function updateGenerationMetadata (uint256 generationId, address metadataContract) public onlyAdmin whenNotFrozen {
        Generations[generationId].metadataContract = metadataContract;
    }

    function updateToken (uint256 tokenId, bytes31 parameters, bytes32 extensions) public onlyEditor whenNotFrozen {
        _requireMinted(tokenId);
        Details storage details = TokenDetails[tokenId];
        details.parameters = parameters;
        details.extensions = extensions;
    }

    function mint (address to, bytes31 parameters, bytes32 extensions) public onlyMinter whenNotPaused whenNotFrozen {
        uint256 tokenId = totalSupply();
        uint8 generationId = currentGeneration();
        require(Generations[generationId].availableSupply > 0, "Max Generation Supply Reached");
        Generations[generationId].availableSupply--;
        Details memory details = Details(generationId, parameters, extensions);
        TokenDetails[tokenId] = details;
        _safeMint(to, tokenId, "");
    }

    function tokenURI (uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        Details storage details = TokenDetails[tokenId];
        return IMetadata(Generations[details.generation].metadataContract)
            .generateMetadata(tokenId,
                              ownerOf(tokenId),
                              details.generation,
                              details.parameters,
                              details.extensions);
    }

    function demo (address addr, string memory ens, bytes31 ethyData) public view returns (string memory) {
        return string(IMetadata(Generations[0].metadataContract).assembleSVG(addr, ens, ethyData));
    }

    function _beforeTokenTransfer (
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}