//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IGrayBoys_Mutants.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GrayBoys_Mutants is IGrayBoys_Mutants, ERC721, AccessControl {
    using Strings for uint256;

    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 private constant MUTATOR_CONTRACT_ROLE = keccak256("MUTATOR_CONTRACT_ROLE");

    uint256[4] private MUTATION_TYPE_START_ID = [
        0,      // _mutationTypeId = 0, Level 1
        10000,  // _mutationTypeId = 1, Level 2
        20000,  // _mutationTypeId = 2, Level 3
        30000   // _mutationTypeId = 3, Embryo
    ];

    bool public isMetadataLocked;
    IERC721 public grayboysContract;

    string public baseUri;
    uint256 public level3MutationCount;
    uint256 public embryoMutationCount;

    constructor(address _grayboysContractAddress) ERC721("Gray Boys Mutations", "GRAY BOYS MUTANTS") {
        grayboysContract = IERC721(_grayboysContractAddress);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    /* Mutants base implementation */
    function mutate(address _ownerAddress, uint256 _mutationTypeId, uint256[] calldata _fromTokenIds) external onlyRole(MUTATOR_CONTRACT_ROLE) override {
        require(_mutationTypeId == 0 || _mutationTypeId == 1, "Invalid _mutationTypeId"); // L1s and L2s are the only ones requiring GBs

        for (uint256 i = 0; i < _fromTokenIds.length; i++) {
            uint256 tokenId = _fromTokenIds[i];

            require(grayboysContract.ownerOf(tokenId) == _ownerAddress, "Not owner of specified GB");
            require(!isMutated(tokenId, _mutationTypeId), "Gray Boy for mutation type already mutated.");

            _safeMint(_ownerAddress, MUTATION_TYPE_START_ID[_mutationTypeId] + tokenId);
        }
    }

    function specialMutate(address _ownerAddress, uint256 _mutationTypeId, uint256 _count) external onlyRole(MUTATOR_CONTRACT_ROLE) override {
        require(_mutationTypeId == 2 || _mutationTypeId == 3, "Invalid _mutationTypeId"); //Crystals and Embryos

        for (uint256 i = 0; i < _count; i++) {
            uint256 mutatedTokenId;

            if (_mutationTypeId == 2) { // L3
                mutatedTokenId = MUTATION_TYPE_START_ID[_mutationTypeId] + level3MutationCount;
                level3MutationCount++;
            }
            else { // Embryo
                mutatedTokenId = MUTATION_TYPE_START_ID[_mutationTypeId] + embryoMutationCount;
                embryoMutationCount++;
            }

            _safeMint(_ownerAddress, mutatedTokenId);
        }
    }

    /* Metadata functions */
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseUri, _tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IGrayBoys_Mutants).interfaceId || super.supportsInterface(interfaceId);
    }

    /* Util functions */
    function isMutated(uint256 _grayBoyTokenId, uint256 _mutationTypeId) public view returns (bool) {
        require(_mutationTypeId < 4, "Invalid _mutationTypeId");
        return _exists(MUTATION_TYPE_START_ID[_mutationTypeId] + _grayBoyTokenId);
    }

    /* Admin functions */
    // Prevents metadata from being changed at the deployer's will.
    // Should be done after switch to decentralised storage.
    function lockMetadata() onlyRole(OWNER_ROLE) external {
        isMetadataLocked = true;
    }

    function setBaseURI(string calldata _baseUri) onlyRole(OWNER_ROLE) external {
        require(!isMetadataLocked, "metadata URI is locked");
        baseUri = _baseUri;
    }
}