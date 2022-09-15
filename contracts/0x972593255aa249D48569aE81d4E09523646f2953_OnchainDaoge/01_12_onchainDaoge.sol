// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Base64 } from 'base64-sol/base64.sol';

contract OnchainDaoge is ERC721, Ownable {

    bytes[] internal images;
    uint16 public totalSupply = 0;

    string internal constant HEADER =
        '<svg id="logo" width="100%" height="100%" version="1.1" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string internal constant FOOTER =
        "<style>#logo{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";

    constructor() ERC721("DAOGE", "DAOGE") {
        
    }

    function mint() public onlyOwner {
        require(totalSupply == 0, "Only 1 of these will ever be minted");
        _mint(msg.sender, totalSupply);
        totalSupply++;
    }

    function storeImage(bytes calldata _image) public onlyOwner {
        images.push(_image);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": ',
                                '"CryptoGang DAO",',
                                '"image": "',
                                "data:image/svg+xml;base64,",
                                Base64.encode(bytes(
                                    abi.encodePacked(
                                        HEADER,
                                        wrapTag(Base64.encode(images[_tokenId])),
                                        FOOTER
                                    )
                                )),
                                '",',
                                '"description": ',
                                unicode'"GangDaoge #KISS🫡 💞 🏴‍☠️"',
                                "}"
                            )
                        )
                    )
                )
            );    
        }

    function wrapTag(string memory uri) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="1" y="1" width="500" height="500" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    uri,
                    '"/>'
                )
            );
    }
}