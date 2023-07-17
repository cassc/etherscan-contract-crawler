// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.20;

import {Data} from "./Data.sol";
import {Base64} from "../lib/solady/src/utils/Base64.sol";
import {LibString} from "../lib/solady/src/utils/LibString.sol";
import {IFileStore} from "../lib/ethfs/packages/contracts/src/IFileStore.sol";

contract Collision {
    using LibString for uint256;

    IFileStore fileStore;
    string desc =
        '"description":"In a far away parallel universe an advanced civilization built a computer around a star and escaped into a simulated reality. After some immeasurable amount of time these facts were forgotten and after another immeasurable amount of time that star began to die. Even so, life Inside this simulation progressed, and on one planet some of that life progressed enough to form a government. You are the new member of a mysterious project under a secret agency of this government researching the elementary particles that make up your universe.",';

    constructor() {
        fileStore = IFileStore(0x9746fD0A77829E12F8A9DBe70D7a322412325B91);
    }

    function _parameters(uint256 _id) internal pure returns (string memory) {
        return
            string.concat(
                '<script src="data:text/javascript;base64,',
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            "let seed = ",
                            _id.toString(),
                            _id == 0 ? "; let mode = 1;" : "; let mode = 0;"
                        )
                    )
                )
            );
    }

    function _scripts(uint256 _id) internal view returns (string memory) {
        return
            string.concat(
                '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
                fileStore.getFile("p5-v1.5.0.min.js.gz").read(),
                '"></script>',
                '<script src="data:text/javascript;base64,',
                fileStore.getFile("gunzipScripts-0.0.1.js").read(),
                '"></script>',
                _parameters(_id),
                '"></script><script src="data:text/javascript;base64,',
                fileStore.getFile("(:").read(),
                '"></script>'
            );
    }

    function _page(uint256 _id) internal view returns (string memory) {
        return
            string.concat(
                '"animation_url":"data:text/html;base64,',
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            '<!DOCTYPE html><html style="height: 100%;"><head>',
                            _scripts(_id),
                            '</head><body style="margin: 0;display: flex;justify-content: center;align-items: center;height: 100%;"></body></html>'
                        )
                    )
                ),
                '"}'
            );
    }

    function uri(uint256 _id) external view returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            '{"name":"< ',
                            _id > 0 ? _id.toString() : "...",
                            ' >",',
                            desc,
                            '"image":"',
                            Data._image(_id),
                            '",',
                            _page(_id)
                        )
                    )
                )
            );
    }
}