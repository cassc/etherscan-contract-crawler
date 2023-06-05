/*    *                   .                  *               *                      .   .
*   .   *               .               .                          *         .
            .        *         *                   *                                          *
    *                                                        .                             *
                  .        *        .                                *          .
        .   *                               .    *                     .           *

 ██████  ███    ██  ██████ ██   ██  █████  ██ ███    ██ ███████ ████████  █████  ██████  ███████ 
██    ██ ████   ██ ██      ██   ██ ██   ██ ██ ████   ██ ██         ██    ██   ██ ██   ██ ██      
██    ██ ██ ██  ██ ██      ███████ ███████ ██ ██ ██  ██ ███████    ██    ███████ ██████  ███████ 
██    ██ ██  ██ ██ ██      ██   ██ ██   ██ ██ ██  ██ ██      ██    ██    ██   ██ ██   ██      ██ 
 ██████  ██   ████  ██████ ██   ██ ██   ██ ██ ██   ████ ███████    ██    ██   ██ ██   ██ ███████ 
                                                                                                
 ~ ~ ~ ~ ~ ~ ~ fully on-chain and procedurally generated svg pixel constellations ~ ~ ~ ~ ~ ~ ~ 
.                *       .                        .                 *                       .
     *         .             *          *                 .              .             .
      .           *    .                       .             *                 *        *
          *      .             .                                     .
    *                   .                  *         *      *                     .           */


//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Utilities.sol";

contract Orion is ERC721A, Ownable {
    uint public price = 5000000000000000;
    uint public maxSupply = 10000;

    constructor() ERC721A("onchainstars", "strs") {}

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function reduceSupply(uint _lowerSupply) external onlyOwner {
        require(_lowerSupply < maxSupply, "New supply must be lower than the current supply");
        maxSupply = _lowerSupply;
    }

    function mint(uint256 quantity) external payable {
        require(msg.value >= price * quantity, "Insufficient fee");
        require(totalSupply() + quantity <= maxSupply, "Exceeds max supply");
        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory name = string(abi.encodePacked("constellation #", utils.uint2str(tokenId)));
    string memory svg = renderSvg(tokenId);
    Galaxy memory galaxy = countStars(tokenId);

    string memory json = string(
      abi.encodePacked(
        '{"name": "',
        name,
        '", "description": "Fully on-chain and procedurally generated svg pixel constellations.", ',
        '"seller_fee_basis_points": 750, ',
        '"fee_recipient": "0x1b525cD89FdF6142891b67c9BA07FFD754862C3D", ',
        '"attributes":[{"trait_type": "big stars", "value": "',
        utils.uint2str(galaxy.bigStars),
        '"}, {"trait_type": "white stars", "value": "',
        utils.uint2str(galaxy.whiteStars),
        '"}, {"trait_type": "red stars", "value": "',
        utils.uint2str(galaxy.redStars),
        '"}, {"trait_type": "blue stars", "value": "',
        utils.uint2str(galaxy.blueStars),
        '"}, {"trait_type": "yellow stars", "value": "',
        utils.uint2str(galaxy.yellowStars),
        '"}], "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(svg)),
        '"}'
      )
    );
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
  }

    struct Galaxy {
        uint seed;
        uint bigStars;
        uint whiteStars;
        uint redStars;
        uint blueStars;
        uint yellowStars;
    }

    function countStars(uint tokenId) private pure returns (Galaxy memory x) {

        // set the possible number of white stars
        uint8[5] memory whiteStarOptions = [
            32, 40, 48, 56, 64
        ];
        
        // set the possible number of red stars
        uint8[100] memory redStarOptions = [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 3
        ];

        // set the possible number of blue stars
        uint8[100] memory blueStarOptions = [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 5
        ];

        // set the possible number of yellow stars
        uint8[100] memory yellowStarOptions = [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 5, 6
        ];

        uint seed = utils.random(tokenId, 111, 999);
        x.seed = seed;
        x.bigStars = utils.random(tokenId, 0, 7);
        x.whiteStars = whiteStarOptions[utils.random(tokenId, 0, 5)];
        x.redStars = redStarOptions[utils.random(tokenId, 0, 100)];
        x.blueStars = blueStarOptions[utils.random(tokenId + seed, 0, 100)];
        x.yellowStars = yellowStarOptions[utils.random(tokenId + seed + 1, 0, 100)];

    }

    function makeSvg(uint tokenId, uint seed, uint bigStars, uint whiteStars, uint redStars, uint blueStars, uint yellowStars) private pure returns (string memory svg) {
        
        // set the possible star opacities for small white stars
        string[10] memory opacity = [
            '0.2', '0.2', '0.2', '0.2',
            '0.4', '0.4', '0.4',
            '0.8', '0.8',
            '1'
        ];
        
        svg = string.concat(
            '<svg id="',
            utils.uint2str(tokenId),
            '" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 64 64" fill="#000"><rect x="0" y="0" width="64" height="64" fill="#000"></rect>'
        );

        for (uint i = 0; i < bigStars; i++) {
            svg = string.concat(
                svg,
                '<rect x="',
                utils.uint2str(utils.random(tokenId + i, 0, 63)),
                '" ',
                'y="',
                utils.uint2str(utils.random(tokenId * i, 0, 63)),
                '" ',
                'width="2" ',
                'height="2" ',
                'fill="#FFFFFF" ',
                'opacity="1"',
                '></rect>'
            );
        }

        for (uint i = 0; i < whiteStars; i++) {
            svg = string.concat(
                svg,
                '<rect x="',
                utils.uint2str(utils.random(seed + i, 0, 64)),
                '" ',
                'y="',
                utils.uint2str(utils.random(seed * i, 0, 64)),
                '" ',
                'width="1" ',
                'height="1" ',
                'fill="#FFFFFF" ',
                'opacity="',
                opacity[utils.random(tokenId + i, 0, 10)],
                '"></rect>'
            );
        }

        for (uint i = 0; i < redStars; i++) {
            svg = string.concat(
                svg,
                '<rect x="',
                utils.uint2str(utils.random(seed + i + 1, 0, 64)),
                '" ',
                'y="',
                utils.uint2str(utils.random(seed * i + 1, 0, 64)),
                '" ',
                'width="1" ',
                'height="1" ',
                'fill="#FF8D8D" ',
                'opacity="1"></rect>'
            );
        }

        for (uint i = 0; i < blueStars; i++) {
            svg = string.concat(
                svg,
                '<rect x="',
                utils.uint2str(utils.random(tokenId + i + 2, 0, 64)),
                '" ',
                'y="',
                utils.uint2str(utils.random(tokenId * i + 2, 0, 64)),
                '" ',
                'width="1" ',
                'height="1" ',
                'fill="#7DD0FF" ',
                'opacity="1"></rect>'
            );
        }

        for (uint i = 0; i < yellowStars; i++) {
            svg = string.concat(
                svg,
                '<rect x="',
                utils.uint2str(utils.random(seed + tokenId + i + 3, 0, 64)),
                '" ',
                'y="',
                utils.uint2str(utils.random(seed * tokenId * i + 3, 0, 64)),
                '" ',
                'width="1" ',
                'height="1" ',
                'fill="#FFE790" ',
                'opacity="1"></rect>'
            );
        }

        svg = string.concat(
            svg,
            "</svg>"
        );

        return svg;
    }

    function renderSvg(uint256 tokenId) internal pure returns (string memory svg) {
        Galaxy memory x = countStars(tokenId);
        svg = makeSvg(tokenId, x.seed, x.bigStars, x.whiteStars, x.redStars, x.blueStars, x.yellowStars);
        return svg;
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}