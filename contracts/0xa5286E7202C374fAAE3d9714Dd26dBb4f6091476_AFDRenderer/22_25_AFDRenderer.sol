// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IFileStore} from "ethfs/IFileStore.sol";
import {File} from "ethfs/File.sol";
import {AFundamentalDispute} from "./AFD.sol";
import {IRenderer} from "./IRenderer.sol";

/// @author frolic.eth
/// @title  A Fundamental Dispute renderer
contract AFDRenderer is IRenderer {
    AFundamentalDispute public immutable token;
    IFileStore public immutable fileStore;

    event Initialized();

    constructor(AFundamentalDispute _token, IFileStore _fileStore) {
        token = _token;
        fileStore = _fileStore;
        emit Initialized();
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory addressString = toString(uint160(address(this)));
        string memory tokenIdString = toString(tokenId);
        string memory seedString = toString(token.tokenSeed(tokenId));

        return string.concat(
            "data:application/json,",
            "%7B%22name%22%3A%22A%20Fundamental%20Dispute%20",
            tokenIdString,
            "%2F436%22%2C%22description%22%3A%22%E2%80%94%20a%20series%20of%20digital%20sunsets%20living%20inside%20the%20world%20computer.%5Cn%5Cn%20%20Art%20by%20%40generativelight%2C%20website%20and%20contracts%20by%20%40frolic%22%2C%22external_url%22%3A%22https%3A%2F%2Fafundamentaldispute.com%2Fart%2F",
            tokenIdString,
            "%22%2C%22image%22%3A%22https%3A%2F%2Fafundamentaldispute.com%2Fapi%2Fart-placeholder%2F",
            tokenIdString,
            "%3F",
            addressString,
            "%22%2C%22animation_url%22%3A%22data%3Atext%2Fhtml%2C%250A%2520%2520%253Cmeta%2520charset%253D%2522UTF-8%2522%253E%250A%2520%2520%253Cmeta%2520name%253D%2522viewport%2522%2520content%253D%2522width%253Ddevice-width%252C%2520initial-scale%253D1.0%2522%253E%250A%2520%2520%253Ctitle%253E",
            tokenIdString,
            "%252F436%2520%25E2%2580%2594%2520A%2520Fundamental%2520Dispute%253C%252Ftitle%253E%250A%250A%2520%2520%253Cstyle%253E%250A%2520%2520%2520%2520*%2520%257B%250A%2520%2520%2520%2520%2520%2520box-sizing%253A%2520border-box%253B%250A%2520%2520%2520%2520%257D%250A%2520%2520%2520%2520html%252C%250A%2520%2520%2520%2520body%2520%257B%250A%2520%2520%2520%2520%2520%2520width%253A%2520100vw%253B%250A%2520%2520%2520%2520%2520%2520height%253A%2520100vh%253B%250A%2520%2520%2520%2520%2520%2520margin%253A%25200%253B%250A%2520%2520%2520%2520%2520%2520background%253A%2520%2523111%253B%250A%2520%2520%2520%2520%257D%250A%2520%2520%2520%2520canvas%2520%257B%250A%2520%2520%2520%2520%2520%2520display%253A%2520block%253B%250A%2520%2520%2520%2520%2520%2520margin%253A%2520auto%253B%250A%2520%2520%2520%2520%257D%250A%2520%2520%2520%2520body.fullscreen%2520canvas%2520%257B%250A%2520%2520%2520%2520%2520%2520width%253A%25201200px%2520!important%253B%250A%2520%2520%2520%2520%2520%2520height%253A%25201650px%2520!important%253B%250A%2520%2520%2520%2520%257D%250A%2520%2520%2520%2520body%253Anot(.fullscreen)%2520%257B%250A%2520%2520%2520%2520%2520%2520overflow%253A%2520hidden%253B%250A%2520%2520%2520%2520%257D%250A%2520%2520%2520%2520body%253Anot(.fullscreen)%2520canvas%2520%257B%250A%2520%2520%2520%2520%2520%2520padding%253A%25208vmin%253B%250A%2520%2520%2520%2520%2520%2520width%253A%2520100%2525%2520!important%253B%250A%2520%2520%2520%2520%2520%2520height%253A%2520100%2525%2520!important%253B%250A%2520%2520%2520%2520%2520%2520object-fit%253A%2520contain%253B%250A%2520%2520%2520%2520%257D%250A%2520%2520%253C%252Fstyle%253E%250A%250A%2520%2520%253Cscript%253E%250A%2520%2520%2520%2520const%2520seed%2520%253D%2520",
            seedString,
            "%253B%250A%250A%2520%2520%2520%2520document.addEventListener(%2522click%2522%252C%2520(event)%2520%253D%253E%2520%257B%250A%2520%2520%2520%2520%2520%2520const%2520x%2520%253D%2520event.clientX%2520%252F%2520document.body.clientWidth%253B%250A%2520%2520%2520%2520%2520%2520const%2520y%2520%253D%2520event.clientY%2520%252F%2520document.body.clientHeight%253B%250A%2520%2520%2520%2520%2520%2520document.body.classList.toggle(%2522fullscreen%2522)%253B%250A%2520%2520%2520%2520%2520%2520document.body.scrollTo(%257B%250A%2520%2520%2520%2520%2520%2520%2520%2520left%253A%2520document.body.scrollWidth%2520*%2520x%2520-%2520document.body.clientWidth%2520%252F%25202%252C%250A%2520%2520%2520%2520%2520%2520%2520%2520top%253A%2520document.body.scrollHeight%2520*%2520y%2520-%2520document.body.clientHeight%2520%252F%25202%250A%2520%2520%2520%2520%2520%2520%257D)%253B%250A%2520%2520%2520%2520%257D)%253B%250A%2520%2520%253C%252Fscript%253E%250A%250A%2520%2520%253Cscript%2520type%253D%2522text%252Fjavascript%252Bgzip%2522%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C",
            fileStore.getFile("p5-v1.5.0.min.js.gz").read(),
            "%2522%253E%253C%252Fscript%253E%250A%2520%2520%253Cscript%2520type%253D%2522text%252Fjavascript%252Bgzip%2522%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C",
            fileStore.getFile("afd.min.js.gz").read(),
            "%2522%253E%253C%252Fscript%253E%250A%2520%2520%253Cscript%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C",
            fileStore.getFile("gunzipScripts-0.0.1.js").read(),
            "%2522%253E%253C%252Fscript%253E%250A%22%7D"
        );
    }

    function fullscreenHtml(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenIdString = toString(tokenId);
        string memory seedString = toString(token.tokenSeed(tokenId));

        return string.concat(
            "<meta charset=\"UTF-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n  <title>",
            tokenIdString,
            "/436 &mdash; A Fundamental Dispute</title>\n\n  <style>\n    * {\n      box-sizing: border-box;\n    }\n    html,\n    body {\n      width: 100vw;\n      height: 100vh;\n      margin: 0;\n      background: #111;\n      overflow: hidden;\n    }\n    canvas {\n      display: block;\n      margin: auto;\n      width: 100% !important;\n      height: 100% !important;\n      object-fit: contain;\n    }\n  </style>\n\n  <script>\n    const seed = ",
            seedString,
            ";\n  </script>\n\n  <script type=\"text/javascript+gzip\" src=\"data:text/javascript;base64,",
            fileStore.getFile("p5-v1.5.0.min.js.gz").read(),
            "\"></script>\n  <script type=\"text/javascript+gzip\" src=\"data:text/javascript;base64,",
            fileStore.getFile("afd.min.js.gz").read(),
            "\"></script>\n  <script src=\"data:text/javascript;base64,",
            fileStore.getFile("gunzipScripts-0.0.1.js").read(),
            "\"></script>"
        );
    }

    function toString(uint256 value)
        internal
        pure
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}