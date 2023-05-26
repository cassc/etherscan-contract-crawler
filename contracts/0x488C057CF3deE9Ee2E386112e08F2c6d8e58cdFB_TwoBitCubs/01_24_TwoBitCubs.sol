// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "../interfaces/ICubTraitProvider.sol";
import "../utils/CubComposition.sol";
import "../utils/TwoBitCubErrors.sol";
import "./TwoBitHoney.sol";

/// @title TwoBitCubs
contract TwoBitCubs is ERC721Enumerable, ICubTraitProvider, Ownable, ReentrancyGuard {
    /*
                          :=====-     .:------::.    :=====:
                        :**++++++#+=--:.      ..:-==#+++++++*=
                       -#******#=.                  .=*#*****#+
                       +*****#=                        :*#****%
                       -#**#*.                           +#***+
                        -###    .=+***=.       =+**+=:    +##=
                          #.  .=*******+      -*******+:   #.
                         -=  .+**%=+%*+:      .+*#+=%***:  :+
                         +.  +***##%#+  .-::-:  =#%##****.  #
                        :+   *******+   -%%%%+   =*******:  -=
                        *.   =******. :- .*#: .=  +*****+    #
                        #.    -+++-.   +%%%%%%#.   -=++-     *:
                        *-.            .#*++*%-             :#
                     =*###-:.            -==-.           .:-*:
                    -#****#*=-:..                    ..::=+=
                    .#*******#**+=-:::::......:::::-==+*#:
                     :##**********####**********####****#*
                       =##*****#******************#******#:
                         :=*###%*****************#+******%:
                             .=*:--===+++++++++#*+******##
                              -=              -*+*******%:
                           -=+****=           #+******#%*=-.
                         =*---+****#.         *#****###*=--++
                        =*.    +***#+          -*####**.    ++
                        +*     =***#*            =#***+     =*
                        .#=.  :***#%*--::::::::--+%#***-.  -#:
                         .+#**##*+-.:-==++++++==-:.-=*###*#+.
                             .............................
    */
    using Strings for uint256;

    /// @dev Price to adopt one cub
    uint256 public constant ADOPTION_PRICE = 0.15 ether;

    /// @dev The number of blocks until a growing cub becomes an adult (roughly 1 week)
    uint256 public constant ADULT_AGE = 44000;

    /// @dev Maximum cubs that will be minted (adopted and bread)
    uint256 public constant MAX_CUBS = 7500; // We expect ~4914 cubs, but are prepared for 7500 in deference to Honey holders, in case there are somehow lots of twins and triplets

    /// @dev Maximum quantity of cubs that can be adopted at once
    uint256 public constant MAX_ADOPT_QUANTITY = 10;

    /// @dev Maximum quantity of cubs that can be adopted in total
    uint256 public constant TOTAL_ADOPTIONS = 2500;

    /// @dev Reference to the TwoBitHoney contract
    TwoBitHoney internal immutable _twoBitHoney;

    /// @dev Counter for adopted Cubs
    uint256 private _adoptedCubs;

    /// @dev Counter for token Ids
    uint256 private _tokenCounter;

    /// @dev Seed for randomness
    uint256 private _seed;

    /// @dev The block number when adoption and mating are available
    uint256 private _wenMint;

    /// @dev Enables/disables the reveal
    bool private _wenReveal;

    /// @dev Mapping of TokenIds to Cub DNA
    mapping(uint256 => ICubTraits.DNA) private _tokenIdsToCubDNA;

    /// @dev Mapping of TokenIds to Cub growth
    mapping(uint256 => uint256) private _tokenIdsToBirthday;

    constructor(address twoBitHoney) ERC721("TwoBitCubs", "TBC") {
        _seed = uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number-1), uint24(block.number))));
        _twoBitHoney = TwoBitHoney(twoBitHoney);
        _wenMint = 0;
        _wenReveal = false;
    }

    /// @dev Celebrate and marvel at the astonishing detail in each TwoBitBear Cub
    function adoptCub(uint256 quantity) public payable nonReentrant {
        if (_wenMint == 0 || block.number < _wenMint) revert NotOpenForMinting();
        if (quantity == 0 || quantity > MAX_ADOPT_QUANTITY) revert InvalidAdoptionQuantity();
        if (quantity > remainingAdoptions()) revert AdoptionLimitReached();
        if (msg.value < ADOPTION_PRICE * quantity) revert InvalidPriceSent();
        _mintCubs(0xFFFF, 0xFFFF, quantity);
        _adoptedCubs += quantity;
    }

    /// @notice For easy import into MetaMask 
    function decimals() public pure returns (uint256) {
        return 0;
    }

    /// @inheritdoc ICubTraitProvider
    function familyForTraits(ICubTraits.TraitsV1 memory traits) public pure override returns (string memory) {
        string[18] memory families = ["Maeda", "Buffett", "Milonakis", "Petty", "VanDough", "Dammrich", "Pleasr", "Farmer", "Evan Dennis", "Hobbs", "Viselner", "Ghxsts", "Greenawalt", "Capacity", "Sheridan", "Ong", "Orrell", "Kong"];
        return families[traits.familyIndex];
    }

    /// Mate some bears
    /// @dev Throws if the parent TwoBitBear token IDs are not valid or not owned by the caller, or if the honey balance is insufficient
    function mateBears(uint256 parentBearOne, uint256 parentBearTwo) public nonReentrant {
        if (_wenMint == 0 || block.number < _wenMint) revert NotOpenForMinting();
        if (parentBearOne == parentBearTwo || _twoBitHoney.bearSpecies(parentBearOne) != _twoBitHoney.bearSpecies(parentBearTwo)) revert InvalidParentCombination();
        if (!_twoBitHoney.ownsBear(msg.sender, parentBearOne)) revert BearNotOwned(parentBearOne);
        if (!_twoBitHoney.ownsBear(msg.sender, parentBearTwo)) revert BearNotOwned(parentBearTwo);
        _twoBitHoney.burnHoneyForAddress(msg.sender); // Errors here will bubble up

        uint8 siblingSeed = uint8(_seed % 256);
        uint256 quantity = 1 + CubComposition.randomIndexFromPercentages(siblingSeed, _cubSiblingPercentages());
        _mintCubs(uint16(parentBearOne), uint16(parentBearTwo), quantity);
    }

    /// Wakes a cub from hibernation so that it will begin growing
    /// @dev Throws if msg sender is not the owner of the cub, or if the cub's aging has already begun
    function wakeCub(uint256 tokenId) public nonReentrant {
        if (msg.sender != ownerOf(tokenId)) revert CubNotOwned(tokenId);
        if (_tokenIdsToBirthday[tokenId] > 0) revert AgingAlreadyStarted();
        _tokenIdsToBirthday[tokenId] = block.number;
    }

    /// @inheritdoc ICubTraitProvider
    function isAdopted(ICubTraits.DNA memory dna) public pure override returns (bool) {
        return dna.firstParentTokenId == 0xFFFF; // || dna.secondParentTokenId == 0xFFFF;
    }

    /// @inheritdoc ICubTraitProvider
    function moodForType(ICubTraits.CubMoodType moodType) public pure override returns (string memory) {
        string[14] memory moods = ["Happy", "Hungry", "Sleepy", "Grumpy", "Cheerful", "Excited", "Snuggly", "Confused", "Ravenous", "Ferocious", "Hangry", "Drowsy", "Cranky", "Furious"];
        return moods[uint256(moodType)];
    }

    /// @inheritdoc ICubTraitProvider
    function moodFromParents(uint256 firstParentTokenId, uint256 secondParentTokenId) public view returns (ICubTraits.CubMoodType) {
        IBearable.BearMoodType moodOne = _twoBitHoney.bearMood(firstParentTokenId);
        IBearable.BearMoodType moodTwo = _twoBitHoney.bearMood(secondParentTokenId);
        (uint8 smaller, uint8 larger) = moodOne < moodTwo ? (uint8(moodOne), uint8(moodTwo)) : (uint8(moodTwo), uint8(moodOne));
        if (smaller == 0) {
            return ICubTraits.CubMoodType(4 + larger - smaller);
        } else if (smaller == 1) {
            return ICubTraits.CubMoodType(8 + larger - smaller);
        } else if (smaller == 2) {
            return ICubTraits.CubMoodType(11 + larger - smaller);
        }
        return ICubTraits.CubMoodType(13 + larger - smaller);
    }

    /// @inheritdoc ICubTraitProvider
    function nameForTraits(ICubTraits.TraitsV1 memory traits) public pure override returns (string memory) {
        string[18] memory names = ["Rhett", "Clon", "2476", "Tank", "Gremplin", "eBoy", "Pablo", "Chuck", "Justin", "MouseDev", "Pranksy", "Rik", "Joshua", "Racecar", "0xInuarashi", "OhhShiny", "Gary", "Kilo"];
        return names[traits.nameIndex];
    }

    /// Returns the remaining number of adoptions available
    function remainingAdoptions() public view returns (uint256) {
        return TOTAL_ADOPTIONS - _adoptedCubs;
    }

    /// @inheritdoc ICubTraitProvider
    function speciesForType(ICubTraits.CubSpeciesType speciesType) public pure override returns (string memory) {
        string[4] memory species = ["Brown", "Black", "Polar", "Panda"];
        return species[uint256(speciesType)];
    }

    /// @inheritdoc ICubTraitProvider
    function traitsV1(uint256 tokenId) public view override returns (ICubTraits.TraitsV1 memory traits) {
        if (!_exists(tokenId)) revert NonexistentCub();
        if (!_wenReveal) revert NotYetRevealed();

        ICubTraits.DNA memory dna = _tokenIdsToCubDNA[tokenId];
        bytes memory genes = abi.encodePacked(dna.genes); // 32 Bytes
        uint256 increment = (tokenId % 20) + 1;
        uint256 birthday = _tokenIdsToBirthday[tokenId];
        if (birthday > 0) {
            traits.age = block.number - birthday;
        }
        if (isAdopted(dna)) {
            traits.species = ICubTraits.CubSpeciesType(CubComposition.randomIndexFromPercentages(uint8(genes[9 + increment]), _adoptedPercentages()));
            traits.topColor = CubComposition.colorTopFromRandom(genes, 6 + increment, 3 + increment, 4 + increment, traits.species);
            traits.bottomColor = CubComposition.colorBottomFromRandom(genes, 5 + increment, 7 + increment, 1 + increment, traits.species);
            traits.mood = ICubTraits.CubMoodType(CubComposition.randomIndexFromPercentages(uint8(genes[increment]), _adoptedPercentages()));
        } else {
            traits.species = ICubTraits.CubSpeciesType(uint8(_twoBitHoney.bearSpecies(dna.firstParentTokenId)));
            traits.topColor = CubComposition.randomColorFromColors(_twoBitHoney.bearTopColor(dna.firstParentTokenId), _twoBitHoney.bearTopColor(dna.secondParentTokenId), genes, 6 + increment, 3 + increment);
            traits.bottomColor = CubComposition.randomColorFromColors(_twoBitHoney.bearBottomColor(dna.firstParentTokenId), _twoBitHoney.bearBottomColor(dna.secondParentTokenId), genes, 5 + increment, 7 + increment);
            traits.mood = moodFromParents(dna.firstParentTokenId, dna.secondParentTokenId);
        }
        traits.nameIndex = uint8(uint8(genes[2 + increment]) % 18);
        traits.familyIndex = uint8(uint8(genes[8 + increment]) % 18);
    }

    /// @dev Wen the world is ready
    function revealCubs() public onlyOwner {
        _wenReveal = true;
    }

    /// @dev Enable adoption
    function setMintingBlock(uint256 wenMint) public onlyOwner {
        _wenMint = wenMint;
    }

    /// @dev Exposes the raw image SVG to the world, for any applications that can take advantage
    function imageSVG(uint256 tokenId) public view returns (string memory) {
        ICubTraits.TraitsV1 memory traits = traitsV1(tokenId);        
        return string(CubComposition.createSvg(traits, ADULT_AGE));
    }

    /// @dev Exposes the image URI to the world, for any applications that can take advantage
    function imageURI(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(_baseImageURI(), Base64.encode(bytes(imageSVG(tokenId)))));
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentCub();
        return string(abi.encodePacked(_baseURI(), Base64.encode(_metadataForToken(tokenId))));
    }

    /// @notice Send funds from sales to the team
    function withdrawAll() public payable onlyOwner {
        payable(0xDC009bCb27c70A6Da5A083AA8C606dEB26806a01).transfer(address(this).balance);
    }

    function _adoptedPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](3);
        array[0] = 54; // 54% Brown/Happy
        array[1] = 30; // 30% Black/Hungry
        array[2] = 15; // 15% Polar/Sleepy
        return array; // 1% Panda/Grumpy
    }

    function _attributesFromTraits(ICubTraits.TraitsV1 memory traits) private pure returns (bytes memory) {
        return abi.encodePacked(
            "trait_type\":\"Species\",\"value\":\"", speciesForType(traits.species),
            _attributePair("Mood", moodForType(traits.mood)),
            _attributePair("Name", nameForTraits(traits)),
            _attributePair("Family", familyForTraits(traits)),
            _attributePair("Realistic Head Fur", SVG.svgColorWithType(traits.topColor, ISVG.ColorType.None)),
            _attributePair("Realistic Body Fur", SVG.svgColorWithType(traits.bottomColor, ISVG.ColorType.None))
        );
    }

    function _attributePair(string memory name, string memory value) private pure returns (bytes memory) {
        return abi.encodePacked("\"},{\"trait_type\":\"", name, "\",\"value\":\"", value);
    }

    function _baseImageURI() private pure returns (string memory) {
        return "data:image/svg+xml;base64,";
    }

    function _baseURI() internal pure virtual override returns (string memory) {
        return "data:application/json;base64,";
    }

    // @dev should return roughly 2414 mated cubs
    function _cubSiblingPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](2);
        array[0] = 70; // 70% single cub
        array[1] = 25; // 25% twin cubs
        return array; // 5% triplet cubs
    }

    function _metadataForToken(uint256 tokenId) private view returns (bytes memory) {
        if (_wenReveal) {
            ICubTraits.DNA memory dna = _tokenIdsToCubDNA[tokenId];
            ICubTraits.TraitsV1 memory traits = traitsV1(tokenId);
            return abi.encodePacked(
                "{\"name\":\"",
                    _nameFromTraits(traits, tokenId),
                "\",\"description\":\"",
                    moodForType(traits.mood), " ", speciesForType(traits.species),
                "\",\"attributes\":[{\"",
                    _attributesFromTraits(traits), _parentAttributesFromDNA(dna),
                "\"}],\"image\":\"",
                    _baseImageURI(), Base64.encode(CubComposition.createSvg(traits, ADULT_AGE)),
                "\"}"
            );
        }
        return abi.encodePacked(
            "{\"name\":\"Rendering Cub #", tokenId.toString(), "...\",\"description\":\"Unrevealed\",\"image\":\"ipfs://Qmc5YVyzKZ6D3wjqLFcfUBPtp9yh7NKxst2M2N3nDFdKDZ\"}"
        );
    }

    function _mintCubs(uint16 parentBearOne, uint16 parentBearTwo, uint256 quantity) private {
        if (_tokenCounter + quantity > MAX_CUBS) revert NoMoreCubs();
        uint256 localSeed = _seed; // Write to _seed only at the end of this function to reduce gas
        uint256 tokenId = _tokenCounter;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, tokenId);
            _tokenIdsToCubDNA[tokenId] = ICubTraits.DNA(_seed, parentBearOne, parentBearTwo);
            tokenId += 1;
            if (i + 1 < quantity) {
                // Perform a light-weight seed adjustment to save gas
                localSeed = uint256(keccak256(abi.encodePacked(localSeed >> 1)));
            }
        }
        _tokenCounter = tokenId;
        // The sender's transaction now salts the next cubs' randomness
        _seed = uint256(keccak256(abi.encodePacked(localSeed >> 1, msg.sender, blockhash(block.number-1), uint24(block.number))));
    }

    function _nameFromTraits(ICubTraits.TraitsV1 memory traits, uint256 tokenId) private pure returns (string memory) {
        // TwoBitCubs will have 0-based user-facing numbers, to reduce confusion
        string memory speciesSuffix = traits.age < ADULT_AGE ? " Cub #" : " Bear #"; // Adult cubs no longer say 'Cub'
        return string(abi.encodePacked(nameForTraits(traits), " ", familyForTraits(traits), " the ", moodForType(traits.mood), " ", speciesForType(traits.species), speciesSuffix, tokenId.toString()));
    }

    function _parentAttributesFromDNA(ICubTraits.DNA memory dna) private pure returns (bytes memory) {
        if (dna.firstParentTokenId == 0xFFFF) {
            return "";
        }
        // TwoBitBears was 0-based for id's, but 1-based for user-facing numbers (like many apps). Ensure we display user-facing numbers in the attributes
        (uint256 smaller, uint256 larger) = dna.firstParentTokenId < dna.secondParentTokenId ?
            (dna.firstParentTokenId, dna.secondParentTokenId) :
            (dna.secondParentTokenId, dna.firstParentTokenId);
        string memory parents = string(abi.encodePacked("#", (smaller + 1).toString(), " & #", (larger + 1).toString()));
        return _attributePair("Parents", parents);
    }
}