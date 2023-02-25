// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Utils.sol";
import "./TokenRenderer.sol";

contract ScoutRankTokenRenderer is Ownable, TokenRenderer {
    string private _baseURI;
    uint256 private _minimum;

    constructor(string memory baseURI, uint minimum) {
        _baseURI = baseURI;
        _minimum = minimum;
    }

    // URI
    // ---

    function getBaseURI() public view returns (string memory) {
        return _baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI = newBaseURI;
    }

    function _getName(
        uint256 tokenId,
        string memory name
    ) internal pure returns (string memory) {
        return
            string(abi.encodePacked(name, " #", Utils.toString(tokenId + 1)));
    }

    function getTokenURI(
        uint256 tokenId,
        string memory name
    ) public view override returns (string memory) {
        bytes memory json = abi.encodePacked(
            '{"name": "',
            _getName(tokenId, name),
            '", "description": "The ',
            name,
            " rank is awarded to Daylight Scouts who have submitted ",
            Utils.toString(_minimum),
            " or more accepted abilities. ",
            name,
            ' holders get access to special features on Daylight.xyz. Together, the Scout community works to help everyone discover what their wallet address can do.\\n\\nThis collection is soulbound.", "image": "',
            _baseURI,
            '"}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Utils.base64Encode(json)
                )
            );
    }
}