/* solhint-disable quotes */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnonymiceBadgesData.sol";
import "./IAnonymiceBadges.sol";
import "./POAPLibrary.sol";

contract AnonymiceBadgesDescriptor is Ownable {
    address public anonymiceBadgesDataAddress;
    address public anonymiceBadgesAddress;

    function tokenURI(uint256 id) public view returns (string memory) {
        string memory name = string(
            abi.encodePacked('{"name": "Anonymice Collector Card #', POAPLibrary._toString(id))
        );

        address wallet = IAnonymiceBadges(anonymiceBadgesAddress).ownerOf(id);
        uint256[] memory poaps = IAnonymiceBadges(anonymiceBadgesAddress).getBoardPOAPs(wallet);
        uint256 boardId = IAnonymiceBadges(anonymiceBadgesAddress).currentBoard(wallet);
        string memory boardName = IAnonymiceBadges(anonymiceBadgesAddress).boardNames(wallet);

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
                                    POAPLibrary.encode(bytes(buildSvg(boardId, poaps, boardName, false))),
                                    '","attributes": [',
                                    buildAttributes(poaps),
                                    "],",
                                    '"description": "Soulbound Collector Cards and Unlockable Badges. 100% on-chain, no APIs, no IPFS, no transfers. Just code."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function buildSvg(
        uint256 boardId,
        uint256[] memory poaps,
        string memory boardName,
        bool isPreview
    ) public view returns (string memory) {
        POAPLibrary.Board memory board = IAnonymiceBadges(anonymiceBadgesAddress).getBoard(boardId);

        string memory viewBox = string(
            abi.encodePacked("0 0 ", POAPLibrary._toString(board.width), " ", POAPLibrary._toString(board.height))
        );
        string memory svg = '<svg id="board" width="100%" height="100%" version="1.1" viewBox="';

        svg = string(
            abi.encodePacked(
                svg,
                viewBox,
                '" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                '<image x="0" y="0" width="100%" height="100%" image-rendering="pixelated" preserveAspectRatio="xMinYMin" xlink:href="',
                IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBoardImage(board.id),
                '" />'
            )
        );
        for (uint256 index = 0; index < board.slots.length; index++) {
            svg = string(
                abi.encodePacked(
                    svg,
                    '<g transform="translate(',
                    POAPLibrary._toString(board.slots[index].x),
                    ", ",
                    POAPLibrary._toString(board.slots[index].y),
                    ")"
                )
            );
            uint32 scale = board.slots[index].scale;
            if (scale != 0) {
                uint32 base = scale / 100;
                uint32 decimals = scale % 100;
                svg = string(
                    abi.encodePacked(
                        svg,
                        " scale(",
                        POAPLibrary._toString(base),
                        ".",
                        POAPLibrary._toString(decimals),
                        ")"
                    )
                );
            }
            if (isPreview && poaps[index] == 0) {
                svg = string(abi.encodePacked(svg, '">', _getSlotPlaceholder(index + 1), "</g>"));
            } else {
                svg = string(abi.encodePacked(svg, '">', _getBadgeImage(poaps[index]), "</g>"));
            }
        }
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="50%" y="40" text-anchor="middle" font-weight="bold" font-size="32" font-family="Pixeled">',
                boardName,
                "</text>"
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                "<style>",
                "@font-face {font-family: Pixeled;font-style: normal;src: url(",
                IAnonymiceBadgesData(anonymiceBadgesDataAddress).getFontSource(),
                ") format('truetype')}",
                "</style>"
            )
        );
        svg = string(abi.encodePacked(svg, "</svg>"));
        return svg;
    }

    function buildAttributes(uint256[] memory poaps) public view returns (string memory) {
        string memory svg = "";
        bool hasAny = false;
        for (uint256 index = 0; index < poaps.length; index++) {
            if (poaps[index] != 0) {
                string memory badgeName = _getBadgeName(poaps[index]);
                svg = string(abi.encodePacked(svg, '{"value": "', badgeName, '"},'));
                hasAny = true;
            }
        }
        // if has any, remove the last comma
        if (hasAny) {
            svg = POAPLibrary.substring(svg, 0, bytes(svg).length - 1);
        }

        return svg;
    }

    function badgeImages(uint256 badgeId) external view returns (string memory) {
        return IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBadge(badgeId).image;
    }

    function boardImages(uint256 badgeId) external view returns (string memory) {
        return IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBoardImage(badgeId);
    }

    function _getBadgeImage(uint256 badgeId) internal view returns (string memory) {
        IAnonymiceBadgesData.Badge memory badge = IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBadge(badgeId);

        return
            string(
                abi.encodePacked(
                    '<image width="128" height="128" image-rendering="pixelated" preserveAspectRatio="xMinYMin" xlink:href="',
                    badge.image,
                    '" />',
                    '<text x="64" fill="white" y="142" text-anchor="middle" font-weight="bold" font-family="Pixeled">',
                    badge.nameLine1,
                    "</text>",
                    '<text x="64" fill="white" y="158" text-anchor="middle" font-weight="bold" font-family="Pixeled">',
                    badge.nameLine2,
                    "</text>"
                )
            );
    }

    function _getBadgeName(uint256 badgeId) internal view returns (string memory) {
        IAnonymiceBadgesData.Badge memory badge = IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBadge(badgeId);

        return string(abi.encodePacked(badge.nameLine1, " ", badge.nameLine2));
    }

    function _getSlotPlaceholder(uint256 slot) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBadgePlaceholder(),
                    '<text x="64" y="70" text-anchor="middle" id="slot" fill="white" font-weight="bold" font-size="16px" font-family="Pixeled">Slot ',
                    POAPLibrary._toString(slot),
                    "</text>"
                )
            );
    }

    function setAnonymiceBadgesAddress(address _anonymiceBadgesAddress) external onlyOwner {
        anonymiceBadgesAddress = _anonymiceBadgesAddress;
    }

    function setAnonymiceBadgesDataAddress(address _anonymiceBadgesDataAddress) external onlyOwner {
        anonymiceBadgesDataAddress = _anonymiceBadgesDataAddress;
    }
}
/* solhint-enable quotes */