// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@theappstudio/solidity/contracts/utils/OnChain.sol";
import "@theappstudio/solidity/contracts/utils/Randomization.sol";
import "../interfaces/IBear3TraitProvider.sol";
import "../interfaces/ICubTraitProvider.sol";
import "../utils/BearRenderTech.sol";
import "../utils/TwoBitBears3Errors.sol";
import "./TwoBitCubs.sol";

/// @title TwoBitBears3
contract TwoBitBears3 is ERC721, IBear3TraitProvider, IERC721Enumerable, Ownable {

    /// @dev Reference to the BearRenderTech contract
    IBearRenderTech private immutable _bearRenderTech;

    /// @dev Stores the cubs Adult Age so that it doesn't need to be queried for every mint
    uint256 private immutable _cubAdultAge;

    /// @dev Precalculated eligibility for cubs
    uint256[] private _cubEligibility;

    /// @dev Stores bear token ids that have already minted gen 4
    mapping(uint256 => bool) private _generation4Claims;

    /// @dev The contract for Gen 4
    address private _gen4Contract;

    /// @dev Stores cub token ids that have already mated
    mapping(uint256 => bool) private _matedCubs;

    /// @dev Seed for randomness
    uint256 private _seed;

    /// @dev Array of TokenIds to DNA
    uint256[] private _tokenIdsToDNA;

    /// @dev Reference to the TwoBitCubs contract
    TwoBitCubs private immutable _twoBitCubs;

    /// Look...at these...Bears
    constructor(uint256 seed, address renderTech, address twoBitCubs) ERC721("TwoBitBears3", "TB3") {
        _seed = seed;
        _bearRenderTech = IBearRenderTech(renderTech);
        _twoBitCubs = TwoBitCubs(twoBitCubs);
        _cubAdultAge = _twoBitCubs.ADULT_AGE();
    }

    /// Applies calculated slots of gen 2 eligibility to reduce gas
    function applySlots(uint256[] calldata slotIndices, uint256[] calldata slotValues) external onlyOwner {
        for (uint i = 0; i < slotIndices.length; i++) {
            uint slotIndex = slotIndices[i];
            uint slotValue = slotValues[i];
            if (slotIndex >= _cubEligibility.length) {
                while (slotIndex > _cubEligibility.length) {
                    _cubEligibility.push(0);
                }
                _cubEligibility.push(slotValue);
            } else if (_cubEligibility[slotIndex] != slotValue) {
                _cubEligibility[slotIndex] = slotValue;
            }
        }
    }

    /// Assigns the Gen 4 contract address for message caller verification
    function assignGen4(address gen4Contract) external onlyOwner {
        if (gen4Contract == address(0)) revert InvalidAddress();
        _gen4Contract = gen4Contract;
    }

    /// @inheritdoc IBear3TraitProvider
    function bearTraits(uint256 tokenId) external view onlyWhenExists(tokenId) returns (IBear3Traits.Traits memory) {
        return _traitsForToken(tokenId);
    }

    /// Calculates the current values for a slot
    function calculateSlot(uint256 slotIndex, uint256 totalTokens) external view onlyOwner returns (uint256 slotValue) {
        uint tokenStart = slotIndex * 32;
        uint tokenId = tokenStart + 32;
        if (tokenId > totalTokens) {
            tokenId = totalTokens;
        }
        uint adults = 0;
        do {
            tokenId -= 1;
            slotValue = (slotValue << 8) | _getEligibility(tokenId);
            if (slotValue >= 0x80) {
                adults++;
            }
        } while (tokenId > tokenStart);
        if (adults == 0 || (slotIndex < _cubEligibility.length && slotValue == _cubEligibility[slotIndex])) {
            slotValue = 0; // Reset because there's nothing worth writing
        }
    }

    /// Marks the Gen 3 Bear as having minted a Gen 4 Bear
    function claimGen4(uint256 tokenId) external onlyWhenExists(tokenId) {
        if (_gen4Contract == address(0) || _msgSender() != _gen4Contract) revert InvalidCaller();
        _generation4Claims[tokenId] = true;
    }

    /// @notice For easy import into MetaMask
    function decimals() external pure returns (uint256) {
        return 0;
    }

    /// @inheritdoc IBear3TraitProvider
    function hasGen2Mated(uint256 tokenId) external view returns (bool) {
        return _matedCubs[tokenId];
    }

    /// @inheritdoc IBear3TraitProvider
    function generation4Claimed(uint256 tokenId) external view onlyWhenExists(tokenId) returns (bool) {
        return _generation4Claims[tokenId];
    }

    function slotParameters() external view onlyOwner returns (uint256 totalSlots, uint256 totalTokens) {
        totalTokens = _twoBitCubs.totalSupply();
        totalSlots = 1 + totalTokens / 32;
    }

    /// Exposes the raw image SVG to the world, for any applications that can take advantage
    function imageSVG(uint256 tokenId) external view returns (string memory) {
        return string(_imageBytes(tokenId));
    }

    /// Exposes the image URI to the world, for any applications that can take advantage
    function imageURI(uint256 tokenId) external view returns (string memory) {
        return string(OnChain.svgImageURI(_imageBytes(tokenId)));
    }

    /// Mints the provided quantity of TwoBitBear3 tokens
    /// @param parentOne The first gen 2 bear parent, which also determines the mood
    /// @param parentTwo The second gen 2 bear parent
    function mateBears(uint256 parentOne, uint256 parentTwo) external {
        // Check eligibility
        if (_matedCubs[parentOne]) revert ParentAlreadyMated(parentOne);
        if (_matedCubs[parentTwo]) revert ParentAlreadyMated(parentTwo);
        if (_twoBitCubs.ownerOf(parentOne) != _msgSender()) revert ParentNotOwned(parentOne);
        if (_twoBitCubs.ownerOf(parentTwo) != _msgSender()) revert ParentNotOwned(parentTwo);
        uint parentOneInfo = _getEligibility(parentOne);
        uint parentTwoInfo = _getEligibility(parentTwo);
        uint parentOneSpecies = parentOneInfo & 0x03;
        if (parentOne == parentTwo || parentOneSpecies != (parentTwoInfo & 0x03)) revert InvalidParentCombination();
        if (parentOneInfo < 0x80) revert ParentTooYoung(parentOne);
        if (parentTwoInfo < 0x80) revert ParentTooYoung(parentTwo);
        // Prepare mint
        _matedCubs[parentOne] = true;
        _matedCubs[parentTwo] = true;
        uint seed = Randomization.randomSeed(_seed);
        // seed (208) | parent one (16) | parent two (16) | species (8) | mood (8)
        uint rawDna = (seed << 48) | (parentOne << 32) | (parentTwo << 16) | (parentOneSpecies << 8) | ((parentOneInfo & 0x7F) >> 2);
        uint tokenId = _tokenIdsToDNA.length;
        _tokenIdsToDNA.push(rawDna);
        _seed = seed;
        _safeMint(_msgSender(), tokenId, ""); // Reentrancy is possible here
    }

    /// @notice Returns expected gas usage based on selected parents, with a small buffer for safety
    /// @dev Does not check for ownership or whether parents have already mated
    function matingGas(address minter, uint256 parentOne, uint256 parentTwo) external view returns (uint256 result) {
        result = 146000; // Lowest gas cost to mint
        if (_tokenIdsToDNA.length == 0) {
            result += 16500;
        }
        if (balanceOf(minter) == 0) {
            result += 17500;
        }
        // Fetching eligibility of parents will cost additional gas
        uint fetchCount = 0;
        if (_eligibility(parentOne) < 0x80) {
            result += 47000;
            if (uint(_twoBitCubs.traitsV1(parentOne).mood) >= 4) {
                result += 33500;
            }
            fetchCount += 1;
        }
        if (_eligibility(parentTwo) < 0x80) {
            result += 47000;
            if (uint(_twoBitCubs.traitsV1(parentTwo).mood) >= 4) {
                result += 33500;
            }
            fetchCount += 1;
        }
        // There's some overhead for a single fetch
        if (fetchCount == 1) {
            result += 10000;
        }
    }

    /// Prevents a function from executing if the tokenId does not exist
    modifier onlyWhenExists(uint256 tokenId) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        _;
    }

    /// @inheritdoc IBear3TraitProvider
    function scarColors(uint256 tokenId) external view onlyWhenExists(tokenId) returns (IBear3Traits.ScarColor[] memory) {
        IBear3Traits.Traits memory traits = _traitsForToken(tokenId);
        return _bearRenderTech.scarsForTraits(traits);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc IERC721Enumerable
    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < this.totalSupply(), "global index out of bounds");
        return index; // Burning is not exposed by this contract so we can simply return the index
    }

    /// @inheritdoc IERC721Enumerable
    /// @dev This implementation is for the benefit of web3 sites -- it is extremely expensive for contracts to call on-chain
    function tokenOfOwnerByIndex(address owner_, uint256 index) external view returns (uint256 tokenId) {
        require(index < ERC721.balanceOf(owner_), "owner index out of bounds");
        for (uint tokenIndex = 0; tokenIndex < _tokenIdsToDNA.length; tokenIndex++) {
            // Use _exists() to avoid a possible revert when accessing OpenZeppelin's ownerOf(), despite not exposing _burn()
            if (_exists(tokenIndex) && ownerOf(tokenIndex) == owner_) {
                if (index == 0) {
                    tokenId = tokenIndex;
                    break;
                }
                index--;
            }
        }
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) public view override onlyWhenExists(tokenId) returns (string memory) {
        IBear3Traits.Traits memory traits = _traitsForToken(tokenId);
        return string(OnChain.tokenURI(_bearRenderTech.metadata(traits, tokenId)));
    }

    /// @inheritdoc IERC721Enumerable
    function totalSupply() external view returns (uint256) {
        return _tokenIdsToDNA.length; // We don't expose _burn() so the .length suffices
    }

    function _eligibility(uint256 parent) private view returns (uint8 result) {
        uint slotIndex = parent / 32;
        if (slotIndex < _cubEligibility.length) {
            result = uint8(_cubEligibility[slotIndex] >> ((parent % 32) * 8));
        }
    }

    function _getEligibility(uint256 parent) private view returns (uint8 result) {
        // Check the precalculated eligibility
        result = _eligibility(parent);
        if (result < 0x80) {
            // We need to go get the latest information from the Cubs contract
            result = _packedInfo(_twoBitCubs.traitsV1(parent));
        }
    }

    function _imageBytes(uint256 tokenId) private view onlyWhenExists(tokenId) returns (bytes memory) {
        IBear3Traits.Traits memory traits = _traitsForToken(tokenId);
        return _bearRenderTech.createSvg(traits, tokenId);
    }

    function _traitsForToken(uint256 tokenId) private view returns (IBear3Traits.Traits memory traits) {
        uint dna = _tokenIdsToDNA[tokenId];
        traits.mood = IBear3Traits.MoodType(dna & 0xFF);
        traits.species = IBear3Traits.SpeciesType((dna >> 8) & 0xFF);
        traits.firstParentTokenId = uint16(dna >> 16) & 0xFFFF;
        traits.secondParentTokenId = uint16(dna >> 32) & 0xFFFF;
        traits.nameIndex = uint8((dna >> 48) & 0xFF);
        traits.familyIndex = uint8((dna >> 56) & 0xFF);
        traits.background = IBear3Traits.BackgroundType(((dna >> 64) & 0xFF) % 3);
        traits.gen4Claimed = _generation4Claims[tokenId];
        traits.genes = uint176(dna >> 80);
    }

    function _packedInfo(ICubTraits.TraitsV1 memory traits) private view returns (uint8 info) {
        info |= uint8(traits.species);
        info |= uint8(traits.mood) << 2;
        if (traits.age >= _cubAdultAge) {
            info |= 0x80;
        }
    }
}