// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IMergeCanvas.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

error MergeNFT_MintedBefore(address sender);
error ERC721Metadata_URIQueryForNonExistentToken(uint256 tokenId);

contract MergeNFT is ERC721, Ownable {
    uint256 public tokenCounter;
    string public CANVAS_URL;
    uint256 private CANVAS_DIMENSION;
    uint16 private OPACITY;
    address immutable OWNER_ADDRESS;
    address private MERGE_CANVAS_CONTRACT_ADDRESS;
    mapping(uint256 => address) public tokenIdToContributor;
    mapping(address => bool) private hasMinted;
    IMergeCanvas mergeCanvasContract;

    event MergeNFT_Minted(address contributor, uint256 tokenId);
    event MergeNFT_Deployed(
        address owner,
        address mergeCanvasContractAddress,
        string canvasUrl,
        uint16 opacity,
        uint256 canvasDimension
    );

    struct Square {
        uint16 x;
        uint16 y;
        IMergeCanvas.RGB color;
    }

    constructor(address _merge_canvas_contract_address, string memory _url)
        ERC721("TheMergeMosaic", "TMM")
    {
        tokenCounter = 1;
        OPACITY = 80; // White overlay opacity on top of the background Image
        OWNER_ADDRESS = msg.sender;
        CANVAS_URL = _url; //Background Image to be included in the SVG
        MERGE_CANVAS_CONTRACT_ADDRESS = _merge_canvas_contract_address;
        mergeCanvasContract = IMergeCanvas(MERGE_CANVAS_CONTRACT_ADDRESS);
        CANVAS_DIMENSION = 500;
        emit MergeNFT_Deployed(
            OWNER_ADDRESS,
            MERGE_CANVAS_CONTRACT_ADDRESS,
            CANVAS_URL,
            OPACITY,
            CANVAS_DIMENSION
        );
    }

    function mint() public Contributed {

        // If user has already minted, revert
        if (hasMinted[msg.sender] == true) {
            revert MergeNFT_MintedBefore(msg.sender);
        }

        uint256 tokenId = tokenCounter;
        tokenCounter = tokenCounter + 1;
        // user has claimed their NFT
        hasMinted[msg.sender] = true;
        // Mint NFT
        _safeMint(msg.sender, tokenId);
        // Set ID to contibutor address to find the contibuted pixels ini the pre merge contract
        tokenIdToContributor[tokenId] = msg.sender;
        emit MergeNFT_Minted(msg.sender, tokenId);
    }

    modifier OnlyOwner() {
        if (msg.sender != OWNER_ADDRESS) {
            revert MergeCanvas_NotOwner(msg.sender);
        }
        _;
    }

    modifier Contributed() {
        // Only addresses that have contributed to the Mosaic
        if (!mergeCanvasContract.hasContributed(msg.sender)) {
            revert MergeCanvas_NotContributor(msg.sender);
        }
        _;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (_tokenId >= tokenCounter) {
            revert ERC721Metadata_URIQueryForNonExistentToken(_tokenId);
        }

        return
            formatTokenURI(
                svgToImageURI(generateSVG(tokenIdToContributor[_tokenId]))
            );
    }


    function putBackground() internal view returns (string memory) {
        // Functtion to put the background image from URL in the SVG
        return
            string.concat(
                '<image href="',
                CANVAS_URL,
                '" onerror="this.style.display=',
                "'none'",
                '" height="',
                Strings.toString(CANVAS_DIMENSION),
                '" width="',
                Strings.toString(CANVAS_DIMENSION),
                '"/>',
                '<rect width="',
                Strings.toString(CANVAS_DIMENSION),
                '" height="',
                Strings.toString(CANVAS_DIMENSION),
                '" fill="white" fill-opacity="',
                Strings.toString(OPACITY),
                '%"/>'
            );
    }

    function generateSVG(address _to) internal view returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" height="',
                Strings.toString(CANVAS_DIMENSION),
                '" width="',
                Strings.toString(CANVAS_DIMENSION),
                '">',
                putBackground(),
                generateRects(_to),
                "</svg>"
            );
    }

    function generateRects(address _to)
        internal
        view
        returns (string memory _rects)
    {
        
        // Get the contributed pixels from the pre merge contract
        uint256[] memory pixel_coordinates = mergeCanvasContract
            .getAddressPixels(_to);

        // Construct the SVG string
        for (uint16 i = 0; i < pixel_coordinates.length; i++) {
            // Get (x,y) coordinates
            uint256 curr_pixel_coordinates_encoded = pixel_coordinates[i];
            uint16 x_coordinate = uint16(curr_pixel_coordinates_encoded >> 16);
            uint16 y_coordinate = uint16(
                curr_pixel_coordinates_encoded % (2**16)
            );

            IMergeCanvas.RGB memory pixel_color = mergeCanvasContract
                .getPixelColor(x_coordinate, y_coordinate);

            // Struct to pass to createRect function for SVG creation
            Square memory sqr = Square({
                x: x_coordinate,
                y: y_coordinate,
                color: pixel_color
            });
            _rects = string.concat(_rects, createRect(sqr));
        }
        return _rects;
    }

    function svgToImageURI(string memory _svg)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(_svg))
                )
            );
    }

 
    function createRect(Square memory _shape)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    Strings.toString(_shape.x),
                    '" y="',
                    Strings.toString(_shape.y),
                    '" width="',
                    Strings.toString(1),
                    '" height="',
                    Strings.toString(1),
                    '" style="fill:rgb(',
                    Strings.toString(_shape.color.R),
                    ",",
                    Strings.toString(_shape.color.G),
                    ",",
                    Strings.toString(_shape.color.B),
                    ")",
                    '"/>'
                )
            );
    }

    function setCanvasURL(string memory _url) public OnlyOwner {
        CANVAS_URL = _url;
    }

    function formatTokenURI(string memory _imageURI)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string.concat(
                                '{"name":"',
                                "Merge Mosaic",
                                '", "description":"An NFT of Pixels Contributed to the Mosaic!", "attributes":"", ',
                                '"image": "',
                                CANVAS_URL,
                                ' "animation_url":"',
                                _imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

}