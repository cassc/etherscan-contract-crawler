// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./utils/Base64.sol";
import "./ICanary.sol";

contract CanaryPhysicalProduction is ERC721 {
    using Strings for uint256;

    struct AttestationData {
        bytes32 attestationPayloadHash;
        string attestationPayload;
        uint256 attestationTimestamp;
    }

    // Constant Variables related to SVG Generation
    uint8 constant NO_OF_ROWS = 30;
    uint8 constant NO_OF_COLS = 30;
    uint8 constant ROW_START = 20;
    uint8 constant COL_START = 20;
    uint8 constant NO_OF_HAIRROWS = NO_OF_ROWS - ROW_START;
    uint8 constant NO_OF_HAIRCOLS = NO_OF_COLS - COL_START;

    uint16 constant ROW_HEIGHT = 10;
    uint16 constant COL_WIDTH = 10;

    string internal constant PLACEHOLDER_SVG_PRE =
       '<svg width=\"620\" height=\"620\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 300 300\"><defs><filter id=\"a\"><feComponentTransfer><feFuncA type=\"discrete\" tableValues=\"0 1\"/></feComponentTransfer><feGaussianBlur stdDeviation=\"23\"/></filter></defs><path stroke=\"#000\" stroke-width=\"8\" fill-opacity=\"10%\" filter=\"url(#a)\" d=\"M0 0h300v300H0z\"/><text style=\"font:38px monospace\" x=\"50%\" y=\"50%\" text-anchor=\"middle\">';

    string internal constant MUNDI_PRE =
        '<svg width=\"620\" height=\"620\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" viewBox=\"-10 -20 320 320\">';

    string internal constant MUNDI_MID =
        '<rect id=\"bg\" x=\"-10\" y=\"-20\" width=\"320\" height=\"320\"/> <g id=\"hair\"> <rect x=\"40\" y=\"160\" width=\"10\" height=\"10\"/> <polygon points=\"90,220 90,210 80,210 80,200 70,200 70,210 60,210 60,200 70,190 70,160 80,160 80,150 70,150 60,140 50,150 60,160 60,190 50,190 50,180 40,180 40,190 30,190 30,200 50,200 50,210 30,210 30,220 50,220 50,230 30,230 30,240 40,250 50,250 50,260 30,260 30,280 20,290 10,290 10,300 60,300 60,280 100,280 100,230\"/> <polygon points=\"100,60 100,50 90,50 90,40 80,40 80,60 70,70 60,70 60,100 50,110 50,120 60,130 70,130 70,120 80,120 80,140 90,130 90,80 100,80 100,70 110,70 110,60\"/> <rect x=\"80\" y=\"290\" width=\"10\" height=\"10\"/> <polygon points=\"110,120 110,130 100,140 100,120\"/> <polygon points=\"120,20 120,30 110,40 90,40 90,30 110,30 110,20\"/> <rect x=\"150\" y=\"140\" width=\"10\" height=\"10\"/> <rect x=\"160\" y=\"180\" width=\"10\" height=\"10\"/> <polygon points=\"240,90 230,100 220,100 220,90 210,90 210,80 200,80 200,70 190,60 190,50 170,50 160,40 150,40 150,30 160,30 160,20 150,20 150,30 140,30 140,40 130,40 130,10 170,10 170,30 180,30 180,20 190,20 200,30 190,30 190,40 200,40 210,50 220,50 220,60 230,70 230,80\"/> <polygon points=\"260,290 260,300 250,300 250,290 240,290 230,280 230,270 240,270 240,280 250,280\"/> <polygon points=\"250,230 250,240 260,240 260,250 270,260 280,260 280,270 270,270 270,280 250,280 250,260 240,260 240,250 230,250 230,240 240,240 240,210 230,210 230,190 220,180 210,180 210,140 200,140 200,130 180,130 180,120 190,120 200,110 210,110 210,100 220,100 220,120 230,120 230,140 240,150 230,160 230,170 250,190 260,190 260,210 250,210 250,220 260,220 260,210 270,200 280,200 280,210 270,210 270,230\"/> <rect x=\"270\" y=\"290\" width=\"10\" height=\"10\"/> <rect x=\"290\" y=\"290\" width=\"10\" height=\"10\"/> <polygon points=\"220,190 220,200 210,210 210,220 200,230 200,240 210,240 210,250 200,250 200,270 210,280 210,290 200,300 190,300 180,290 180,280 160,280 160,270 150,260 140,260 140,280 130,280 130,270 120,260 120,250 140,250 145,245 150,250 170,250 170,240 180,240 180,230 190,230 190,220 200,220 200,210 190,210 190,200 210,200 210,190\"/> </g> <g id=\"bg\"> <rect x=\"40\" y=\"280\" width=\"10\" height=\"10\"/> <rect x=\"60\" y=\"220\" width=\"10\" height=\"10\"/> <polygon points=\"90,260 80,270 60,270 60,260 70,260 70,240 80,240 80,250 90,250\"/> <rect x=\"70\" y=\"90\" width=\"10\" height=\"10\"/> </g> <g id=\"skin\"> <rect x=\"30\" y=\"220\" width=\"10\" height=\"10\"/> <rect x=\"60\" y=\"260\" width=\"10\" height=\"10\"/> <polygon points=\"70,190 70,210 60,210 60,200\"/> <rect x=\"120\" y=\"20\" width=\"10\" height=\"10\"/> <rect x=\"130\" y=\"180\" width=\"10\" height=\"10\"/> <rect x=\"240\" y=\"260\" width=\"10\" height=\"10\"/> <polygon points=\"260,280 260,290 250,280\"/> <polygon points=\"100,110 100,140 90,140 80,150 80,140 90,130 90,110\"/> <polygon points=\"100,230 90,220 90,210 80,210 80,170 90,170 90,200 100,210 110,210 120,220 120,260 130,270 130,280 140,280 140,260 150,260 150,270 160,270 160,280 180,280 180,290 190,300 90,300 90,280 100,280\"/> <polygon points=\"130,30 130,50 120,50 110,60 100,60 100,50 90,50 90,40 110,40 120,30\"/> <polygon points=\"140,120 130,120 120,130 110,130 110,110 130,110\"/> <polygon points=\"170,160 170,180 160,180 160,160 150,160 150,150 160,150\"/> <polygon points=\"210,80 210,110 200,110 190,120 180,120 180,130 200,130 200,160 190,150 180,150 180,140 170,130 160,130 160,120 170,110 170,100 180,100 180,110 190,110 200,100 200,80\"/> <polygon points=\"200,210 200,220 190,220 190,230 180,230 180,240 170,240 170,230 130,230 130,220 160,220 160,210 170,210 170,220 180,220 180,210 170,200 140,200 140,190 170,190 180,200 190,200 190,210\"/> <polygon points=\"210,170 210,200 190,200 200,190 200,180\"/> <polygon points=\"250,140 250,150 240,150 230,140 230,120 240,120 240,140\"/> </g> <g id=\"skin-in\"> <polygon points=\"170,230 170,250 150,250 145,245 140,250 120,250 120,220 110,210 100,210 90,200 90,170 80,170 80,150 90,140 100,140 110,130 120,130 130,120 140,120 140,130 130,130 130,140 120,140 120,150 90,150 90,160 100,170 100,180 120,200 130,200 135,205 130,210 130,240 140,240 140,230\"/> <polygon points=\"140,170 140,180 130,180\"/> <rect x=\"140\" y=\"30\" width=\"10\" height=\"10\"/> <polygon points=\"120,100 120,110 110,110 110,120 100,120 100,110 90,110 90,100\"/> <polygon points=\"180,210 180,220 170,220 170,210 160,210 160,220 140,220 140,210 150,210 150,200 170,200\"/> <polygon points=\"160,160 160,190 140,190 140,180 150,180 150,160\"/> <polygon points=\"180,140 180,150 170,150 170,140 150,140 150,120 160,110 160,100 170,100 170,110 160,120 160,130 170,130\"/> <polygon points=\"200,70 200,100 190,110 180,110 180,100 190,90 190,80 180,70 180,60 170,50 190,50 190,60\"/> <polygon points=\"210,140 210,170 200,180 200,190 190,200 180,200 170,190 170,160 180,170 180,190 190,190 190,170 195,165 200,170 200,140\"/> </g> <g id=\"skin-in-in\"> <rect x=\"130\" y=\"230\" width=\"10\" height=\"10\"/> <polygon points=\"110,100 90,100 90,80 100,80 100,90\"/> <polygon points=\"130,180 130,190 140,190 140,200 150,200 150,210 140,210 140,220 130,220 130,210 135,205 130,200 120,200 100,180 100,170 110,170 110,180 120,180 120,170 130,160 130,150 120,150 120,140 130,140 130,130 140,130 140,140 150,140 150,150 140,150 140,170\"/> <polygon points=\"190,80 190,90 180,100 160,100 160,110 150,120 140,120 130,110 120,110 120,100 140,100 140,110 150,110 150,100 160,90 170,90 170,80 160,80 160,70 170,60 160,50 160,40 180,60 180,70\"/> <polygon points=\"200,160 200,170 195,165 190,170 190,190 180,190 180,170 160,150 160,140 170,140 170,150 190,150\"/> </g> <polygon id=\"skin-core\" points=\"150,40 150,70 140,70 140,90 130,100 120,100 120,90 125,85 120,80 120,70 110,70 110,60 120,50 130,50 130,40 \"/> <g id=\"skin-apex\"> <polygon points=\"130,150 130,160 120,170 120,180 110,180 110,170 100,170 90,160 90,150\"/> <polygon points=\"125,85 120,90 120,100 110,100 100,90 100,70 120,70 120,80\"/> <polygon points=\"160,80 170,80 170,90 160,90 150,100 150,110 140,110 140,100 130,100 140,90 140,70 150,70 150,40 160,40 160,50 170,60 160,70\"/> <rect x=\"140\" y=\"120\" width=\"10\" height=\"20\"/> <rect x=\"140\" y=\"150\" width=\"10\" height=\"30\"/> </g><g id=\"hair\">';

    string internal constant MUNDI_POST = "</svg>";

    uint8[12][12] internal HAIR_MASK = [
        // ˅ first col is a border        // ˅ last col is also a border
        [1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0], // first row is a border
        [1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0],
        [1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0] // last row is border
    ];

    string[] colors = [
        "#3C5F94", "#444444", "#485872", "#73A9FB", "#74E186", "#7C6290", "#935E9B", "#9CD654", "#A7CD76", "#B0A794", "#CA93D1", "#DBCDB3", "#DEAD6E", "#252929", "#EB9792", "#FFA24D",
        "#97C8B7", "#9AB8C7", "#9FD3C1", "#A3C0B6", "#A7B9C2", "#A8CCC0", "#ABCADA", "#B2C9D4", "#BCCCC8", "#BCDDD2", "#C2DED7", "#CEDAE0", "#CEE5DD", "#D5E3EA", "#D9E6ED", "#E1EBF0",
        "#215575", "#264659", "#334C5B", "#3E8195", "#417180", "#497886", "#50855C", "#58849D", "#59839A", "#5E956B", "#5EA16E", "#5EA970", "#68A476", "#6A9C76", "#70B07F", "#72BA83",
        "#64C795", "#67B490", "#6CBF9A", "#72C09C", "#7598A6", "#7998A5", "#7C99A9", "#7CA2B8", "#81A1AE", "#829EAE", "#84A7B5", "#86A6B9", "#86CFAD", "#87ACA0", "#8BB1A5", "#97B8AE",
        "#508DA4", "#528193", "#528F8F", "#5592A3", "#55A184", "#5689A5", "#58A57B", "#599DB0", "#5A937C", "#5C9AAB", "#608A8A", "#608AA0", "#6491A1", "#649C7D", "#699B9B", "#6CA38F",
        "#1F5271", "#26607A", "#2A6886", "#2A728F", "#335C6F", "#33936D", "#36809F", "#376C88", "#3F915E", "#407A56", "#42805E", "#446967", "#4D788F", "#558C6C", "#5A8877", "#5F937E",
        "#33588F", "#36383A", "#3D387E", "#3E7976", "#4F76B0", "#693771", "#769054", "#7AAB3A", "#95815B", "#97589F", "#A6625D", "#A99A7C", "#AA545D", "#B08751", "#BD55A6", "#CA8749"
    ];

    // Attestation related variables
    mapping(bytes32 => bool) public hashExists;
    mapping(uint256 => AttestationData) internal _tokenIdToAttestationData;
    address public immutable CANARY_ADDRESS;

    constructor(
        string memory name,
        string memory symbol,
        address canaryAddress
    ) ERC721(name, symbol) {
        CANARY_ADDRESS = canaryAddress;
    }

    // Public Functions

    /// @notice Returns attestation data
    function getAttestationData(uint256 tokenId)
        public
        view
        returns (
            string memory attestationPayload,
            bytes32 attestationPayloadHash,
            uint256 attestationTimestamp
        )
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return (
            _tokenIdToAttestationData[tokenId].attestationPayload,
            _tokenIdToAttestationData[tokenId].attestationPayloadHash,
            _tokenIdToAttestationData[tokenId].attestationTimestamp
        );
    }

  /// @dev Token URI including the image SVG data is dynamically generated
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (_tokenIdToAttestationData[tokenId].attestationTimestamp == 0) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"Physical Production Rights of The Greats #',
                                tokenId.toString(),
                                '", ',
                                '"image":"',
                                generatePlaceholderSvg(tokenId),
                                '" }'
                            )
                        )
                ));
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"Attestation of the Physical Production of The Greats #',
                            tokenId.toString(),
                            '", ',
                            '"image":"',
                            renderSVGFromHash(
                                _tokenIdToAttestationData[tokenId].attestationPayloadHash,
                                tokenId
                            ),
                            '", ',
                            '"attestation_timestamp":"',
                            _tokenIdToAttestationData[tokenId].attestationTimestamp.toString(),
                            '", ',
                            '"attestation_payload_base64":"',
                            Base64.encode(abi.encodePacked(_tokenIdToAttestationData[tokenId].attestationPayload)),
                            '" }'
                        )
                    )
                ));
    }

    // External Functions

    /// @notice Mints an Physical Production token for the corresponding Canary token ID
    function mint(uint256 canaryTokenId) external {
        require(!_exists(canaryTokenId), "Already minted");

        address owner = ICanary(CANARY_ADDRESS).ownerOf(canaryTokenId);

        require(owner == msg.sender, "Caller is not the owner of the token");
        require(
            ICanary(CANARY_ADDRESS).metadataAssigned(canaryTokenId),
            "Metadata is not assigned to the token yet"
        );

        _safeMint(msg.sender, canaryTokenId);
    }

    /// @notice Attestation is done by storing a payload that represents the attestation proof to the metadata of the token ID
    /// @dev Can only attest once for a particular Physical Production token
    function attest(uint256 tokenId, string memory payload) external {
        require(_exists(tokenId), "Token does not exist");
        require(
            _tokenIdToAttestationData[tokenId].attestationTimestamp == 0,
            "Attestation already done for this token ID"
        );
        require(bytes(payload).length > 0, "Payload string cannot be empty");

        bytes32 payloadHash = keccak256(abi.encodePacked(payload));

        require(hashExists[payloadHash] == false, "Hash already exists");

        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");

        hashExists[payloadHash] = true;
        _tokenIdToAttestationData[tokenId] = AttestationData(
            payloadHash,
            payload,
            block.timestamp
        );
    }

    // Internal Functions

    /// @dev Renders Mundi SVG dynamically based on the Keccak-256 hash of the attestation payload
    function renderSVGFromHash(bytes32 attestationPayloadHash, uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint8[10][10] memory hairMap;

        // First 75 bits of the following are used
        uint8[256] memory hashInBinary = toBinaryArray(abi.encodePacked(attestationPayloadHash));

        uint256 bitOffset;

        for (uint8 row = 0; row < NO_OF_HAIRROWS; row++) {
            for (uint8 col = 0; col < NO_OF_HAIRCOLS; col++) {
                uint8 hairMaskV = HAIR_MASK[row + 1][col + 1];
                if (hairMaskV == 0) {
                    hairMap[row][col] = 0;
                } else {
                    hairMap[row][col] = hashInBinary[bitOffset++];
                }
            }
        }

        string memory tokenNumberRender = string(
            abi.encodePacked(
                '<text text-rendering=\"geometricPrecision\" font-family=\"Mundi\" font-size=\"25\" text-anchor=\"end\" x=\"300\" y=\"16\" id=\"number\">#', tokenId.toString(),
                "</text>"
            )
        );

        string
            memory hairSvg = '<rect x=\"200\" y=\"200\" width=\"100\" height=\"100\" id=\"bg\"/>';

        for (uint8 row = 0; row < NO_OF_HAIRROWS; row++) {
            for (uint8 col = 0; col < NO_OF_HAIRCOLS; col++) {
                uint8 hairMaskV = HAIR_MASK[row + 1][col + 1];
                if (hairMaskV == 0) continue;
                if (hairMap[row][col] == 0) continue;

                bool isTop = row == 0;
                bool isLeft = col == 0;
                bool isRight = col == NO_OF_HAIRCOLS - 1;
                bool isBottom = row == NO_OF_HAIRROWS - 1;

                uint8 top = isTop ? HAIR_MASK[row][col + 1] : hairMap[row - 1][col];
                uint8 left = isLeft ? HAIR_MASK[row + 1][col] : hairMap[row][col - 1];
                uint8 right = isRight ? HAIR_MASK[row + 1][col + 2] : hairMap[row][col + 1];
                uint8 bottom = isBottom ? HAIR_MASK[row + 2][col + 1] : hairMap[row + 1][col];

                hairSvg = string(
                    abi.encodePacked(
                        hairSvg,
                        generateHairPoint(col, row, top, left, right, bottom)
                    )
                );
            }
        }
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            MUNDI_PRE,
                            generateStylesheet(attestationPayloadHash),
                            MUNDI_MID,
                            hairSvg,
                            "</g>",
                            tokenNumberRender,
                            MUNDI_POST
                        )
                    )
                ));
    }

    // Internal functions

    /// @dev Renders the SVG hair component
    function generateHairPoint(
        uint8 col,
        uint8 row,
        uint8 top,
        uint8 left,
        uint8 right,
        uint8 bottom
    ) internal pure returns (string memory) {
        uint256 x = (col + COL_START) * COL_WIDTH;
        uint256 y = (row + ROW_START) * ROW_HEIGHT;

        string memory topLeft = string(abi.encodePacked(x.toString(), ",", y.toString()));
        string memory topRight = string(
            abi.encodePacked((x + COL_WIDTH).toString(), ",", y.toString())
        );
        string memory bottomLeft = string(
            abi.encodePacked(x.toString(), ",", (y + ROW_HEIGHT).toString())
        );
        string memory bottomRight = string(
            abi.encodePacked((x + COL_WIDTH).toString(), ",", (y + ROW_HEIGHT).toString())
        );

        string memory points;

        // if it's a diagonal, round the corner
        if (top != 0 && right != 0 && bottom == 0 && left == 0) {
            points = string(abi.encodePacked(topLeft, " ", topRight, " ", bottomRight));
        } else if (right != 0 && bottom != 0 && left == 0 && top == 0) {
            points = string(abi.encodePacked(topRight, " ", bottomRight, " ", bottomLeft));
        } else if (bottom != 0 && left != 0 && top == 0 && right == 0) {
            points = string(abi.encodePacked(bottomRight, " ", bottomLeft, " ", topLeft));
        } else if (left != 0 && top != 0 && right == 0 && bottom == 0) {
            points = string(abi.encodePacked(bottomLeft, " ", topLeft, " ", topRight));
        } else {
            points = string(
                abi.encodePacked(topLeft, " ", topRight, " ", bottomRight, " ", bottomLeft)
            );
        }

        return string(abi.encodePacked('<polygon points=\"', points, '\" id=\"hair\" />'));
    }

    /// @dev Converts bytes array into an integer array that represents corresponding binary representation
    function toBinaryArray(bytes memory b) internal pure returns (uint8[256] memory binary) {
        for (uint256 i = 0; i < 32; i++) {

            // Since each byte1 represents two hexadecimal chars, it needs to be split
            bytes1 rightHexByte = b[i] & 0x0F;
            bytes1 leftHexByte = b[i] >> 4;

            uint256 n = hexadecimalCharToInteger(leftHexByte);
            for (uint8 k = 0; k < 4; k++) {
                binary[3 + (8 * i) - k] = (n % 2 == 1) ? 1 : 0;
                n /= 2;
            }
            n = hexadecimalCharToInteger(rightHexByte);
            for (uint8 k = 0; k < 4; k++) {
                binary[7 + (8 * i) - k] = (n % 2 == 1) ? 1 : 0;
                n /= 2;
            }
        }
    }

    /**
     * @dev Generates the SVG stylesheet consisting of a deterministic color palette.
     * Composes the color palette based on last 7 bytes of the SHA-256 hash string.
     */
    function generateStylesheet(bytes32 attestationPayloadHash) internal view returns (string memory) {
        bytes memory b = abi.encodePacked(attestationPayloadHash);
        string[7] memory colorPalette;

        for (uint256 i = 0; i < 4; i++) {
            // Since each byte1 represents two hexadecimal chars, it needs to be split
            bytes1 leftHexByte = b[31 - i] >> 4;
            bytes1 rightHexByte = b[31 - i] & 0x0F;

            colorPalette[i * 2] = colors[((i * 2) * 16) + hexadecimalCharToInteger(rightHexByte)];
            if (i < 3) {
                colorPalette[(i * 2) + 1] = colors[(((i * 2) + 1) * 16) + hexadecimalCharToInteger(leftHexByte)];
            }
        }

        // Splitting as a workaround to stack too deep error
        string memory part1 = string(
            abi.encodePacked(
                "<style>#bg { fill: ",
                colorPalette[0],
                "; }",
                "#skin-apex { fill: ",
                colorPalette[1],
                "; }",
                "#skin-core { fill: ",
                colorPalette[2],
                "; }"
            )
        );

        string memory part2 = string(
            abi.encodePacked(
                "#skin-in-in { fill: ",
                colorPalette[3],
                "; }",
                "#skin-in { fill: ",
                colorPalette[4],
                "; }",
                "#skin { fill: ",
                colorPalette[5],
                "; }",
                "#hair { fill: ",
                colorPalette[6],
                "; }",
                "#number { font: 35px monospace; fill: #ffffff; font-smooth: never; -webkit-font-smoothing: none; }",
                "</style>"
            )
        );

        return string(abi.encodePacked(part1, part2));
    }

    /// @dev Converts Hexadecimal char to an integer (0 to 15)
    function generatePlaceholderSvg(uint256 tokenId) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(abi.encodePacked(PLACEHOLDER_SVG_PRE, "#", tokenId.toString(), "</text></svg>"))
                )
            );
    }

    /// @dev Converts Hexadecimal char to an integer (0 to 15)
    function hexadecimalCharToInteger(bytes1 char) internal pure returns (uint256) {
        bytes1[16] memory alphabets = [
            bytes1(0x00),
            bytes1(0x01),
            bytes1(0x02),
            bytes1(0x03),
            bytes1(0x04),
            bytes1(0x05),
            bytes1(0x06),
            bytes1(0x07),
            bytes1(0x08),
            bytes1(0x09),
            bytes1(0x0a),
            bytes1(0x0b),
            bytes1(0x0c),
            bytes1(0x0d),
            bytes1(0x0e),
            bytes1(0x0f)
        ];
        for (uint256 i = 0; i < 16; i++) {
            if (char == alphabets[i]) {
                return i;
            }
        }
        revert("Input is not a hexadecimal char");
    }
}