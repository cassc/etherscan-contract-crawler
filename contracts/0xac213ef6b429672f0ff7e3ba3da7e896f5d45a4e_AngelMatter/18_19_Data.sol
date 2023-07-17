// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.20;

import {Base64} from "../lib/solady/src/utils/Base64.sol";
import {LibString} from "../lib/solady/src/utils/LibString.sol";

library Data {
    function _image(uint256 id) internal pure returns (string memory) {
        if (id > 0) {
            return _main(id);
        } else {
            return _$ECRET(id);
        }
    }

    function _main(uint256 id) internal pure returns (string memory) {
        string
            memory im = '<svg height="500" width="500" xmlns="http://www.w3.org/2000/svg"><rect x="0" y="0" width="500" height="500"/>';
        for (uint256 i; i < 26; ++i) {
            string memory y = LibString.toString((i * 20) + 10);
            im = string.concat(
                im,
                '<text fill="#FFF" font-size="20" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (keccak256(abi.encode(i, keccak256(abi.encode(id)))))
                    )
                ),
                '<animate attributeName="opacity" values="1;0;1" dur="1s" repeatCount="indefinite"/></text><text fill="#FFF" font-size="20" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (
                            keccak256(
                                abi.encode(i + 1, keccak256(abi.encode(id)))
                            )
                        )
                    )
                ),
                '<animate attributeName="opacity" values="0;1;0" dur="1s" repeatCount="indefinite"/></text><text fill="#FFF" font-size="20" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (
                            keccak256(
                                abi.encode(i + 2, keccak256(abi.encode(id)))
                            )
                        )
                    )
                ),
                '<animate attributeName="opacity" values="0;1;0" dur="2s" repeatCount="indefinite"/></text>'
            );
        }

        for (uint256 i; i < 11; ++i) {
            string memory y = LibString.toString((i * 50) + 25);
            im = string.concat(
                im,
                '<text fill="#000" font-size="80" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (keccak256(abi.encode(i, keccak256(abi.encode(id)))))
                    )
                ),
                '<animate attributeName="opacity" values="1;0;1" dur="1s" repeatCount="indefinite"/></text><text fill="#000" font-size="80" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (
                            keccak256(
                                abi.encode(i + 1, keccak256(abi.encode(id)))
                            )
                        )
                    )
                ),
                '<animate attributeName="opacity" values="0;1;0" dur="1s" repeatCount="indefinite"/></text><text fill="#000" font-size="80" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (
                            keccak256(
                                abi.encode(i + 2, keccak256(abi.encode(id)))
                            )
                        )
                    )
                ),
                '<animate attributeName="opacity" values="0;1;0" dur="2s" repeatCount="indefinite"/></text>'
            );
        }

        im = string.concat(im, "</svg>");
        return
            string.concat(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(im))
            );
    }

    function _$ECRET(uint256 id) internal pure returns (string memory) {
        string
            memory im = '<svg height="500" width="500" xmlns="http://www.w3.org/2000/svg">';
        for (uint256 i; i < 26; ++i) {
            string memory y = LibString.toString((i * 20) + 10);
            im = string.concat(
                im,
                '<text fill="#000" font-size="20" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (keccak256(abi.encode(i, keccak256(abi.encode(id)))))
                    )
                ),
                '<animate attributeName="opacity" values="1;0;1" dur="2s" repeatCount="indefinite"/></text><text fill="#000" font-size="20" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (
                            keccak256(
                                abi.encode(i + 1, keccak256(abi.encode(id)))
                            )
                        )
                    )
                ),
                '<animate attributeName="opacity" values="0;1;0" dur="2s" repeatCount="indefinite"/></text><text fill="#000" font-size="20" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (
                            keccak256(
                                abi.encode(i + 2, keccak256(abi.encode(id)))
                            )
                        )
                    )
                ),
                '<animate attributeName="opacity" values="0;1;0" dur="3s" repeatCount="indefinite"/></text>'
            );
        }

        for (uint256 i; i < 11; ++i) {
            string memory y = LibString.toString((i * 50) + 25);
            im = string.concat(
                im,
                '<text fill="#FFF" font-size="80" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (keccak256(abi.encode(i, keccak256(abi.encode(id)))))
                    )
                ),
                '<animate attributeName="opacity" values="1;0;1" dur="2s" repeatCount="indefinite"/></text><text fill="#FFF" font-size="80" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (
                            keccak256(
                                abi.encode(i + 1, keccak256(abi.encode(id)))
                            )
                        )
                    )
                ),
                '<animate attributeName="opacity" values="0;1;0" dur="2s" repeatCount="indefinite"/></text><text fill="#FFF" font-size="80" font-family="monospace" x="250" y="',
                y,
                '" text-anchor="middle">',
                LibString.toHexStringNoPrefix(
                    abi.encode(
                        (
                            keccak256(
                                abi.encode(i + 2, keccak256(abi.encode(id)))
                            )
                        )
                    )
                ),
                '<animate attributeName="opacity" values="0;1;0" dur="3s" repeatCount="indefinite"/></text>'
            );
        }

        im = string.concat(
            im,
            '<text fill="#F00" font-size="80" font-family="monospace" x="420" y="275" text-anchor="middle">&lt; &gt;</text></svg>'
        );
        return
            string.concat(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(im))
            );
    }
}