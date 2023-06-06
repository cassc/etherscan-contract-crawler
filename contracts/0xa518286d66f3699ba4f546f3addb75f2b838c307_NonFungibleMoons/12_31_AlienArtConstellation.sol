// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DynamicNftRegistryInterface} from "../../interfaces/dynamicNftRegistry/DynamicNftRegistryInterface.sol";
import {AlienArtBase} from "../../interfaces/alienArt/AlienArtBase.sol";
import {MoonImageConfig, MoonImageColors} from "../../moon/MoonStructs.sol";
import {AlienArtConstellationEventsAndErrors} from "./AlienArtConstellationEventsAndErrors.sol";
import {ConstellationLib} from "./ConstellationLib.sol";
import {IERC165} from "../../interfaces/ext/IERC165.sol";
import {IERC721} from "../../interfaces/ext/IERC721.sol";
import {ERC1155} from "../../ext/ERC1155.sol";
import {Ownable} from "../../ext/Ownable.sol";
import {Utils} from "../../utils/Utils.sol";
import {Traits} from "../../utils/Traits.sol";
import {LibPRNG} from "../../utils/LibPRNG.sol";
import {svg} from "./SVG.sol";

/// @title AlienArtConstellation
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice On-chain constellation NFTs that conform to the Alien Art (AlienArtBase) on-chain NFT composability standard and support swapping constellations between Non-Fungible Moon NFTs.
contract AlienArtConstellation is
    ERC1155,
    AlienArtBase,
    AlienArtConstellationEventsAndErrors,
    Ownable
{
    using LibPRNG for LibPRNG.PRNG;

    struct ConstellationParams {
        Constellation constellationType;
        // In degrees
        uint16 rotation;
        bool fluxConstellation;
    }

    enum Constellation {
        LITTLE_DIPPER,
        BIG_DIPPER,
        // Zodiac
        ARIES,
        PISCES,
        AQUARIUS,
        CAPRICORNUS,
        SAGITTARIUS,
        OPHIUCHUS,
        SCORPIUS,
        LIBRA,
        VIRGO,
        LEO,
        CANCER,
        GEMINI,
        TAURUS,
        NONE
    }

    // These constants ensure that Etherscan/etc can read the name and symbol for this contract
    string public constant name = "Constellations";
    string public constant symbol = "CLN";

    uint16 internal constant DEFAULT_VIEW_SIZE = 200;
    uint16 internal constant DEFAULT_MOON_RADIUS = 32;

    address internal moonAddress;

    mapping(uint256 => uint256) public moonTokenIdToConstellationTokenId;
    uint16 internal constant RANDOMNESS_FACTOR = 1337;

    address dynamicNftRegistryAddress;
    uint64 internal constant COOLDOWN_PERIOD = 120;

    /// @notice set moon address.
    /// @param _moonAddress moon address.
    function setMoonAddress(address _moonAddress) external onlyOwner {
        if (moonAddress != address(0)) {
            revert MoonAddressAlreadySet();
        }
        moonAddress = _moonAddress;
    }

    /// @notice swap constellation associated moon 1 with the constellation associated with moon 2.
    /// Both moons must be owned by the same user.
    /// @param moon1 moon 1 token id.
    /// @param moon2 moon 2 token id.
    function swapConstellations(uint256 moon1, uint256 moon2) external {
        // Checks

        // Check both moons are owned by this account
        if (
            IERC721(moonAddress).ownerOf(moon1) != msg.sender ||
            IERC721(moonAddress).ownerOf(moon2) != msg.sender
        ) {
            revert SwapMoonsOwnerMustBeMsgSender();
        }

        // Effects

        // Perform swap
        uint256 originalMoon1Constellation = moonTokenIdToConstellationTokenId[
            moon1
        ];
        moonTokenIdToConstellationTokenId[
            moon1
        ] = moonTokenIdToConstellationTokenId[moon2];
        moonTokenIdToConstellationTokenId[moon2] = originalMoon1Constellation;

        // Emit event indicating swap occurred
        emit SwapConstellations(
            msg.sender,
            moon1,
            moon2,
            moonTokenIdToConstellationTokenId[moon1],
            moonTokenIdToConstellationTokenId[moon2]
        );

        // Interactions
        if (dynamicNftRegistryAddress != address(0)) {
            // Call update token on zone registry (if defined) for both moons
            // and do not invalidate collection orders.
            DynamicNftRegistryInterface(dynamicNftRegistryAddress).updateToken(
                moonAddress,
                moon1,
                COOLDOWN_PERIOD,
                false
            );
            DynamicNftRegistryInterface(dynamicNftRegistryAddress).updateToken(
                moonAddress,
                moon2,
                COOLDOWN_PERIOD,
                false
            );
        }
    }

    /// @notice get constellation type that corresponds to a particular moon token id when the constellation is to be minted
    /// @param moonTokenId moon token id
    /// @return Constellation
    function getConstellationTypeForMoonTokenIdAtMint(uint256 moonTokenId)
        public
        view
        returns (Constellation)
    {
        LibPRNG.PRNG memory prng;
        prng.seed(
            keccak256(
                abi.encodePacked(
                    moonTokenId,
                    block.difficulty,
                    RANDOMNESS_FACTOR
                )
            )
        );

        uint256 randomFrom0To99 = prng.uniform(100);
        if (randomFrom0To99 <= 1) {
            // 2% chance of returning little dipper
            return Constellation.LITTLE_DIPPER;
        }
        if (randomFrom0To99 == 2) {
            // 1% chance of returning big dipper
            return Constellation.BIG_DIPPER;
        }

        // Length of zodiac constellation values and None is the value of the last enum - first zodiac constellation + 1 for the none value
        uint256 totalZodiacConstellations = uint256(Constellation.NONE) -
            uint256(Constellation.ARIES) +
            1;
        // Return any value from the zodiac constellations or None.
        return
            Constellation(
                prng.uniform(totalZodiacConstellations) +
                    uint256(Constellation.ARIES)
            );
    }

    /// @notice get art name for this alien art contract.
    /// @return art name.
    function getArtName() external pure override returns (string memory) {
        return name;
    }

    /// @notice get on-chain Constellation art image, adhering to Alien Art abstract class.
    /// @param tokenId moon token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return on-chain Constellation SVG.
    function getArt(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view override returns (string memory) {
        Constellation constellation = Constellation(
            moonTokenIdToConstellationTokenId[tokenId]
        );
        return
            getArtForConstellation(
                constellation,
                moonSeed,
                moonImageConfig,
                rotationInDegrees
            );
    }

    // For a given moon seed, returns bool indicating if flux constellation should be used, bool indicating if
    // moon color for star color should be used
    function getConstellationUseFluxAndUseMoonColor(bytes32 moonSeed)
        internal
        pure
        returns (bool, bool)
    {
        if (moonSeed == bytes32(0)) {
            // If moon seed is bytes32(0), return false for both use flux and use moon color for star color
            return (false, false);
        }
        LibPRNG.PRNG memory prng;
        prng.seed(moonSeed);
        return (prng.uniform(4) == 0, prng.uniform(20) == 0);
    }

    /// @notice get on-chain Constellation SVG.
    /// @param constellation constellation to get SVG for.
    /// @param moonSeed moon seed of moon mapping to constellation.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return Constellation SVG.
    function getArtForConstellation(
        Constellation constellation,
        bytes32 moonSeed,
        MoonImageConfig memory moonImageConfig,
        uint256 rotationInDegrees
    ) public pure returns (string memory) {
        (
            bool useFlux,
            bool useMoonColorForStarColor
        ) = getConstellationUseFluxAndUseMoonColor(moonSeed);
        return
            getConstellation(
                ConstellationParams({
                    constellationType: constellation,
                    rotation: uint16(rotationInDegrees),
                    fluxConstellation: useFlux
                }),
                moonImageConfig.viewWidth,
                moonImageConfig.viewHeight,
                useMoonColorForStarColor
                    ? moonImageConfig.colors.moon
                    : "#FDFD96",
                moonSeed
            );
    }

    /// @notice get traits for Constellation.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @return traits.
    function getTraits(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata,
        uint256
    ) external view override returns (string memory) {
        (
            bool useFlux,
            bool useMoonColorForStarColor
        ) = getConstellationUseFluxAndUseMoonColor(moonSeed);
        return
            string.concat(
                Traits.getTrait(
                    "Star brightness",
                    useFlux ? "Flux" : "Fixed",
                    true
                ),
                Traits.getTrait(
                    "Star color",
                    useMoonColorForStarColor ? "Moon" : "Classic",
                    true
                ),
                _getTraitForConstellation(
                    Constellation(moonTokenIdToConstellationTokenId[tokenId])
                )
            );
    }

    function _getTraitForConstellation(Constellation constellation)
        internal
        pure
        returns (string memory)
    {
        return
            Traits.getTrait(
                "Constellation",
                getConstellationTypeString(constellation),
                false
            );
    }

    function getConstellationTypeString(Constellation constellation)
        internal
        pure
        returns (string memory)
    {
        if (constellation == Constellation.LITTLE_DIPPER) {
            return "Little dipper";
        }
        if (constellation == Constellation.BIG_DIPPER) {
            return "Big dipper";
        }
        if (constellation == Constellation.ARIES) {
            return "Aries";
        }
        if (constellation == Constellation.PISCES) {
            return "Pisces";
        }
        if (constellation == Constellation.AQUARIUS) {
            return "Aquarius";
        }
        if (constellation == Constellation.CAPRICORNUS) {
            return "Capricornus";
        }
        if (constellation == Constellation.SAGITTARIUS) {
            return "Sagittarius";
        }
        if (constellation == Constellation.OPHIUCHUS) {
            return "Ophiuchus";
        }
        if (constellation == Constellation.SCORPIUS) {
            return "Scorpius";
        }
        if (constellation == Constellation.LIBRA) {
            return "Libra";
        }
        if (constellation == Constellation.VIRGO) {
            return "Virgo";
        }
        if (constellation == Constellation.LEO) {
            return "Leo";
        }
        if (constellation == Constellation.CANCER) {
            return "Cancer";
        }
        if (constellation == Constellation.GEMINI) {
            return "Gemini";
        }
        if (constellation == Constellation.TAURUS) {
            return "Taurus";
        }
        return "None";
    }

    function getConstellation(
        ConstellationParams memory constellation,
        uint256 rectWidth,
        uint256 rectHeight,
        string memory starColor,
        bytes32 moonSeed
    ) internal pure returns (string memory) {
        if (constellation.constellationType == Constellation.NONE) {
            return "";
        }

        ConstellationLib.GenerateConstellationParams
            memory params = ConstellationLib.GenerateConstellationParams(
                0,
                0,
                constellation.rotation,
                uint16(rectWidth) / 2,
                uint16(rectHeight) / 2,
                starColor,
                constellation.fluxConstellation,
                moonSeed
            );

        if (constellation.constellationType == Constellation.LITTLE_DIPPER) {
            params.x = 60;
            params.y = 150;
            return ConstellationLib.getLittleDipper(params);
        }
        if (constellation.constellationType == Constellation.BIG_DIPPER) {
            params.x = 89;
            params.y = 13;
            return ConstellationLib.getBigDipper(params);
        }
        if (constellation.constellationType == Constellation.ARIES) {
            params.x = 75;
            params.y = 40;
            return ConstellationLib.getAries(params);
        }
        if (constellation.constellationType == Constellation.PISCES) {
            params.x = 25;
            params.y = 147;
            return ConstellationLib.getPisces(params);
        }
        if (constellation.constellationType == Constellation.AQUARIUS) {
            params.x = 35;
            params.y = 156;
            return ConstellationLib.getAquarius(params);
        }
        if (constellation.constellationType == Constellation.CAPRICORNUS) {
            params.x = 35;
            params.y = 145;
            return ConstellationLib.getCapricornus(params);
        }
        if (constellation.constellationType == Constellation.SAGITTARIUS) {
            params.x = 35;
            params.y = 160;
            return ConstellationLib.getSagittarius(params);
        }
        if (constellation.constellationType == Constellation.OPHIUCHUS) {
            params.x = 35;
            params.y = 160;
            return ConstellationLib.getOphiuchus(params);
        }
        if (constellation.constellationType == Constellation.SCORPIUS) {
            params.x = 35;
            params.y = 140;
            return ConstellationLib.getScorpius(params);
        }
        if (constellation.constellationType == Constellation.LIBRA) {
            params.x = 75;
            params.y = 167;
            return ConstellationLib.getLibra(params);
        }
        if (constellation.constellationType == Constellation.VIRGO) {
            params.x = 15;
            params.y = 120;
            return ConstellationLib.getVirgo(params);
        }
        if (constellation.constellationType == Constellation.LEO) {
            params.x = 55;
            params.y = 165;
            return ConstellationLib.getLeo(params);
        }
        if (constellation.constellationType == Constellation.CANCER) {
            params.x = 110;
            params.y = 185;
            return ConstellationLib.getCancer(params);
        }
        if (constellation.constellationType == Constellation.GEMINI) {
            params.x = 75;
            params.y = 152;
            return ConstellationLib.getGemini(params);
        }
        if (constellation.constellationType == Constellation.TAURUS) {
            params.x = 67;
            params.y = 155;
            return ConstellationLib.getTaurus(params);
        }

        return "";
    }

    /// @notice get standalone Constellation, which is
    /// an on-chain Constellation SVG that can properly be rendered standalone (without being embedded in another SVG).
    /// @param constellation constellation.
    /// @param moonSeed moon seed of moon mapping to constellation.
    /// @param config moon image config.
    /// @return standalone Constellation SVG.
    function getStandaloneConstellation(
        Constellation constellation,
        bytes32 moonSeed,
        MoonImageConfig memory config
    ) public pure returns (string memory) {
        return
            svg.svgTag(
                string.concat(
                    svg.prop("xmlns", "http://www.w3.org/2000/svg"),
                    svg.prop("width", "400"),
                    svg.prop("height", "400"),
                    svg.prop("viewBox", "0 0 200 200")
                ),
                string.concat(
                    svg.rect(
                        string.concat(
                            svg.prop("width", "200"),
                            svg.prop("height", "200"),
                            svg.prop("fill", "#0e1111")
                        )
                    ),
                    getArtForConstellation(constellation, moonSeed, config, 0)
                )
            );
    }

    /// @notice burn and mint constellation for particular moon. Only callable by moon contract.
    /// @param moonTokenId moon token id.
    function burnAndMint(uint256 moonTokenId) external {
        // Only moon contract can burn
        if (msg.sender != moonAddress) {
            revert MsgSenderNotMoonAddress();
        }

        // Burn existing Constellation token
        _burn(msg.sender, moonTokenIdToConstellationTokenId[moonTokenId], 1);
        // Mint new token
        mint(moonTokenId, 1);
    }

    /// @notice mint Constellation NFTs corresponding with moons.
    /// @param startMoonTokenId start moon token id.
    /// @param numMoonsMinted number of moons minted.
    function mint(uint256 startMoonTokenId, uint256 numMoonsMinted) public {
        // Only moon contract can mint
        if (msg.sender != moonAddress) {
            revert MsgSenderNotMoonAddress();
        }

        for (
            uint256 moonTokenId = startMoonTokenId;
            moonTokenId < startMoonTokenId + numMoonsMinted;
            ++moonTokenId
        ) {
            // Determine constellation to mint based on moon token
            uint256 constellationIdx = uint256(
                getConstellationTypeForMoonTokenIdAtMint(moonTokenId)
            );
            // Map moon token id to this constellation token id (index)
            moonTokenIdToConstellationTokenId[moonTokenId] = constellationIdx;
            // Mint to msg.sender, which is moon contract since we only
            // allow minting by moon contract
            _mint(msg.sender, constellationIdx, 1, "");
        }
    }

    /// @notice get fully on-chain uri for a particular token.
    /// @param tokenId token id, which is an index in Constellation enum.
    /// @return Constellation uri for tokenId.
    function uri(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155)
        returns (string memory)
    {
        if (tokenId > uint256(Constellation.NONE)) {
            revert InvalidConstellationIndex();
        }

        // Only define fields relevant for generating image for uri
        MoonImageConfig memory moonImageConfig;
        moonImageConfig.viewWidth = DEFAULT_VIEW_SIZE;
        moonImageConfig.viewHeight = DEFAULT_VIEW_SIZE;
        moonImageConfig.moonRadius = DEFAULT_MOON_RADIUS;

        string memory constellationSvg = Utils.svgToImageURI(
            getStandaloneConstellation(
                Constellation(tokenId),
                bytes32(0),
                moonImageConfig
            )
        );
        return
            Utils.formatTokenURI(
                constellationSvg,
                constellationSvg,
                getConstellationTypeString(Constellation(tokenId)),
                "Constellations are on-chain constellation NFTs. Constellations are on-chain art owned by on-chain art; Constellations are all owned by Non-Fungible Moon NFTs.",
                string.concat(
                    "[",
                    _getTraitForConstellation(Constellation(tokenId)),
                    "]"
                )
            );
    }

    // Dynamic NFT registry setup

    /// @notice set up dynamic NFT registry.
    /// @param _dynamicNftRegistryAddress dynamic NFT registry address.
    function setupDynamicNftRegistry(address _dynamicNftRegistryAddress)
        external
        onlyOwner
    {
        dynamicNftRegistryAddress = _dynamicNftRegistryAddress;
    }

    // IERC165 functions

    /// @notice check if this contract supports a given interface.
    /// @param interfaceId interface id.
    /// @return true if contract supports interfaceId, false otherwise.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            // AlienArtBase interface id
            interfaceId == type(AlienArtBase).interfaceId;
    }
}