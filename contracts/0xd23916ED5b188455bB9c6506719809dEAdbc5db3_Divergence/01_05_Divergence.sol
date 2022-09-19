//                      ▄▄▄
//                   ▄▓▒▒▒▒▌
//                ▄▓▒▒▒▒▒▒▀   ▄▄▒▒▒
//             ▄▓▒▒▒▒▒▀    ▄▒▒▒▒▒▒▒         ▄▄▄▒▒▒▒
//          ▄▓▒▒▒▒▒▀   ▄▄▓▒▒▒▒▒▒▀▀   ▄▄▄▒▒▒▒▒▒▒▒▒▒▒▌
//        ▐▒▒▒▒▒▒   ▄▒▒▒▒▒▒▒▀   ▄▒▒▒▒▒▒▒▒▒▒▒▒▀▀▀▀
//         ▀▀▒▀   ▄▒▒▒▒▒▒▀  ▄▒▓▒▒▒▒▒▒▀▀▀
//                ▀▒▒▒▒  ▄▒▒▒▒▒▒▀▀
//                     ▄▓▒▒▒▒▀
//                    ▒▒▒▒▒▀
//                  ▄▒▒▒▒▀    ▄▄▄▄
//                 ▒▒▒▒▒    ▐▒▒▒▒▒▒▒
//               ▄▒▒▒▒▒     ▓▒▒▒▒▒▒▒
//             ▄▓▒▒▒▒▀       ▀▒▒▒▒▀
//            ▐▒▒▒▒▒                          ▄▄▒▒▒▒▒▒▒▒▄
//             ▀▒▒▀                       ▄▒▓▒▒▒▒▒▒▒▒▒▒▒▀
//                                     ▄▒▒▒▒▒▒▀▀
//                                   ▄▓▒▒▒▒▀
//                ▄▒▒▒▒▄           ▄▒▒▒▒▒
//              ▄▒▒▒▒▒▒          ▄▓▒▒▒▒
//             ▒▒▒▒▒▒          ▄▒▒▒▒▒▀
//             ▒▒▒▒▀         ▄▒▒▒▒▒▀
//                         ▄▓▒▒▒▒▀
//                        ▐▒▒▒▒▒
//          _ _             ▀▀
//       __| (_)_   _____ _ __ __ _  ___ _ __   ___ ___ 
//      / _` | \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
//     | (_| | |\ V /  __/ | | (_| |  __/ | | | (_|  __/
//      \__,_|_| \_/ \___|_|  \__, |\___|_| |_|\___\___|
//                            |___/  ʙʏ ʙᴜᴢᴢʏʙᴇᴇ
//
//               SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// erc 721a is imported from its own npm
// module, not an openzeppelin one.
import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Divergence is ERC721A, Ownable {
    string public _baseTokenURI;
    uint supply = 4884;

    constructor(
        string memory baseURI
    ) ERC721A("Divergence", "DIV") {
        _baseTokenURI = baseURI;
    }

    function airdrop(address[] calldata holders, uint256[] calldata count) external onlyOwner {
        for (uint256 i = 0; i < holders.length; i++) {
            require(
                totalSupply() + count[i] <= supply,
                "Mint would go past max supply"
            );
            _mint(holders[i], count[i]);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}