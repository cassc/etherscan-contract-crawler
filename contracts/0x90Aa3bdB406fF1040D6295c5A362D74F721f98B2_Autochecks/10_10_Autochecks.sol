// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC721, IERC721Enumerable, IERC721Metadata} from "forge-std/interfaces/IERC721.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "openzeppelin-contracts/contracts/utils/Base64.sol";
import {Array} from "utils/Array.sol";

/**
 *
 *     ✓    ✓     ✓ ✓✓✓✓✓✓✓ ✓✓✓✓✓✓✓  ✓✓✓✓✓  ✓     ✓ ✓✓✓✓✓✓✓  ✓✓✓✓✓  ✓    ✓  ✓✓✓✓✓
 *    ✓ ✓   ✓     ✓    ✓    ✓     ✓ ✓     ✓ ✓     ✓ ✓       ✓     ✓ ✓   ✓  ✓     ✓
 *   ✓   ✓  ✓     ✓    ✓    ✓     ✓ ✓       ✓     ✓ ✓       ✓       ✓  ✓   ✓
 *  ✓     ✓ ✓     ✓    ✓    ✓     ✓ ✓       ✓✓✓✓✓✓✓ ✓✓✓✓✓   ✓       ✓✓✓     ✓✓✓✓✓
 *  ✓✓✓✓✓✓✓ ✓     ✓    ✓    ✓     ✓ ✓       ✓     ✓ ✓       ✓       ✓  ✓         ✓
 *  ✓     ✓ ✓     ✓    ✓    ✓     ✓ ✓     ✓ ✓     ✓ ✓       ✓     ✓ ✓   ✓  ✓     ✓
 *  ✓     ✓  ✓✓✓✓✓     ✓    ✓✓✓✓✓✓✓  ✓✓✓✓✓  ✓     ✓ ✓✓✓✓✓✓✓  ✓✓✓✓✓  ✓    ✓  ✓✓✓✓✓
 *
 *                                                        by one of the many matts
 */
contract Autochecks is ERC721 {
    address immutable glyphs;
    address immutable receiver;
    uint256 public constant MINIMUM_DONATION = 0.02 ether;
    uint256 private constant CELL_SIZE = 3 * 24;
    // NOTE: ^ check size is 24, but we inline it elsewhere so we can store these strings as constants

    string private constant JSON_PROTOCOL_URI = "data:application/json;base64,";
    string private constant SVG_PROTOCOL_URI = "data:image/svg+xml;base64,";

    string private constant pat =
        '<use href="#c" x="0" y="0" /><use href="#c" x="24" y="0" /><use href="#c" x="48" y="0" /><use href="#c" x="0" y="24" /><use href="#c" x="48" y="24" /><use href="#c" x="0" y="48" /><use href="#c" x="24" y="48" /><use href="#c" x="48" y="48" />';

    string private constant lus =
        '<use href="#c" x="24" y="0" /><use href="#c" x="0" y="24" /><use href="#c" x="24" y="24" /><use href="#c" x="48" y="24" /><use href="#c" x="24" y="48" />';

    string private constant ex =
        '<use href="#c" x="0" y="0" /><use href="#c" x="48" y="0" /><use href="#c" x="24" y="24" /><use href="#c" x="0" y="48" /><use href="#c" x="48" y="48" />';

    string private constant bar =
        '<use href="#c" x="24" y="0" /><use href="#c" x="24" y="24" /><use href="#c" x="24" y="48" />';

    string private constant hep =
        '<use href="#c" x="0" y="24" /><use href="#c" x="24" y="24" /><use href="#c" x="48" y="24" />';

    string private constant bas =
        '<use href="#c" x="0" y="0" /><use href="#c" x="24" y="24" /><use href="#c" x="48" y="48" />';

    string private constant fas =
        '<use href="#c" x="48" y="0" /><use href="#c" x="24" y="24" /><use href="#c" x="0" y="48" />';

    string private constant hax =
        '<use href="#c" x="0" y="0" /><use href="#c" x="24" y="0" /><use href="#c" x="48" y="0" /><use href="#c" x="0" y="24" /><use href="#c" x="24" y="24" /><use href="#c" x="48" y="24" /><use href="#c" x="0" y="48" /><use href="#c" x="24" y="48" /><use href="#c" x="48" y="48" />';

    error DonatePlease();

    constructor(address _glyphs, address _receiver)
        ERC721("Autochecks", unicode"☵✓")
    {
        glyphs = _glyphs;
        receiver = _receiver;
    }

    function mint(uint256 id) external payable {
        if (msg.value < MINIMUM_DONATION) revert DonatePlease();

        IERC721(glyphs).ownerOf(id); // throws if !exists

        SafeTransferLib.safeTransferETH(receiver, msg.value);
        _mint(msg.sender, id);
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory svg = string.concat(
            SVG_PROTOCOL_URI,
            Base64.encode(bytes(_render(id)))
        );

        string memory json = string.concat(
            '{"name":"Autocheck #',
            Strings.toString(id),
            '",',
            '"description":"one of the many matts, 2023",',
            '"image":"',
            svg,
            '"}'
        );

        return string.concat(JSON_PROTOCOL_URI, Base64.encode(bytes(json)));
    }

    function _render(uint256 id) internal view returns (string memory) {
        bytes memory instructions = bytes(IERC721Metadata(glyphs).tokenURI(id));
        uint256 len = instructions.length;
        string[] memory fragments = new string[](len);

        uint256 x = 0;
        uint256 y = 0;
        // NOTE: skip the 30-character long prefix
        for (uint256 i = 30; i < len; ) {
            bytes1 inst = instructions[i];
            if (inst == 0x25) {
                // newline is 0x25, 0x30, 0x41
                unchecked {
                    x = 0; // reset x
                    y += 1; // inc y
                    i += 2; // skip the rest of the newline encoding
                }
            } else if (inst == 0x2E) {
                // 0x2E = . = Draw nothing in the cell.
                unchecked {
                    x += 1;
                }
            } else {
                if (inst == 0x4F) {
                    // 0x4F = O = Draw a circle bounded by the cell.
                    fragments[i] = _g(x, y, pat);
                } else if (inst == 0x2B) {
                    // 0x2B = + = Draw centered lines vertically and horizontally the length of the cell.
                    fragments[i] = _g(x, y, lus);
                } else if (inst == 0x58) {
                    // 0x58 = X = Draw diagonal lines connecting opposite corners of the cell.
                    fragments[i] = _g(x, y, ex);
                } else if (inst == 0x7C) {
                    // 0x7C = | = Draw a centered vertical line the length of the cell.
                    fragments[i] = _g(x, y, bar);
                } else if (inst == 0x5F) {
                    // 0x5F = - = Draw a centered horizontal line the length of the cell.
                    fragments[i] = _g(x, y, hep);
                } else if (inst == 0x5C) {
                    // 0x5C = \ = Draw a line connecting the top left corner of the cell to the bottom right corner.
                    fragments[i] = _g(x, y, bas);
                } else if (inst == 0x2F) {
                    // 0x2F = / = Draw a line connecting the bottom left corner of teh cell to the top right corner.
                    fragments[i] = _g(x, y, fas);
                } else if (inst == 0x23) {
                    // 0x23 = # = Fill in the cell completely.
                    fragments[i] = _g(x, y, hax);
                }

                unchecked {
                    x += 1;
                }
            }

            unchecked {
                i++; // hi t11s
            }
        }

        return
            string.concat(
                '<svg viewBox="0 0 ',
                Strings.toString((64 + 24) * CELL_SIZE), // inc 12 cells of horizontal padding
                " ",
                Strings.toString((64 + 24) * CELL_SIZE), // inc 12 cells of vertical padding
                '" xmlns="http://www.w3.org/2000/svg" style="background:#ffffff"><defs><path id="c" d="M22.25 12c0-1.43-.88-2.67-2.19-3.34.46-1.39.2-2.9-.81-3.91s-2.52-1.27-3.91-.81c-.66-1.31-1.91-2.19-3.34-2.19s-2.67.88-3.33 2.19c-1.4-.46-2.91-.2-3.92.81s-1.26 2.52-.8 3.91c-1.31.67-2.2 1.91-2.2 3.34s.89 2.67 2.2 3.34c-.46 1.39-.21 2.9.8 3.91s2.52 1.26 3.91.81c.67 1.31 1.91 2.19 3.34 2.19s2.68-.88 3.34-2.19c1.39.45 2.9.2 3.91-.81s1.27-2.52.81-3.91c1.31-.67 2.19-1.91 2.19-3.34zm-11.71 4.2L6.8 12.46l1.41-1.42 2.26 2.26 4.8-5.23 1.47 1.36-6.2 6.77z"/></defs>',
                _g(12, 12, Array.join(fragments)),
                "</svg>"
            );
    }

    function _g(
        uint256 x,
        uint256 y,
        string memory slot
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<g transform="translate(',
                Strings.toString(x * CELL_SIZE),
                ", ",
                Strings.toString(y * CELL_SIZE),
                ')">',
                slot,
                "</g>"
            );
    }
}