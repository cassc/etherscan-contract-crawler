// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
    Found some quotes on OSS and decided to share.
    Open Source is important for humanity, it carries us forward, it keeps work focused on what matters.
    I'm sure that Isaac Newton's famous words "If I can see further than anyone else, it is only because I am standing on the shoulders of giants"
    apply to this as well.

    The recent actions taken by those that have led us to believe are the faces of Open Source or are seen as major supporters with the TC situation
    have made me worry. If we don't stand-up for great minds that contribute and compound or knowledge, then we are truly not worthy of their
    contributions.

    I made this contract for myself, as a reminder, to never deviate from my values. If you share these values, then by all means pledge :)

    There are no royalties, no supply limit, no owner.
 */
contract ProtectOpenSource is ERC721 {
    uint256 public currentId;

    string[] private quotes = [
        "Linus Torvalds: In real open source, you have the right to control your own destiny.",
        "Linus Torvalds: In open source, we feel strongly that to really do something well, you have to get a lot of people involved.",
        "Vint Cerf: Information flow is what the Internet is about. Information sharing is power. If you don't share your ideas, smart people can't do anything about them, and you'll remain anonymous and powerless.",
        "Richard Stallman: Proprietary software is an injustice. Sharing is good, and with digital technology, sharing is easy.",
        "Jim Zemlin: We believe open source is a public good and across every industry, we have a responsibility to come together to improve and support the security of open-source software we all depend on.",
        "Philippe Kahn: The power of Open Source is the power of the people. The people rule.",
        "Matt Mullenweg: My own personal dream is that the majority My own personal dream is that the majority of the web runs on open source software.",
        "Brian Behlendorf: In true open source development, there's lots of visibility all the way through the development process.",
        "Mitch Kapor: Open source can propagate to fill all the nooks and crannies that people want it to fill.",
        "Jon Johansen: Basically, if reverse engineering is banned, then a lot of the open source community is doomed to fail.",
        "Richard Stallman: Open source is a development methodology; free software is a social movement.",
        "Matt Mullenweg: The beauty of open-source is that you can pick up right where someone left off and start right there.",
        "Jim Whitehurst: Open source isn't about saving money, it's about doing more stuff, and getting incremental innovation with the finite budget you have.",
        "Larry Ellison: Once open source gets good enough, competing with it would be insane.",
        "Mitch Kapor: The accomplishment of open source is that it is the back end of the web, the invisible part, the part that you don't see as a user.",
        "Peter Fenton: In open-source in general, the power lies in connecting the author of the software directly to users, eliminating the middleman.",
        "Sundar Pichai: Open platforms historically undergo a lot of scrutiny, but there are a lot of advantages to having an open source platform from a security standpoint."
    ];

    function notRandom(string memory t) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(t)));
    }

    function getQuote(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "QUOTES", quotes);
    }

    function pluck(uint256 tokenId, string memory content, string[] memory t) internal pure returns (string memory) {
        uint256 rand = notRandom(string(abi.encodePacked(content, toString(tokenId))));
        return t[rand % t.length];
    }
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(tokenId < currentId, "token does not exist");
        string[7] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { color: white; font-family: helvetica,serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="#000000" /><foreignObject height="100%" width="80%" x="10" y="20" class="base"><div xmlns="http://www.w3.org/1999/xhtml">';

        parts[1] = '<p>Open source is source code that is made freely available for possible modification and redistribution.</p>';

        parts[2] = "<p>Products include permission to use the source code, design documents, or content of the product.</p>";

        parts[3] = "<p>The open-source model is a decentralized software development model that encourages open collaboration.</p>";

        parts[4] = string.concat("<p>",getQuote(tokenId),"</p>");

        parts[5] = '</div></foreignObject></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "PROTECT OPEN SOURCE #', toString(tokenId), '", "description": "Protect Open Source. Take a stance for humanity.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function pledgeToProtect() public  {
        _safeMint(msg.sender, currentId++);
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    constructor() ERC721("PROTECT OPEN SOURCE", "PROTECTOSS") {}
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);
        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}