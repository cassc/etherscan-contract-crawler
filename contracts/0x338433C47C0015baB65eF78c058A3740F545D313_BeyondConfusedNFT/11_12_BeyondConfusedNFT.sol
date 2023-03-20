//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*
__________                                .___   __  .__             _________                _____                       .___
\______   \ ____ ___.__. ____   ____    __| _/ _/  |_|  |__   ____   \_   ___ \  ____   _____/ ____\_ __  ______ ____   __| _/
 |    |  _// __ <   |  |/  _ \ /    \  / __ |  \   __\  |  \_/ __ \  /    \  \/ /  _ \ /    \   __\  |  \/  ___// __ \ / __ | 
 |    |   \  ___/\___  (  <_> )   |  \/ /_/ |   |  | |   Y  \  ___/  \     \___(  <_> )   |  \  | |  |  /\___ \\  ___// /_/ | 
 |______  /\___  > ____|\____/|___|  /\____ |   |__| |___|  /\___  >  \______  /\____/|___|  /__| |____//____  >\___  >____ | 
        \/     \/\/                \/      \/             \/     \/          \/            \/                \/     \/     \/ 
*/

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BeyondConfusedNFT is ERC721 {
    using Strings for uint8;
    uint256 private _tokenIdCounter = 0;
    uint256 public constant PRICE = 10**16; // 0.01 ETH
    address artist = 0x55e2780588aa5000F464f700D2676fD0a22Ee160;

    struct Color {
        uint8 r;
        uint8 g;
        uint8 b;
    }

    constructor() ERC721("BeyondConfusedDeputy", "BCD") {}

    function buy() public payable returns (uint256) {
        require(msg.value == PRICE, "Incorrect Ether amount sent");
        require(_tokenIdCounter < 1000, "All NFTs have been minted");

        // Transfer the Ether to the contract owner
        payable(artist).transfer(msg.value);
 
        // Mint the NFT to the buyer
        return mintNFT(msg.sender);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory svg = _generateSVG(tokenId);
        string memory dataURI = _generateDataURI(svg);

        return dataURI;
    }

    function _generateDataURI(string memory svg) internal pure returns (string memory) {
        string memory dataURI = string(abi.encodePacked("data:image/svg+xml;utf8,", svg));
        return dataURI;
    }

    function _generateSVG(uint256 tokenId) public view returns (string memory) {
        Color memory color = generateColor(tokenId);
        Color memory color2 = generateComplementaryColor(color);

        string memory colorString = string(
            abi.encodePacked(
                "rgb(",
                color.r.toString(),
                ",",
                color.g.toString(),
                ",",
                color.b.toString(),
                ")"
            )
        );

        string memory colorString2 = string(
            abi.encodePacked(
                "rgb(",
                color2.r.toString(),
                ",",
                color2.g.toString(),
                ",",
                color2.b.toString(),
                ")"
            )
        );

        string memory arrowColorString;
        uint256 colorIndex = tokenId % 3;
        if (colorIndex == 0) {
            arrowColorString = "rgb(255,0,0)"; // Red
        } else if (colorIndex == 1) {
            arrowColorString = "rgb(0,255,0)"; // Green
        } else {
            arrowColorString = "rgb(0,0,255)"; // Blue
        } 

        string memory output = string(abi.encodePacked('<?xml version="1.0" encoding="UTF-8"?><svg id="Layer_1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 313.47 291.42"><defs><style>.cls-1,.cls-2{stroke-width:5px;}.cls-1,.cls-2,.cls-3,.cls-4,.cls-5{stroke:#000;stroke-miterlimit:10;}.cls-1,.cls-4{fill:',colorString,';}.cls-2,.cls-5{fill:',colorString2,';}.cls-3{fill:',arrowColorString,';stroke-width:4px;}.cls-4,.cls-5{stroke-width:7px;}</style></defs><g><path class="cls-4" d="M157.36,157.01s20.92,10.66,31.77,10.99,13.51-5.11,16.62-5.49,9.31,1.99,9.31,9.84c0,7.85,3.65,63.72-6.03,75.96-9.68,12.23-39.35,39.26-51.35,39.62h-.72c-12-.37-41.68-27.39-51.35-39.62-9.68-12.23-6.03-68.1-6.03-75.96s6.21-10.22,9.31-9.84,5.76,5.83,16.62,5.49,31.77-10.99,31.77-10.99h.08Z"/><path class="cls-5" d="M157.1,186.77s11.29,5.75,17.16,5.93,7.3-2.76,8.97-2.97,5.03,1.08,5.03,5.32,1.97,34.41-3.25,41.02c-5.23,6.61-21.25,21.2-27.73,21.4h-.39c-6.48-.2-22.5-14.79-27.73-21.4s-3.25-36.78-3.25-41.02,3.35-5.52,5.03-5.32,3.11,3.15,8.97,2.97,17.16-5.93,17.16-5.93h.04Z"/><circle class="cls-4" cx="157.32" cy="222.12" r="10"/></g><g><path class="cls-1" d="M264.06,35.15s16.81,8.56,25.53,8.83,10.86-4.11,13.35-4.41,7.48,1.6,7.48,7.91c0,6.31,2.93,51.2-4.84,61.03-7.78,9.83-31.62,31.54-41.26,31.84h-.58c-9.65-.29-33.49-22.01-41.26-31.84-7.78-9.83-4.84-54.73-4.84-61.03s4.99-8.22,7.48-7.91,4.63,4.68,13.35,4.41,25.53-8.83,25.53-8.83h.06Z"/><path class="cls-2" d="M263.85,59.06s9.08,4.62,13.78,4.77,5.86-2.22,7.21-2.38,4.04,.86,4.04,4.27c0,3.41,1.58,27.65-2.61,32.96-4.2,5.31-17.07,17.03-22.28,17.19h-.31c-5.21-.16-18.08-11.88-22.28-17.19s-2.61-29.55-2.61-32.96,2.69-4.44,4.04-4.27,2.5,2.53,7.21,2.38,13.78-4.77,13.78-4.77h.03Z"/><circle class="cls-1" cx="264.03" cy="87.47" r="8.03"/></g><g><path class="cls-1" d="M49.47,42.9s16.81,8.56,25.53,8.83,10.86-4.11,13.35-4.41,7.48,1.6,7.48,7.91c0,6.31,2.93,51.2-4.84,61.03-7.78,9.83-31.62,31.54-41.26,31.84h-.58c-9.65-.29-33.49-22.01-41.26-31.84C.11,106.43,3.04,61.53,3.04,55.22s4.99-8.22,7.48-7.91,4.63,4.68,13.35,4.41,25.53-8.83,25.53-8.83h.06Z"/><path class="cls-2" d="M49.26,66.81s9.08,4.62,13.78,4.77,5.86-2.22,7.21-2.38,4.04,.86,4.04,4.27c0,3.41,1.58,27.65-2.61,32.96-4.2,5.31-17.07,17.03-22.28,17.19h-.31c-5.21-.16-18.08-11.88-22.28-17.19s-2.61-29.55-2.61-32.96,2.69-4.44,4.04-4.27,2.5,2.53,7.21,2.38,13.78-4.77,13.78-4.77h.03Z"/><circle class="cls-1" cx="49.44" cy="95.22" r="8.03"/></g><path class="cls-3" d="M83.18,42.82s4.94-29.93,19.32-40.76c1.6-1.2,5.06,15.92,6.84,14.75,12.23-7.98,28.95-14.69,50.59-14.69s37.6,5.63,48.81,12.31c1.76,1.04,2.39-13.38,3.92-12.31,12.69,8.94,18.8,33.91,18.8,33.91,0,0-19.93,4.54-32.37,0-1.8-.66,8.91-10.32,6.9-10.97-11.9-3.83-27.36-7.26-45.01-7.53-17.81-.27-34.74,4.41-48.23,9.81-1.51,.6,8.4,11.16,6.98,11.77-15.29,6.64-36.55,3.7-36.55,3.7Z"/><path class="cls-3" d="M106.7,211.09s-16.09,11.02-27.51,9.16c-1.27-.21,5.14-9.43,3.8-9.74-9.14-2.13-19.7-6.9-29.32-16.94s-14.11-19.95-16-28.13c-.3-1.28-7.28,4.84-7.46,3.65-1.49-9.86,7.38-23.81,7.38-23.81,0,0,10.97,7.23,14.4,15.02,.5,1.13-8.76,.46-8.16,1.68,3.51,7.23,8.8,15.93,16.53,24.24,7.8,8.38,17.49,14.16,26,18.02,.95,.43,1.44-8.86,2.36-8.48,9.88,4.15,17.97,15.32,17.97,15.32Z"/><path class="cls-3" d="M271.51,141.16s11.17,15.98,9.42,27.42c-.19,1.27-9.47-5.05-9.77-3.71-2.04,9.16-6.72,19.76-16.67,29.48s-19.82,14.29-27.97,16.26c-1.28,.31,4.91,7.23,3.72,7.42-9.85,1.59-23.87-7.16-23.87-7.16,0,0,7.12-11.04,14.89-14.54,1.13-.51,.54,8.75,1.76,8.15,7.2-3.58,15.84-8.95,24.08-16.75,8.31-7.87,13.99-17.63,17.77-26.17,.42-.95-8.87-1.36-8.5-2.28,4.05-9.92,15.15-18.11,15.15-18.11Z"/></svg>'));
        return output; 
    }

    function generateColor(uint256 seed) public view returns (Color memory color) {
        uint256 hashValue = uint256(keccak256(abi.encodePacked(seed)));

        color = Color({
            r: uint8(hashValue % 256),
            g: uint8((hashValue / 256) % 256),
            b: uint8((hashValue / (256 * 256)) % 256)
        });

        return color;
    }

    function generateComplementaryColor(Color memory originalColor) public pure returns (Color memory complementaryColor) {
        complementaryColor = Color({
            r: uint8(255 - originalColor.r),
            g: uint8(255 - originalColor.g),
            b: uint8(255 - originalColor.b)
        });

        return complementaryColor;
    }

    function mintNFT(address recipient) internal returns (uint256) {
        _tokenIdCounter = _tokenIdCounter + 1;

        uint256 newTokenId = _tokenIdCounter;
        _mint(recipient, newTokenId);

        return newTokenId;
    }

}