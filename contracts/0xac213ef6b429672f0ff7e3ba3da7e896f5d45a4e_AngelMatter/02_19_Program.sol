// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.20;

import {Particle} from "./Particle.sol";
import {Base64} from "../lib/solady/src/utils/Base64.sol";
import {LibString} from "../lib/solady/src/utils/LibString.sol";
import {IFileStore} from "../lib/ethfs/packages/contracts/src/IFileStore.sol";

struct Params {
    uint256 id;
    uint256 seed;
    uint256 pres;
    string ar;
    address wal;
    uint8 inv;
    uint8 lvl;
    uint8 asc;
}

contract Program {
    using LibString for uint256;
    using LibString for uint160;
    using LibString for uint8;

    IFileStore fileStore;
    string desc =
        '"description":"In a far away parallel universe an advanced civilization built a computer around a star and escaped into a simulated reality. After some immeasurable amount of time these facts were forgotten and after another immeasurable amount of time that star began to die. Even so, life Inside this simulation progressed, and on one planet some of that life progressed enough to form a government. You are the new member of a mysterious project under a secret agency of this government researching the elementary particles that make up your universe.",';

    constructor() {
        fileStore = IFileStore(0x9746fD0A77829E12F8A9DBe70D7a322412325B91);
    }

    function _parameters(
        Params memory _params
    ) internal view returns (string memory) {
        return
            string.concat(
                '<script src="data:text/javascript;base64,',
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            "let seed = ",
                            (_params.seed % 9007199254740991).toString(),
                            "; let tim = ",
                            block.timestamp.toString(),
                            "; let ar = ",
                            _params.ar,
                            "; let wal = ",
                            (uint160(_params.wal) % 9007199254740991)
                                .toString(),
                            "; let inv = ",
                            _params.inv.toString(),
                            "; let lvl = ",
                            _params.lvl.toString(),
                            "; let asc = ",
                            _params.asc.toString(),
                            ";"
                        )
                    )
                )
            );
    }

    function _scripts(
        Params memory _params
    ) internal view returns (string memory) {
        return
            string.concat(
                '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
                fileStore.getFile("p5-v1.5.0.min.js.gz").read(),
                '"></script>',
                '<script src="data:text/javascript;base64,',
                fileStore.getFile("gunzipScripts-0.0.1.js").read(),
                '"></script>',
                _parameters(_params),
                '"></script><script src="data:text/javascript;base64,',
                fileStore.getFile(":)").read(),
                '"></script>'
            );
    }

    function _page(
        Params memory _params
    ) internal view returns (string memory) {
        return
            string.concat(
                '"animation_url":"data:text/html;base64,',
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            '<!DOCTYPE html><html style="height: 100%;"><head>',
                            _scripts(_params),
                            '</head><body style="margin: 0;display: flex;justify-content: center;align-items: center;height: 100%;"></body></html>'
                        )
                    )
                ),
                '",'
            );
    }

    function _attributes(
        Params memory _params
    ) internal pure returns (string memory) {
        string memory atr = string.concat(
            '"attributes": [{"trait_type": "Decay", "value": ',
            _params.lvl.toString(),
            "}, ",
            '{"display_type": "number","trait_type": "Prestige", "value": ',
            _params.pres.toString(),
            "}, "
        );

        atr = _params.inv > 0
            ? string.concat(atr, '{"trait_type": "Spin", "value": "Up"},')
            : string.concat(atr, '{"trait_type": "Spin", "value": "Down"},');

        atr = bytes(_params.ar).length > 1
            ? string.concat(atr, '{"trait_type": "Prism", "value": "Advanced"}')
            : string.concat(
                atr,
                '{"trait_type": "Prism", "value": "Original"}'
            );

        if (_params.asc > 0) {
            atr = string.concat(
                atr,
                ', {"trait_type": "[REDACTED]", "value": "[REDACTED]"}'
            );
        }

        if (_params.id < 1000 && _params.id % 111 == 0) {
            atr = string.concat(
                atr,
                ', {"trait_type": "Angel", "value": "',
                _params.id.toString(),
                '"}'
            );
        }

        if (_params.id % 1111 == 0) {
            atr = string.concat(
                atr,
                ', {"trait_type": "Hyper Angel", "value": "',
                _params.id.toString(),
                '"}'
            );
        }

        return string.concat(atr, "]}");
    }

    function uri(Params memory _params) external view returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        string.concat(
                            '{"name":">>> ',
                            _params.id.toString(),
                            ' <<<",',
                            desc,
                            '"image":"',
                            Particle._image(bytes32(_params.seed)),
                            '",',
                            _page(_params),
                            _attributes(_params)
                        )
                    )
                )
            );
    }
}