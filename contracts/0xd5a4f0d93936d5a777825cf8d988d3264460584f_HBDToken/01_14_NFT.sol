// ~~~~~~~~~~~~~~~~~~~~~~~JJ~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~:~~:~~:~~:~~:~~:~~:JJ""JJ~~:~~:~~:~~:~~:~~:~~:~~
// ~:~~:~~:~~:~~:~~:~~JJMM  MMJJ:~~:~~:~~:~~:~~:~~:~~
// ~~~:~~~~~:~~~~~:~JJHMMM  MMHHJJ~~:~~~:~~~~:~~~:~~:
// ~~:~~:~:~~~:~:~JJMM`.MM  MM  MMJJ~~:~~~:~~~:~~~~~~
// ~:~~~~:~~:~~:~JMM``.MM         MMJJ~~:~~:~~~:~:~:~
// ~~~:~~~~:~~~~(MM`.``MM      `..ZZMM((~~~~:~~~~~:~~
// ~~:~~:~~~~:~~MM.``.`MM  `   .UV<<VVMM~:~~:~:~~~~~:
// ~:~~~:~:~~:~:77gg``gM7     zZ  wwgg77~~:~~~~::~~:~
// ~~~:~~~~:~~~~~~TTggMM`  `uz;;yuggTT~~~~~:~~~~~:~~~
// ~~:~~~:~~~:~~~~~~YYMN`     Xy  MM~~~:~:~~:~:~~~:~~
// ~:~~:~~:~~~:~:~:~~~MM       `((""~~:~~~:~~~~:~~~:~
// ~~~~~:~~:~~~:~~~_((""        ""JJ~:~~~~~~:~~~:~~~~
// ~:~~:~~~~:~~~~:..ll~`... ...   MM~~~:~:~~~:~~~:~:~
// ~~:~~~:~~~:~~:~~.l=-.""" """.. MM~:~~:~~:~~:~~~:~~
// ~~~:~~~:~~:~~~~:~Mg~```     `` MM~~:~~~:~~~~:~~~~:
// ~:~~:~~:~~~:~~:~~MM~```.<      MM~~~~~:~~:~~:~:~~~
// ~~~~~:~~:~~~:~~~~MM~`` .<      MM~:~:~~~~~:~~~~:~~
// ~~:~~~~~~~~~~~:~~MM~``  <`     MM~~~~~~:~~~~~:~~~~
// ~~~:~~:~~:~:~~~:~MM~``         MM~~:~~:~~:~~:~~~:~
// ~~~~~~~~:~~~:~~~~MM~``         MM~~~~~~~~~~~~~~:~~
// ~:~~:~~~~~~~~~:~~MM~```        MM~:~~:~~:~~:~~~~~~
// ~~~:~~:~~:~~:~~~~MM~``         MM~~~:~~:~~:~~:~~:~
// ~~~~~~~:~~~:~~~:~MM~``         MM~~~~~~~~~~~~~:~~~
// ~:~~:~~~~~~~~~~~~MM~```        MM~:~~:~~:~~:~~~~~~
// ~~~:~~:~~:~~:~:~~MM~``         MM~~~:~~~~~~~:~~:~~

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HBDToken is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("HBDToken", "HBD") {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256) public view override returns (string memory) {
        uint256 BDTIMESTAMP = 1695740400;

        uint256 diffDays = (BDTIMESTAMP - block.timestamp) / (60 * 60 * 24);

        uint256 diffHours = ((BDTIMESTAMP - block.timestamp) % (60 * 60 * 24)) /
            (60 * 60);

        uint256 diffMinutes = (((BDTIMESTAMP - block.timestamp) %
            (60 * 60 * 24)) % (60 * 60)) / 60;

        uint256 diffSeconds = (((BDTIMESTAMP - block.timestamp) %
            (60 * 60 * 24)) % (60 * 60)) % 60;

        bytes memory message = block.timestamp < BDTIMESTAMP
            ? abi.encodePacked(
                '<text x="50%" y="50%" text-anchor="middle" dominant-baseline="central" font-size="150px" font-weight="bold" font-family="sans-serif">',
                Strings.toString(diffDays),
                "D",
                "</text>",
                '<text x="50%" y="75%" text-anchor="middle" dominant-baseline="central" font-size="50px" font-weight="bold" font-family="sans-serif">',
                Strings.toString(diffHours),
                "H",
                " ",
                Strings.toString(diffMinutes),
                "M",
                " ",
                Strings.toString(diffSeconds),
                "S",
                "</text>"
            )
            : abi.encodePacked(
                unicode'<text x="50%" y="50%" text-anchor="middle" dominant-baseline="central" font-size="100px" font-weight="bold" font-family="sans-serif">🎉HBD🎉</text>'
            );

        bytes memory image = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" height="500" width="500">',
            '<image height="500" width="500" href="data:image/png;base64,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" />',
            message,
            "</svg>"
        );

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Nazuna Birthday Countdown",',
            unicode'"description": "Happy Birthday. Full On-chain Dynamic NFT.",',
            '"image": "data:image/svg+xml;base64,',
            Base64.encode(image),
            '"',
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }
}