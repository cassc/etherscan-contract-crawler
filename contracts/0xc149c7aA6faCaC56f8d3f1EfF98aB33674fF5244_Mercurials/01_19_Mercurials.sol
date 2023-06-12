// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {LinearVRGDA} from "VRGDAs/LinearVRGDA.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";

/// @title Mercurials NFT
/// @author nvonpentz
/// @notice An on-chain generative art auction.
contract Mercurials is ERC721, LinearVRGDA, ReentrancyGuard {
    // ====================== TYPES ======================
    using Strings for uint256;

    // ============== PUBLIC STATE VARIABLES =============
    /// @notice The total number of tokens sold, also used as the next token ID
    uint256 public totalSold;

    /// @notice The time at which the auction started
    uint256 public immutable startTime = block.timestamp;

    /// @notice The seed used to generate the token's attributes
    mapping(uint256 => uint256) public seeds;

    // ==================== CONSTANTS ====================
    uint256 private constant BASE_FREQUENCY_MIN = 50;
    uint256 private constant BASE_FREQUENCY_MAX = 301;
    uint256 private constant NUM_OCTAVES_MIN = 1;
    uint256 private constant NUM_OCTAVES_MAX = 6;
    uint256 private constant SVG_SEED_MIN = 0;
    // Note: 65535 is the max value for the seed attribute of
    // the feTurbulence SVG element.
    uint256 private constant SVG_SEED_MAX = 65536;
    uint256 private constant K4_MIN = 0;
    uint256 private constant K4_MAX = 51;
    uint256 private constant DIFFUSE_CONSTANT_MIN = 1;
    uint256 private constant DIFFUSE_CONSTANT_MAX = 4;
    uint256 private constant SURFACE_SCALE_MIN = 5;
    uint256 private constant SURFACE_SCALE_MAX = 11;
    uint256 private constant ELEVATION_MIN = 3;
    uint256 private constant ELEVATION_MAX = 21;
    uint256 private constant SCALE_MIN = 0;
    uint256 private constant SCALE_MAX = 201;
    uint256 private constant SCALE_DELTA_MIN = 50;
    uint256 private constant SCALE_DELTA_MAX = 251;
    uint256 private constant SCALE_ANIMATION_MIN = 1;
    uint256 private constant SCALE_ANIMATION_MAX = 81;
    uint256 private constant KEY_TIME_MIN = 3;
    uint256 private constant KEY_TIME_MAX = 8;
    uint256 private constant HUE_ROTATE_ANIMATION_MIN = 1;
    uint256 private constant HUE_ROTATE_ANIMATION_MAX = 21;
    uint256 private constant ROTATION_MIN = 0;
    uint256 private constant ROTATION_MAX = 4;

    // ===================== EVENTS =====================
    event TokenMinted(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 price
    );

    // ===================== ERRORS =====================
    error InvalidBlockHash();
    error InvalidTokenId();
    error InsufficientFunds();
    error TokenDoesNotExist();

    // ================== CONSTRUCTOR ===================
    // @notice Sets the VRGDA parameters, and the ERC721 name and symbol
    constructor()
        ERC721("Mercurials", "MERC")
        LinearVRGDA(
            // Target price, 0.001 Ether
            0.001e18,
            // Price decay percent, 5%
            0.05e18,
            // Per time unit, .2 tokens a day or 1 token every 5 days
            0.2e18
        )
    {}

    // ============== EXTERNAL FUNCTIONS ================
    /// @notice Mints a new token
    /// @param tokenId The token ID to mint
    /// @param blockHash The hash of the parent block number rounded down
    /// to the nearest multiple of 5
    function mint(
        uint256 tokenId,
        bytes32 blockHash
    ) external payable nonReentrant {
        // Require that the user-supplied block hash matches the expected block hash
        // because otherwise the user would get an unexpected token.
        if (
            blockHash !=
            blockhash((block.number - 1) - ((block.number - 1) % 5))
        ) {
            revert InvalidBlockHash();
        }

        // Require that the user-supplied token ID matches the expected token ID
        // value because otherwise user would get an unexpected token.
        // Use totalSoldMemory memory variable to prevent multiple reads from state.
        uint256 totalSoldMemory = totalSold;
        if (tokenId != totalSoldMemory) {
            revert InvalidTokenId();
        }

        // Ensure enough funds were sent.
        uint256 price = getVRGDAPrice(
            toDaysWadUnsafe(block.timestamp - startTime),
            totalSoldMemory
        );
        if (msg.value < price) {
            revert InsufficientFunds();
        }

        // Mint the NFT.
        _mint(msg.sender, tokenId);
        emit TokenMinted(tokenId, msg.sender, price);
        totalSold += 1;
        seeds[tokenId] = generateSeed(tokenId);

        // Refund the user any ETH they spent over the current price of the NFT.
        if (msg.value > price) {
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
        }
    }

    /// @notice Returns information about the token up for auction.
    /// @dev This function should be called using the `pending` block tag.
    /// @dev The id and blockHash should be passed as arguments to the `mint` function.
    /// @return id The token ID of the next token
    /// @return uri The token URI of the next token
    /// @return price The price of the next token
    /// @return blockHash The hash of the parent block number rounded down to
    /// the nearest multiple of 5
    /// @return ttl The time to live, in blocks, of the next token
    function nextToken()
        external
        view
        returns (
            uint256 id,
            string memory uri,
            uint256 price,
            bytes32 blockHash,
            uint256 ttl
        )
    {
        // The ID of the next token will be also be the totalSold.
        id = totalSold;

        // Generate the token URI using the seed.
        uri = generateTokenUri(generateSeed(id), id);

        // Calculate the current price according to VRGDA rules.
        price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), id);

        // Calculate the block hash corresponding to the next token.
        blockHash = blockhash((block.number - 1) - ((block.number - 1) % 5));

        // Calculate the time to live of the token.
        ttl = 5 - ((block.number - 1) % 5);

        return (id, uri, price, blockHash, ttl);
    }

    // =============== PUBLIC FUNCTIONS =================
    // @notice Returns the token URI for a given token ID
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        return generateTokenUri(seeds[tokenId], tokenId);
    }

    // =============== INTERNAL FUNCTIONS ================
    /// @notice Generates the seed for a given token ID
    /// @param tokenId The token ID to generate the seed for
    /// @return seed The seed for the given token ID
    function generateSeed(uint256 tokenId) internal view returns (uint256) {
        // Seed is calculated as the hash of the current token ID combined with the parent
        // block rounded down to the nearest 5. This ensures that the seed is
        // the same for 5 blocks.
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(
                            (block.number - 1) - ((block.number - 1) % 5)
                        ),
                        tokenId
                    )
                )
            );
    }

    /// @notice Generates a pseudo-random number from min (inclusive) to max (exclusive)
    /// @dev Callers must ensure that min < max
    /// @param seed The seed to use for the random number (the same across multiple calls)
    /// @param nonce The nonce to use for the random number (different between calls)
    function generateRandom(
        uint256 min,
        uint256 max,
        uint256 seed,
        uint256 nonce
    ) internal pure returns (uint256 random, uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, nonce)));
        nonce++;
        return ((rand % (max - min)) + min, nonce);
    }

    /// @notice Generates a random value that is either true or false
    /// @param seed The seed to use for the random number (the same across multiple calls)
    /// @param nonce The nonce to use for the random number (different between calls)
    function generateRandomBool(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (bool, uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, nonce)));
        nonce++;
        return (rand % 2 == 0, nonce);
    }

    /// @notice Returns a string representation of a signed integer
    function intToString(
        uint256 value,
        bool isNegative
    ) internal pure returns (string memory) {
        if (isNegative && value != 0) {
            return string.concat("-", value.toString());
        }
        return value.toString();
    }

    /// @notice Generates the opening svg tag, opening filter tag, and
    /// the feTurbulence element
    function generateSvgOpenAndFeTurbulenceElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        // Generate a random value to use for the baseFrequency attribute.
        uint256 random;
        (random, nonce) = generateRandom(
            BASE_FREQUENCY_MIN,
            BASE_FREQUENCY_MAX,
            seed,
            nonce
        );
        string memory baseFrequency;
        if (random < 100) {
            baseFrequency = string.concat("0.00", random.toString());
        } else {
            baseFrequency = string.concat("0.0", random.toString());
        }

        // Generate a random value to use for the numOctaves attribute.
        string memory numOctaves;
        (random, nonce) = generateRandom(
            NUM_OCTAVES_MIN,
            NUM_OCTAVES_MAX,
            seed,
            nonce
        );
        numOctaves = random.toString();

        // Generate a random value to use for the seed attribute of the SVG.
        string memory seedForSvg;
        (random, nonce) = generateRandom(
            SVG_SEED_MIN,
            SVG_SEED_MAX,
            seed,
            nonce
        );
        seedForSvg = random.toString();

        // Create the SVG element
        element = string.concat(
            '<svg width="350" height="350" version="1.1" viewBox="25 25 300 300" xmlns="http://www.w3.org/2000/svg"><filter id="a"><feTurbulence baseFrequency="',
            baseFrequency,
            '" numOctaves="',
            numOctaves,
            '" seed="',
            seedForSvg,
            '" />'
        );

        // Create the attributes
        attributes = string.concat(
            '{ "trait_type": "Base Frequency", "value": "',
            baseFrequency,
            '" }, { "trait_type": "Octaves", "value": "',
            numOctaves,
            '" }, '
        );

        return (element, attributes, nonce);
    }

    /// @notice Generates the scale values for the feDisplacementMap SVG element
    function generateScale(
        uint256 seed,
        uint256 nonce
    ) internal pure returns (string memory scaleValues, uint256) {
        // Generate a random start value.
        uint256 start;
        bool startNegative;
        (start, nonce) = generateRandom(SCALE_MIN, SCALE_MAX, seed, nonce);
        (startNegative, nonce) = generateRandomBool(seed, nonce);

        // Generate a negative or positive delta value to add
        // to the start value to get the middle value.
        uint256 delta;
        bool deltaNegative;
        (delta, nonce) = generateRandom(
            SCALE_DELTA_MIN,
            SCALE_DELTA_MAX,
            seed,
            nonce
        );
        (deltaNegative, nonce) = generateRandomBool(seed, nonce);

        // Based on the start and delta values, add start and delta together to
        // get the middle value.
        uint256 end;
        bool endNegative;
        if (startNegative == deltaNegative) {
            end = start + delta;
            endNegative = startNegative;
        } else {
            if (start > delta) {
                end = start - delta;
                endNegative = startNegative;
            } else {
                end = delta - start;
                endNegative = deltaNegative;
            }
        }

        // Convert the start value to a string representation.
        string memory scaleStart = intToString(start, startNegative);

        // Concatenate the start, middle, and end values of the scale animation.
        scaleValues = string.concat(
            scaleStart,
            ";",
            intToString(end, endNegative),
            ";",
            scaleStart,
            ";"
        );

        return (scaleValues, nonce);
    }

    /// @notice Generates feDisplacementMap SVG element
    function generateFeDisplacementMapElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        // Generate scale values for the animation.
        string memory scaleValues;
        (scaleValues, nonce) = generateScale(seed, nonce);

        // Generate a random value for the scale animation duration in seconds.
        uint256 random;
        (random, nonce) = generateRandom(
            SCALE_ANIMATION_MIN,
            SCALE_ANIMATION_MAX,
            seed,
            nonce
        );

        // Convert to string and append 's' to represent seconds in the SVG.
        string memory animationDuration = string.concat(random.toString(), "s");

        // Generate a random number to be the middle keyTime value.
        (random, nonce) = generateRandom(
            KEY_TIME_MIN,
            KEY_TIME_MAX,
            seed,
            nonce
        );
        string memory keyTime = string.concat("0.", random.toString());

        element = string.concat(
            '<feDisplacementMap><animate attributeName="scale" values="',
            scaleValues,
            '" keyTimes="0; ',
            keyTime,
            '; 1" dur="',
            animationDuration,
            '" repeatCount="indefinite" calcMode="spline" keySplines="0.3 0 0.7 1; 0.3 0 0.7 1"/></feDisplacementMap>'
        );

        attributes = string.concat(
            '{ "trait_type": "Scale", "value": "',
            scaleValues,
            '" }, { "trait_type": "Scale Animation", "value": "',
            animationDuration,
            '" }, { "trait_type": "Key Time", "value": "',
            keyTime,
            '" }, '
        );
        return (element, attributes, nonce);
    }

    /// @notice Generates the feColorMatrix element used for the rotation animation
    function generateFeColorMatrixElements(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        // Generate a value to be the duration of the animation
        uint256 random;
        (random, nonce) = generateRandom(
            HUE_ROTATE_ANIMATION_MIN,
            HUE_ROTATE_ANIMATION_MAX,
            seed,
            nonce
        );
        string memory animationDuration = random.toString();

        // Create the feColorMatrix element with the <animate> element inside.
        element = string.concat(
            '<feColorMatrix type="hueRotate" result="b"><animate attributeName="values" from="0" to="360" dur="',
            animationDuration,
            's" repeatCount="indefinite"/></feColorMatrix><feColorMatrix type="matrix" result="c" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0"/>'
        );

        // Save the animation duration.
        attributes = string.concat(
            '{ "trait_type": "Hue Rotate Animation", "value": "',
            animationDuration,
            's" }, '
        );

        return (element, attributes, nonce);
    }

    /// @notice Generates feComposite elements
    function generateFeCompositeElements(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory elements, string memory attributes, uint256)
    {
        uint256 random;

        // Generate a random value for the k4 attribute.
        string memory k4;
        (random, nonce) = generateRandom(K4_MIN, K4_MAX, seed, nonce);
        if (random < 10) {
            k4 = string.concat("0.0", random.toString());
        } else {
            k4 = string.concat("0.", random.toString());
        }

        // Make k4 negative half the time.
        string memory operator;
        bool randomBool;
        (randomBool, nonce) = generateRandomBool(seed, nonce);
        if (randomBool) {
            k4 = string.concat("-", k4);
            // If k4 is negative, always use the "out" operator.
            operator = "out";
        } else {
            // Otherwise use the "over" operator half the time.
            (randomBool, nonce) = generateRandomBool(seed, nonce);
            if (randomBool) {
                operator = "out";
            } else {
                operator = "in";
            }
        }

        // Create the feComposite elements.
        elements = string.concat(
            '<feComposite in="b" in2="c" operator="',
            operator,
            '" result="d"/><feComposite in="d" in2="d" operator="arithmetic" k1="1" k2="1" k3="1" k4="',
            k4,
            '"/>'
        );

        // Create the attributes.
        attributes = string.concat(
            '{ "trait_type": "K4", "value": "',
            k4,
            '" }, { "trait_type": "Composite Operator", "value": "',
            operator,
            '" }, '
        );

        return (elements, attributes, nonce);
    }

    /// @notice Generates the feDiffuseLighting SVG element.
    function generateFeDiffuseLightingElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        // Generate a random value for the diffuse constant.
        uint256 random;
        string memory diffuseConstant;
        (random, nonce) = generateRandom(
            DIFFUSE_CONSTANT_MIN,
            DIFFUSE_CONSTANT_MAX,
            seed,
            nonce
        );
        diffuseConstant = random.toString();

        // Generate a random value for the surfaceScale.
        string memory surfaceScale;
        // Note: 10 is the largest surface scale rendered on mobile devices.
        (random, nonce) = generateRandom(
            SURFACE_SCALE_MIN,
            SURFACE_SCALE_MAX,
            seed,
            nonce
        );
        surfaceScale = random.toString();

        // Generate a random value for the elevation.
        string memory elevation;
        (random, nonce) = generateRandom(
            ELEVATION_MIN,
            ELEVATION_MAX,
            seed,
            nonce
        );
        elevation = random.toString();

        // Create the feDiffuseLighting element.
        element = string.concat(
            '<feDiffuseLighting lighting-color="#fff" diffuseConstant="',
            diffuseConstant,
            '" surfaceScale="',
            surfaceScale,
            '"><feDistantLight elevation="',
            elevation,
            '"/></feDiffuseLighting>'
        );

        // Create the attributes.
        attributes = string.concat(
            '{ "trait_type": "Diffuse Constant", "value": "',
            diffuseConstant,
            '" }, { "trait_type": "Surface Scale", "value": "',
            surfaceScale,
            '" }, { "trait_type": "Elevation", "value": "',
            elevation,
            '" },'
        );

        return (element, attributes, nonce);
    }

    /// @notice Generates the feColorMatrix SVG element for (maybe) inverting the colors
    function generateFeColorMatrixForInversionElement(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        // Apply the inversion half the time.
        bool invert;
        (invert, nonce) = generateRandomBool(seed, nonce);
        if (invert) {
            element = '<feColorMatrix type="matrix" values="-1 0 0 0 1 0 -1 0 0 1 0 0 -1 0 1 0 0 0 1 0"/>';
        }

        attributes = string.concat(
            '{ "trait_type": "Inverted", "value": ',
            invert ? "true" : "false",
            " } " // No comma here because this is the last attribute.
        );

        return (element, attributes, nonce);
    }

    /// @notice Generates the main rect element but also includes the closing filter
    /// and closing svg tags
    function generateRectAndSvgClose(
        uint256 seed,
        uint256 nonce
    )
        internal
        pure
        returns (string memory element, string memory attributes, uint256)
    {
        // Generate the rotation.
        uint256 rotation;
        (rotation, nonce) = generateRandom(
            ROTATION_MIN,
            ROTATION_MAX,
            seed,
            nonce
        );
        rotation = rotation * 90;

        element = string.concat(
            '</filter><rect width="350" height="350" filter="url(#a)" transform="rotate(',
            rotation.toString(),
            ' 175 175)"/></svg>'
        );

        attributes = string.concat(
            '{ "trait_type": "Rotation", "value": "',
            rotation.toString(),
            '" }, '
        );
        return (element, attributes, nonce);
    }

    function generateSvg(
        uint256 seed
    ) internal pure returns (string memory svg, string memory attributes) {
        // Nonce is used to generate random numbers and is incremented after
        // each use.
        uint256 nonce;

        // Use block scoping to avoid stack too deep errors.
        {
            // Generate the feTurbulence element.
            string memory svgOpenAndFeTurbulenceElement;
            string memory feTurbulenceAttributes;
            (
                svgOpenAndFeTurbulenceElement,
                feTurbulenceAttributes,
                nonce
            ) = generateSvgOpenAndFeTurbulenceElement(seed, nonce);

            // Generate the feDisplacementMap element.
            string memory feDisplacementMapElement;
            string memory feDisplacementMapAttributes;
            (
                feDisplacementMapElement,
                feDisplacementMapAttributes,
                nonce
            ) = generateFeDisplacementMapElement(seed, nonce);

            // Concatenate the two elements with the SVG opening tag, and filter tag.
            svg = string.concat(
                svgOpenAndFeTurbulenceElement,
                feDisplacementMapElement
            );

            // Concatenate the attributes.
            attributes = string.concat(
                feTurbulenceAttributes,
                feDisplacementMapAttributes
            );
        }

        // Generate the feColorMatrix element.
        string memory feColorMatrixElements;
        string memory feColorMatrixAttributes;
        (
            feColorMatrixElements,
            feColorMatrixAttributes,
            nonce
        ) = generateFeColorMatrixElements(seed, nonce);

        // Generate the feComposite elements.
        string memory feCompositeElements;
        string memory feCompositeAttributes;
        (
            feCompositeElements,
            feCompositeAttributes,
            nonce
        ) = generateFeCompositeElements(seed, nonce);

        // Generate the feDiffuseLighting element.
        string memory feDiffuseLightingElement;
        string memory feDiffuseLightingAttributes;
        (
            feDiffuseLightingElement,
            feDiffuseLightingAttributes,
            nonce
        ) = generateFeDiffuseLightingElement(seed, nonce);

        // Generate the feColorMatrix element used for inverting colors.
        string memory feColorMatrixForInversionElement;
        string memory feColorMatrixForInversionAttributes;
        (
            feColorMatrixForInversionElement,
            feColorMatrixForInversionAttributes,
            nonce
        ) = generateFeColorMatrixForInversionElement(seed, nonce);

        string memory rectAndSvgClose;
        string memory rectAttributes;
        (rectAndSvgClose, rectAttributes, nonce) = generateRectAndSvgClose(
            seed,
            nonce
        );

        // Concatenate all the SVG elements creating the complete SVG.
        svg = string.concat(
            svg,
            feColorMatrixElements,
            feCompositeElements,
            feDiffuseLightingElement,
            feColorMatrixForInversionElement,
            rectAndSvgClose
        );

        // Concatenate all the attributes.
        attributes = string.concat(
            attributes,
            feColorMatrixAttributes,
            feCompositeAttributes,
            feDiffuseLightingAttributes,
            rectAttributes,
            feColorMatrixForInversionAttributes
        );

        return (svg, attributes);
    }

    /// @notice Generates the token URI for a given token ID
    function generateTokenUri(
        uint256 seed,
        uint256 tokenId
    ) internal pure returns (string memory tokenUri) {
        // Generate the SVG markup.
        (string memory svg, string memory attributes) = generateSvg(seed);

        // Create the token URI by base64 encoding the SVG markup, creating the
        // JSON metadata, and then base64 encoding that as a data URI.
        tokenUri = string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{ "name": "Mercurial #',
                        tokenId.toString(),
                        '", "description": "Abstract on-chain generative art", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '", "attributes": [ ',
                        attributes,
                        " ] }"
                    )
                )
            )
        );

        return tokenUri;
    }
}