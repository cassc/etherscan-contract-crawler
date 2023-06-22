// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/access/AccessControl.sol";
import "./Base64.sol";

contract Pixels is ERC721, ERC721Enumerable, Ownable, AccessControl {
    event PixelsChanged(uint32[] pixels, bytes colors);
    event WhitelistSaleStarted();
    event PublicSaleStarted();
    event PriceChanged(uint newPrice);

    bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    address constant WITHDRAW_ADDRESS = 0xc726A39c79b1DECc7F7940e531459471da00825F;
    address constant ADDITIONAL_MANAGER_ADDRESS = 0xB6de01B0468Ad61a4C2a68f3c68878FC342AD88D;

    uint constant CANVAS_WIDTH = 1000;
    uint constant CANVAS_HEIGHT = 1000;
    uint constant TOTAL_PIXELS = CANVAS_WIDTH * CANVAS_HEIGHT;

    uint constant SVG_PIXEL_SIZE = 5;
    string constant SVG_PIXEL_SIZE_STR = "5";

    uint constant COLORS_COUNT = 16;

    uint constant MAX_PIXELS_PER_MINT = 1024;

    uint public price = 0.001 ether;

    uint8[TOTAL_PIXELS] public pixelToColor;
    uint32[TOTAL_PIXELS] public pixelToChunk;
    mapping(uint32 => uint32[]) public chunkToPixels;

    uint32 public nextChunkToken = 1;

    string public baseExternalUrl = "https://re-place.art/";

    // Whitelist & Pixels Claiming
    uint constant GM420_PIXELS_PER_TOKEN = 100;
    uint constant S33DS_PIXELS_PER_TOKEN = 9;
    uint constant BRICK_BREAKERS_PIXELS_PER_TOKEN = 4;

    IERC721Enumerable constant GM420 = IERC721Enumerable(0xFB4ccb3e948FEd6946fC528bA806e737eDc938c4);
    IERC721Enumerable constant S33ds = IERC721Enumerable(0x96eA4f8d4788Fb1D48d175Cd751dAaB056AdA627);
    IERC721Enumerable constant BrickBreakers = IERC721Enumerable(0x45929d1754E9Fc5450acfbe11f3D620FA2316F3D);

    mapping(uint => uint) public claimedGM420PixelsByToken;
    mapping(uint => uint) public claimedS33dsPixelsByToken;
    mapping(uint => uint) public claimedBrickBreakersPixelsByToken;

    bool public whitelistSaleStarted = false;
    bool public publicSaleStarted = false;

    constructor() ERC721("re:Place", "PXLART") {
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, ADDITIONAL_MANAGER_ADDRESS);
    }

    function startWhitelistSale() public onlyRole(MANAGER_ROLE) {
        require(!whitelistSaleStarted, "Whitelist sale already started");
        whitelistSaleStarted = true;
        emit WhitelistSaleStarted();
    }

    function startPublicSale() public onlyRole(MANAGER_ROLE) {
        require(!publicSaleStarted, "Public sale already started");
        publicSaleStarted = true;
        emit PublicSaleStarted();
    }

    function giveaway(uint32[] calldata pixels, bytes calldata colors, address mintTo) public onlyRole(MANAGER_ROLE) {
        mintInternal(pixels, colors, mintTo);
    }

    function mint(uint32[] calldata pixels, bytes calldata colors) public payable {
        require(publicSaleStarted, "Public sale not started");

        require(msg.value == pixels.length * price, "Amount of Ether sent is not correct");

        mintInternal(pixels, colors, msg.sender);
    }

    function mintWhitelist(uint32[] calldata pixels, bytes calldata colors) public payable {
        require(whitelistSaleStarted, "Whitelist sale not started");

        uint pixelsToPayFor = pixels.length;
        bool whiteListed = false;

        (bool tokensExists, uint claimedPixels) = claimPixelsFromTokens(
            GM420,
            claimedGM420PixelsByToken,
            GM420_PIXELS_PER_TOKEN,
            pixelsToPayFor
        );

        pixelsToPayFor -= claimedPixels;
        if(tokensExists)
            whiteListed = true;

        (tokensExists, claimedPixels) = claimPixelsFromTokens(
            S33ds,
            claimedS33dsPixelsByToken,
            S33DS_PIXELS_PER_TOKEN,
            pixelsToPayFor
        );

        pixelsToPayFor -= claimedPixels;
        if(tokensExists)
            whiteListed = true;

        (tokensExists, claimedPixels) = claimPixelsFromTokens(
            BrickBreakers,
            claimedBrickBreakersPixelsByToken,
            BRICK_BREAKERS_PIXELS_PER_TOKEN,
            pixelsToPayFor
        );

        pixelsToPayFor -= claimedPixels;
        if(tokensExists)
            whiteListed = true;

        require(whiteListed, "Not whitelisted");
        require(msg.value == pixelsToPayFor * price, "Amount of Ether sent is not correct");

        mintInternal(pixels, colors, msg.sender);
    }

    function claimPixelsFromTokens(
        IERC721Enumerable tokensContract,
        mapping(uint => uint) storage claimedPixelsByToken,
        uint maxFreePixelsPerToken,
        uint pixelsToPayFor
    )
        private returns (
            bool tokensExists,
            uint claimedFreePixels
        )
    {
        tokensExists = false;
        claimedFreePixels = 0;

        uint tokens = tokensContract.balanceOf(msg.sender);
        tokensExists = tokens > 0;

        for(uint i = 0; i < tokens; i++) {
            uint token = tokensContract.tokenOfOwnerByIndex(msg.sender, i);
            uint freePixelsToClaimFromToken = maxFreePixelsPerToken - claimedPixelsByToken[token];

            if(pixelsToPayFor < freePixelsToClaimFromToken)
                freePixelsToClaimFromToken = pixelsToPayFor;

            pixelsToPayFor -= freePixelsToClaimFromToken;
            claimedPixelsByToken[token] += freePixelsToClaimFromToken;

            claimedFreePixels += freePixelsToClaimFromToken;
        }
    }

    function mintInternal(uint32[] calldata pixels, bytes calldata colors, address mintTo) private {
        require(pixels.length == colors.length, "pixels and colors should be of equal length");
        require(pixels.length > 0, "Must mint at least 1 pixel");
        require(pixels.length <= MAX_PIXELS_PER_MINT, "Can't mint more than 1024 pixels");

        for(uint i = 0; i < pixels.length; i++) {
            uint32 pixel = pixels[i];
            uint8 color = uint8(colors[i]);

            require(pixel < TOTAL_PIXELS, "Invalid pixel");
            require(color < COLORS_COUNT, "Invalid color");
            require(pixelToChunk[pixel] == 0, "Pixel already minted");

            pixelToColor[pixel] = color;
            pixelToChunk[pixel] = nextChunkToken;
        }

        chunkToPixels[nextChunkToken] = pixels;

        _safeMint(mintTo, nextChunkToken);
        nextChunkToken++;
        
        emit PixelsChanged(pixels, colors);
    }

    function setPixelsColor(uint32[] calldata pixels, bytes calldata colors) public {
        require(pixels.length == colors.length, "pixels and colors should be of equal length");
        require(pixels.length > 0, "Must set at least 1 pixel");

        for(uint i = 0; i < pixels.length; i++) {
            uint32 pixel = pixels[i];
            uint8 color = uint8(colors[i]);

            require(ownerOf(pixelToChunk[pixel]) == msg.sender, "Must own pixel to set its color");
            require(color < COLORS_COUNT, "Invalid color");

            pixelToColor[pixel] = color;
        }

        emit PixelsChanged(pixels, colors);
    }

    function getPixels(uint index, uint count) public view returns (bytes memory result) {
        result = new bytes(count);
        for(uint i = 0; i < count; i++) {
            result[i] = bytes1(pixelToColor[index + i]);
        }
    }

    function getChunksOwner(uint index, uint count) public view returns (address[] memory result) {
        result = new address[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = ownerOf(index + i);
        }
    }

    function getPixelsChunk(uint index, uint count) public view returns (uint32[] memory result) {
        result = new uint32[](count);
        for(uint i = 0; i < count; i++) {
            uint32 chunk = pixelToChunk[index + i];
            result[i] = chunk;
        }
    }

    function getChunkPixels(uint32 chunk) public view returns (uint32[] memory result) {
        return chunkToPixels[chunk];
    }

    function withdraw() public onlyRole(MANAGER_ROLE) {
        uint balance = address(this).balance;
        (bool success, ) = payable(WITHDRAW_ADDRESS).call{value: balance}("");
        require(success, "Failed transfer");
    }

    function setPrice(uint newPrice) public onlyRole(MANAGER_ROLE) {
        price = newPrice;
        emit PriceChanged(newPrice);
    }

    function setBaseExternalUrl(string calldata newBaseExternalUrl) public onlyRole(MANAGER_ROLE) {
        baseExternalUrl = newBaseExternalUrl;
    }
    
    fallback() external payable { }
    
    receive() external payable { }

    // URI generation

    function tokenURI(uint tokenId) override public view returns (string memory) {
        string[16] memory colorsHex = ["#000000", "#898D90", "#D4D7D9", "#FFFFFF", "#FF4500", "#FFA800", "#FFD635", "#00A268", "#7EED56", "#2450A4", "#3690EA", "#51E9F4", "#811E9F", "#B44AC0", "#FF99AA", "#9C6926"];

        uint32[] memory pixels = chunkToPixels[uint32(tokenId)];

        uint32 minX = uint32(CANVAS_WIDTH);
        uint32 minY = uint32(CANVAS_HEIGHT);
        uint32 maxX = 0;
        uint32 maxY = 0;

        for(uint i = 0; i < pixels.length; i++) {
            uint32 pixel = pixels[i];
            uint32 x = uint32(pixel % CANVAS_WIDTH);
            uint32 y = uint32(pixel / CANVAS_WIDTH);

            if(x < minX)
                minX = x;

            if(y < minY)
                minY = y;

            if(x > maxX)
                maxX = x;

            if(y > maxY)
                maxY = y;
        }

        uint32 width = maxX - minX + 1;
        uint32 height = maxY - minY + 1;

        string memory svgData =  string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='", Strings.toString(width * SVG_PIXEL_SIZE), "' height='", Strings.toString(height * SVG_PIXEL_SIZE), "'>"));

        for(uint i = 0; i < pixels.length; i++) {
            uint32 pixel = pixels[i];

            svgData = string(abi.encodePacked(svgData,
            "<rect x='", Strings.toString((pixel % CANVAS_WIDTH - minX) * SVG_PIXEL_SIZE), "' y='", Strings.toString((pixel / CANVAS_WIDTH - minY) * SVG_PIXEL_SIZE), "' fill='", colorsHex[pixelToColor[pixel]], "' width='", SVG_PIXEL_SIZE_STR, "' height='", SVG_PIXEL_SIZE_STR, "' />"));
        }

        svgData = string(abi.encodePacked(svgData,
            "</svg>"));

        string memory json = string(abi.encodePacked(
            '{'
            '"name": "Pixel Art #', Strings.toString(tokenId), '",'
            '"description": "**Pixel Art #', Strings.toString(tokenId), '**  \\n*', Strings.toString(pixels.length), ' pixels on blockchain*  \\n\\nThis amazing fully on-chain ', Strings.toString(width), 'x', Strings.toString(height), ' art piece was minted on **re:Place**, the 1 million on-chain pixels NFT project  \\n\\nCheck out the full canvas - ', baseExternalUrl, '",'
        ));

        json = string(abi.encodePacked(
            json,
            '"image_data": "data:image/svg+xml;base64,', Base64.encode(bytes(svgData)), '",'
            '"external_url": "', baseExternalUrl, '?pixelArt=', Strings.toString(tokenId), '",'
        ));

        json = string(abi.encodePacked(
            json,
            '"attributes":['
            '{"trait_type": "X", "value": "', Strings.toString(minX), '"},'
            '{"trait_type": "Y", "value": "', Strings.toString(minY), '"},'
            '{"trait_type": "Width", "value": "', Strings.toString(width), '"},'
            '{"trait_type": "Height", "value": "', Strings.toString(height), '"},'
            '{"trait_type": "Pixels", "value": "', Strings.toString(pixels.length), '"}'
            ']'
            '}'
        ));

        return string(abi.encodePacked('data:application/json,', json));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}