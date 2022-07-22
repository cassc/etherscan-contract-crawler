// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BBYC.sol";
import "./BoredBitsChemistryClub.sol";

//Based on Yuga Labs' Smart Contract. 
//@yugalabs

contract MutantBitsYachtClub is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint8 private constant NUM_MUTANT_TYPES = 2;
    uint256 private constant MEGA_MUTATION_TYPE = 69;
    uint256 public constant NUM_MEGA_MUTANTS = 8;
    uint16 private constant MAX_MEGA_MUTATION_ID = 30007;
    uint256 public constant SERUM_MUTATION_OFFSET = 10000;

    uint256 public constant PS_MAX_MUTANT_PURCHASE = 20;
    uint256 public constant PS_MAX_MUTANTS = 10000;

    uint256 public mutantPrice = 10000000000000000;

    uint256 public numMutantsMinted;

    bool public publicSaleActive;
    bool public serumMutationActive;

    uint16 private currentMegaMutationId = 30000;
    mapping(uint256 => uint256) private megaMutationIdsByApe;

    string private baseURI;

    BBYC private immutable bbyc;
    BoredBitsChemistryClub private immutable bbcc;

    modifier whenPublicSaleActive() {
        require(publicSaleActive, "Public sale is not active");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address bbycAddress,
        address bbccAddress
    ) ERC721(name, symbol) {
        bbyc = BBYC(bbycAddress);
        bbcc = BoredBitsChemistryClub(bbccAddress);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function mintMutants(uint256 numMutants)
        external
        payable
        whenPublicSaleActive
        nonReentrant
    {
        require(
            numMutantsMinted + numMutants <= PS_MAX_MUTANTS,
            "Minting would exceed max supply"
        );
        require(numMutants > 0, "Must mint at least one mutant");
        require(
            numMutants <= PS_MAX_MUTANT_PURCHASE,
            "Requested number exceeds maximum"
        );

        uint256 costToMint = mutantPrice * numMutants;
        require(costToMint <= msg.value, "Ether value sent is not correct");
        
        for (uint256 i = 0; i < numMutants; i++) {
            uint256 mintIndex = numMutantsMinted;
            if (numMutantsMinted < PS_MAX_MUTANTS) {
                numMutantsMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mintMutantsByTeam(uint256 numMutants)
        external
        onlyOwner
    {
        require(
            numMutantsMinted + numMutants <= PS_MAX_MUTANTS,
            "Minting would exceed max supply"
        );
        require(numMutants > 0, "Must mint at least one mutant");

        for (uint256 i = 0; i < numMutants; i++) {
            uint256 mintIndex = numMutantsMinted;
            if (numMutantsMinted < PS_MAX_MUTANTS) {
                numMutantsMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mutateMultipleWithSerum(uint256 serumTypeId, uint256[] calldata apeIds) external nonReentrant {
        require(serumMutationActive, "Serum Mutation is not active");
        require(
            bbcc.balanceOf(msg.sender, serumTypeId) >= apeIds.length,
            "Must own at least one of this serum type to mutate"
        );

        for(uint i = 0; i < apeIds.length;i++) {
            _mutateApeWithSerum(serumTypeId, apeIds[i]);
        }
    }
    
    function mutateApeWithSerum(uint256 serumTypeId, uint256 apeId)
        external
        nonReentrant
    {
        require(serumMutationActive, "Serum Mutation is not active");
        _mutateApeWithSerum(serumTypeId, apeId);
    }

    function _mutateApeWithSerum(uint256 serumTypeId, uint256 apeId)
        internal
    {
        require(
            bbcc.balanceOf(msg.sender, serumTypeId) > 0,
            "Must own at least one of this serum type to mutate"
        );

        require(
            bbyc.ownerOf(apeId) == msg.sender,
            "Must own the ape you're attempting to mutate"
        );

        uint256 mutantId;

        if (serumTypeId == MEGA_MUTATION_TYPE) {
            require(
                currentMegaMutationId <= MAX_MEGA_MUTATION_ID,
                "Would exceed supply of serum-mutatable MEGA MUTANTS"
            );
            require(
                megaMutationIdsByApe[apeId] == 0,
                "Ape already mutated with MEGA MUTATION SERUM"
            );

            mutantId = currentMegaMutationId;
            megaMutationIdsByApe[apeId] = mutantId;
            currentMegaMutationId++;
        } else {
            mutantId = getMutantId(serumTypeId, apeId);
            require(
                !_exists(mutantId),
                "Ape already mutated with this type of serum"
            );
        }

        bbcc.burnSerumForAddress(serumTypeId, msg.sender);
        _safeMint(msg.sender, mutantId);
    }

    function getMutantIdForApeAndSerumCombination(
        uint256 apeId,
        uint8 serumTypeId
    ) external view returns (uint256) {
        uint256 mutantId;
        if (serumTypeId == MEGA_MUTATION_TYPE) {
            mutantId = megaMutationIdsByApe[apeId];
            require(mutantId > 0, "Invalid MEGA Mutant Id");
        } else {
            mutantId = getMutantId(serumTypeId, apeId);
        }

        require(_exists(mutantId), "Query for nonexistent mutant");

        return mutantId;
    }

    function hasApeBeenMutatedWithType(uint8 serumType, uint256 apeId)
        external
        view
        returns (bool)
    {
        if (serumType == MEGA_MUTATION_TYPE) {
            return megaMutationIdsByApe[apeId] > 0;
        }

        uint256 mutantId = getMutantId(serumType, apeId);
        return _exists(mutantId);
    }

    function getMutantId(uint256 serumType, uint256 apeId)
        internal
        pure
        returns (uint256)
    {
        require(
            serumType != MEGA_MUTATION_TYPE,
            "Mega mutant ID can't be calculated"
        );
        return (apeId * NUM_MUTANT_TYPES) + serumType + SERUM_MUTATION_OFFSET;
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        require(
            tokenId < MAX_MEGA_MUTATION_ID,
            "tokenId outside collection bounds"
        );
        return _exists(tokenId);
    }

    function totalApesMutated() external view returns (uint256) {
        return totalSupply() - numMutantsMinted;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function toggleSerumMutationActive() external onlyOwner {
        serumMutationActive = !serumMutationActive;
    }

    function setMutantPrice(uint256 newPrice) external onlyOwner {
        mutantPrice = newPrice;
    }
}