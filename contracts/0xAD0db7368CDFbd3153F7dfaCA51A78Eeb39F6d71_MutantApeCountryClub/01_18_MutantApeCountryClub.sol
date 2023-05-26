// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Gacc.sol";
import "./Gasc.sol";


contract MutantApeCountryClub is ERC721Enumerable, Ownable, ReentrancyGuard {

    //    ░██████╗░░█████╗░░█████╗░░█████╗░
    //    ██╔════╝░██╔══██╗██╔══██╗██╔══██╗
    //    ██║░░██╗░███████║██║░░╚═╝██║░░╚═╝
    //    ██║░░╚██╗██╔══██║██║░░██╗██║░░██╗
    //    ╚██████╔╝██║░░██║╚█████╔╝╚█████╔╝
    //    ░╚═════╝░╚═╝░░╚═╝░╚════╝░░╚════╝░
    
    uint256 private constant NUM_MUTANT_TYPES = 2;
    uint256 private constant MEGA_MUTATION_TYPE = 69;
    uint256 public constant NUM_MEGA_MUTANTS = 21;
    uint256 private constant MAX_MEGA_MUTATION_ID = 15020;
    uint256 public constant SERUM_MUTATION_OFFSET = 4999;

    uint256[18] legendaryGrandpas = [0,1,2,3,4,5,6,7,8,9,156,576,1713,2976,3023,3622,3767,3867];

    // Whitelist Constants
    uint256 public constant WL_PRICE = 0.15 ether;
    uint256 public constant WL_MAX_MUTANT_PURCHASE = 1;
    uint256 public constant WL_MAX_MULTI_MUTANT_PURCHASE = 5;
    
    // Public Sale Constants
    uint256 public constant PS_MAX_MUTANT_PURCHASE = 20;
    // // The Public sale final price - 0.01 ETH
    uint256 public constant PS_MUTANT_ENDING_PRICE = 10000000000000000;

    // The max supply of Minted Mutants (WL and PS)
    uint256 public constant MAX_MINTED_MUTANTS = 5000;

    // Whitelists
    mapping(address => uint256) public presaleAddresses;
    bytes32 public wlFreeMerkleRoot;
    bytes32 public wlFreeMultiMerkleRoot;
    bytes32 public wlMultiMerkleRoot;
    bytes32 public wlMerkleRoot;
    // Public sale starting price - mutable, in case we need to pause
    // and restart the sale
    uint256 public publicSaleMutantStartingPrice;

    // Supply of Minted Mutants (not Mutated Apes)
    uint256 public numMutantsMinted;

    // Public sale params
    uint256 public publicSaleDuration;
    uint256 public publicSaleStartTime;

    // Sale switches
    bool public saleFreeWhitelistActive;
    bool public saleWhitelistActive;
    bool public publicSaleActive;
    bool public serumMutationActive;

    // Starting index block for the entire collection
    uint256 public collectionStartingIndexBlock;
    // Starting index for Minted Mutants
    uint256 public mintedMutantsStartingIndex;
    // Starting index for MEGA Mutants
    uint256 public megaMutantsStartingIndex;

    uint16 private currentMegaMutationId = 15000;
    mapping(uint256 => uint256) private megaMutationIdsByApe;

    string private baseURI;
    Gacc private immutable gacc;
    Gasc private immutable gasc;

    event MutantPublicSaleStart(
        uint256 indexed _saleDuration,
        uint256 indexed _saleStartTime
    );
    event MutantPublicSalePaused(
        uint256 indexed _currentPrice,
        uint256 indexed _timeElapsed
    );
    event StartingIndicesSet(
        uint256 indexed _mintedMutantsStartingIndex,
        uint256 indexed _megaMutantsStartingIndex
    );

    modifier whenPublicSaleActive() {
        require(publicSaleActive, "Public sale is not active");
        _;
    }

    modifier whenPreSaleActive() {
        require(saleWhitelistActive, "Whitelist sale is not active");
        _;
    }

    modifier startingIndicesNotSet() {
        require(
            mintedMutantsStartingIndex == 0,
            "Minted Mutants starting index is already set"
        );
        require(
            megaMutantsStartingIndex == 0,
            "Mega Mutants starting index is already set"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address gaccAddress,
        address gascAddress
    ) ERC721(name, symbol) {
        gacc = Gacc(gaccAddress);
        gasc = Gasc(gascAddress);
    }

    function startPublicSale(uint256 saleDuration, uint256 saleStartPrice)
        external
        onlyOwner
    {
        require(!publicSaleActive, "Public sale has already begun");
        publicSaleDuration = saleDuration;
        publicSaleMutantStartingPrice = saleStartPrice;
        publicSaleStartTime = block.timestamp;
        publicSaleActive = true;
        emit MutantPublicSaleStart(saleDuration, publicSaleStartTime);
    }

    function pausePublicSale() external onlyOwner whenPublicSaleActive {
        uint256 currentSalePrice = getMintPrice();
        publicSaleActive = false;
        emit MutantPublicSalePaused(currentSalePrice, getElapsedSaleTime());
    }

    function getElapsedSaleTime() internal view returns (uint256) {
        return
            publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
    }

    function getRemainingSaleTime() external view returns (uint256) {
        require(publicSaleStartTime > 0, "Public sale hasn't started yet");
        if (getElapsedSaleTime() >= publicSaleDuration) {
            return 0;
        }

        return (publicSaleStartTime + publicSaleDuration) - block.timestamp;
    }

    function setWlMerkleRoot(bytes32 _wlMerkleRoot) external onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }

    function setFreeWlMerkleRoot(bytes32 _freeWlMerkleRoot) external onlyOwner {
        wlFreeMerkleRoot = _freeWlMerkleRoot;
    }

    function setFreeMultiWlMerkleRoot(bytes32 _freeMultiWlMerkleRoot) external onlyOwner {
        wlFreeMultiMerkleRoot = _freeMultiWlMerkleRoot;
    }

    function setMultiWlMerkleRoot(bytes32 _multiWlMerkleRoot) external onlyOwner {
        wlMultiMerkleRoot = _multiWlMerkleRoot;
    }

    function getMintPrice() public view whenPublicSaleActive returns (uint256) {
        uint256 elapsed = getElapsedSaleTime();
        if (elapsed >= publicSaleDuration) {
            return PS_MUTANT_ENDING_PRICE;
        } else {
            uint256 currentPrice = ((publicSaleDuration - elapsed) *
                publicSaleMutantStartingPrice) / publicSaleDuration;
            return
                currentPrice > PS_MUTANT_ENDING_PRICE
                    ? currentPrice
                    : PS_MUTANT_ENDING_PRICE;
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function mintFreeWhitelist(uint256 numMutants, bytes32[] calldata wlFreeMerkleProof, bytes32[] calldata wlFreeMultiMerkleProof) public payable nonReentrant {
        require(saleFreeWhitelistActive == true, "Free Whitelist Mint has not started");
        require(
            (MerkleProof.verify(wlFreeMerkleProof, wlFreeMerkleRoot, keccak256(abi.encodePacked(msg.sender))) == true || MerkleProof.verify(wlFreeMultiMerkleProof, wlFreeMultiMerkleRoot, keccak256(abi.encodePacked(msg.sender))) == true), 
            "The address is not whitelisted for the free mint");
        uint256 wl_max_mutant = WL_MAX_MUTANT_PURCHASE;
        if (MerkleProof.verify(wlFreeMultiMerkleProof, wlFreeMultiMerkleRoot, keccak256(abi.encodePacked(msg.sender))) == true) {
            wl_max_mutant = WL_MAX_MULTI_MUTANT_PURCHASE;
        }
        require(
            presaleAddresses[_msgSender()] + numMutants <= wl_max_mutant,
            "This would exceed the maximum allowed per whitelist"
        );
        for (uint256 i = 0; i < numMutants; i++) {
            uint256 mintIndex = numMutantsMinted;
            if (numMutantsMinted < MAX_MINTED_MUTANTS) {
                numMutantsMinted++;
                _safeMint(msg.sender, mintIndex);
                presaleAddresses[_msgSender()] += 1;
            }
        }
    }

    function mintWhitelist(uint256 numMutants, bytes32[] calldata wlMerkleProof, bytes32[] calldata wlMultiMerkleProof) public payable nonReentrant {
        require(saleWhitelistActive == true, "Whitelist Sale has not started");
        require(numMutants > 0, "Must mint at least one mutant");
        require(
            (MerkleProof.verify(wlMerkleProof, wlMerkleRoot, keccak256(abi.encodePacked(msg.sender))) == true || MerkleProof.verify(wlMultiMerkleProof, wlMultiMerkleRoot, keccak256(abi.encodePacked(msg.sender))) == true), 
            "The address is not whitelisted");
        uint256 wl_max_mutant = WL_MAX_MUTANT_PURCHASE;
        if (MerkleProof.verify(wlMultiMerkleProof, wlMultiMerkleRoot, keccak256(abi.encodePacked(msg.sender))) == true) {
            wl_max_mutant = WL_MAX_MULTI_MUTANT_PURCHASE;
        }
        require(
            presaleAddresses[_msgSender()] + numMutants <= wl_max_mutant,
            "This would exceed the maximum allowed per whitelist"
        );
        uint256 costToMint = WL_PRICE * numMutants;
        require(costToMint <= msg.value, "Ether value sent is not correct");
        for (uint256 i = 0; i < numMutants; i++) {
            uint256 mintIndex = numMutantsMinted;
            if (numMutantsMinted < MAX_MINTED_MUTANTS) {
                numMutantsMinted++;
                _safeMint(msg.sender, mintIndex);
                presaleAddresses[_msgSender()] += 1;
            }
        }
    }

    function mintMutants(uint256 numMutants)
        external
        payable
        whenPublicSaleActive
        nonReentrant
    {
        require(
            numMutantsMinted + numMutants <= MAX_MINTED_MUTANTS,
            "Minting would exceed max supply"
        );
        require(numMutants > 0, "Must mint at least one mutant");
        require(
            numMutants <= PS_MAX_MUTANT_PURCHASE,
            "Requested number exceeds maximum"
        );

        uint256 costToMint = getMintPrice() * numMutants;
        require(costToMint <= msg.value, "Ether value sent is not correct");
        
        if (mintedMutantsStartingIndex == 0) {
            collectionStartingIndexBlock = block.number;
        }

        for (uint256 i = 0; i < numMutants; i++) {
            uint256 mintIndex = numMutantsMinted;
            if (numMutantsMinted < MAX_MINTED_MUTANTS) {
                numMutantsMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }

        if (msg.value > costToMint) {
            Address.sendValue(payable(msg.sender), msg.value - costToMint);
        }
    }

    function isApeEligibleForSerumMutation(uint256 apeId) public view returns (bool) {
        // Exclude Legendary Grandpa Apes
        for (uint256 i = 0; i < legendaryGrandpas.length; i++) {
            if (apeId == legendaryGrandpas[i]) {
                return false;
            }
        }
        return true;
    }

    
    function mutateApeWithSerum(uint256 serumTypeId, uint256 apeId)
        external
        nonReentrant
    {
        require(serumMutationActive, "Serum Mutation is not active");
        require(
            gacc.ownerOf(apeId) == msg.sender,
            "Must own the ape you're attempting to mutate"
        );
        require(
            gasc.balanceOf(msg.sender, serumTypeId) > 0,
            "Must own at least one of this serum type to mutate"
        );
        require(isApeEligibleForSerumMutation(apeId), 
        "Grandpa is not eligible for mutation"
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

        gasc.burnSerumForAddress(serumTypeId, msg.sender);
        _safeMint(msg.sender, mutantId);
    }

    function mutateApeWithoutSerum(uint256 apeId)
        external
        nonReentrant
    {
        require(serumMutationActive, "Serum Mutation is not active");
        require(
            gacc.ownerOf(apeId) == msg.sender,
            "Must own the ape you're attempting to mutate"
        );
        require(
            !isApeEligibleForSerumMutation(apeId), 
            "A serum is required for this Grandpa"
        );

        uint256 mutantId;
        mutantId = getLegendaryMutantId(apeId);
        require(
            !_exists(mutantId),
            "Ape already mutated with this type of serum"
        );
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

    function getLegendaryMutantId(uint256 apeId)
        internal
        pure
        returns (uint256)
    {
        return (apeId * NUM_MUTANT_TYPES) + 1 + SERUM_MUTATION_OFFSET;
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

    function apesMinted() external view returns (uint256) {
        return numMutantsMinted;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function toggleFreeWhiteListSaleActive() external onlyOwner {
        saleFreeWhitelistActive = !saleFreeWhitelistActive;
    }

    function toggleWhiteListSaleActive() external onlyOwner {
        saleWhitelistActive = !saleWhitelistActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function toggleSerumMutationActive() external onlyOwner {
        serumMutationActive = !serumMutationActive;
    }

    function calculateStartingIndex(uint256 blockNumber, uint256 collectionSize)
        internal
        view
        returns (uint256)
    {
        return uint256(blockhash(blockNumber)) % collectionSize;
    }
    
    function setStartingIndices() external startingIndicesNotSet {
        require(
            collectionStartingIndexBlock != 0,
            "Starting index block must be set"
        );
        uint256 elapsed = getElapsedSaleTime();
        require(
            elapsed >= publicSaleDuration && publicSaleStartTime > 0,
            "Invalid setStartingIndices conditions"
        );

        mintedMutantsStartingIndex = calculateStartingIndex(
            collectionStartingIndexBlock,
            MAX_MINTED_MUTANTS
        );

        megaMutantsStartingIndex = calculateStartingIndex(
            collectionStartingIndexBlock,
            NUM_MEGA_MUTANTS
        );
        
        if ((block.number - collectionStartingIndexBlock) > 255) {
            mintedMutantsStartingIndex = calculateStartingIndex(
                block.number - 1,
                MAX_MINTED_MUTANTS
            );

            megaMutantsStartingIndex = calculateStartingIndex(
                block.number - 1,
                NUM_MEGA_MUTANTS
            );
        }

        // Prevent default sequence
        if (mintedMutantsStartingIndex == 0) {
            mintedMutantsStartingIndex++;
        }
        if (megaMutantsStartingIndex == 0) {
            megaMutantsStartingIndex++;
        }

        emit StartingIndicesSet(
            mintedMutantsStartingIndex,
            megaMutantsStartingIndex
        );
    }
}