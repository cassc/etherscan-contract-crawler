/* solhint-disable quotes */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./POAPLibrary.sol";
import "./AnonymicePrisoners.sol";
import "./IAnonymice.sol";

contract AnonymicePrisonersDescriptor is Ownable {
    address public genesisAddress;
    address public prisonersAddress;
    string private _ironbar;
    string private _background;
    string private _ironbarWithMouse;

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        uint256 genesisId = AnonymicePrisoners(prisonersAddress).getPrisonerGenesisId(tokenId);
        bool isBurned = AnonymicePrisoners(prisonersAddress).getIsBurned(tokenId);
        string memory name = string(
            abi.encodePacked('{"name": "Anonymice Prisoners #', POAPLibrary._toString(tokenId))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    POAPLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    POAPLibrary.encode(bytes(buildSvg(genesisId, isBurned))),
                                    '","attributes": [],',
                                    '"description": "Anonymice Prisoners description. Soul bound."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function buildSvg(uint256 genesisId, bool isBurned) public view returns (string memory) {
        string
            memory svg = '<svg id="prisoner" width="100%" height="100%" version="1.1" viewBox="0 0 88 98" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';

        svg = string(
            abi.encodePacked(
                svg,
                '<image x="0" y="0" width="100%" height="100%" image-rendering="pixelated" preserveAspectRatio="xMinYMin" xlink:href="',
                _background,
                '" />'
            )
        );
        if (isBurned) {
            svg = string(
                abi.encodePacked(
                    svg,
                    '<image x="0" y="0" width="100%" height="100%" image-rendering="pixelated" preserveAspectRatio="xMinYMin" xlink:href="',
                    _ironbar,
                    '" />'
                )
            );
        } else {
            string memory genesisHash = IAnonymice(genesisAddress)._tokenIdToHash(genesisId);
            svg = string(
                abi.encodePacked(
                    svg,
                    '<image x="21" y="8" width="48" height="48" image-rendering="pixelated" preserveAspectRatio="xMinYMin" xlink:href="data:image/svg+xml;base64,',
                    POAPLibrary.encode(bytes(IAnonymice(genesisAddress).fpi(genesisHash))),
                    '" />',
                    '<image x="0" y="0" width="100%" height="100%" image-rendering="pixelated" preserveAspectRatio="xMinYMin" xlink:href="',
                    _ironbarWithMouse,
                    '" />'
                )
            );
        }
        svg = string(abi.encodePacked(svg, "</svg>"));
        return svg;
    }

    function setBackground(string memory background) external onlyOwner {
        _background = background;
    }

    function setIronbarWithMouse(string memory ironbarWithMouse) external onlyOwner {
        _ironbarWithMouse = ironbarWithMouse;
    }

    function setIronbar(string memory ironbar) external onlyOwner {
        _ironbar = ironbar;
    }

    function setAddresses(address _genesisAddress, address _prisonersAddress) external onlyOwner {
        genesisAddress = _genesisAddress;
        prisonersAddress = _prisonersAddress;
    }
}