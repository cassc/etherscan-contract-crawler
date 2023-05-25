// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "solmate/src/tokens/ERC1155.sol";
import "solmate/src/utils/SafeTransferLib.sol";
import "solmate/src/auth/Owned.sol";
import "./Base64.sol";
import "./Helpers.sol";

error MintingTooManyAtOnce();

contract AevoExchangePass is ERC1155, Owned {
    string public constant name = "Exchange Pass";
    string public constant symbol = "PASS";

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC1155() Owned(msg.sender) {
        // Automatically mints 1 to deployer
        _mint(msg.sender, 0, 1, "");
    }

    function adminMint(address to, uint256 id, uint256 amount) public onlyOwner {
        _mint(to, id, amount, "");
    }

    function adminBatchMint(address[] calldata to, uint256 id, uint256 amount) public onlyOwner {
        unchecked {
            for (uint i = 0; i < to.length; i++) {
                _mint(to[i], id, amount, "");
            }
        }
    }

    function setTokenURI(uint256 tokenId, string calldata tokenUri) public onlyOwner {
        _tokenURIs[tokenId] = tokenUri;
    }

    function uri(uint256 id) public view override returns (string memory) {
        if (bytes(_tokenURIs[id]).length != 0) {
            return _tokenURIs[id];
        }

        // Default uri
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                'Exchange Pass',
                                '","description":"Exchange Pass holders get early access to app.aevo.xyz"',
                                ',"image": "ipfs://bafybeigrvvnkkypcunvt4mifezrqskpt24tucktehp5r4oqvpb2fezsbim/preview.png"',
                                ',"animation_url": "ipfs://bafybeigrvvnkkypcunvt4mifezrqskpt24tucktehp5r4oqvpb2fezsbim/aevo.gltf"',
                                ',"external_url": "https://app.aevo.xyz"',
                                ',"background_color": "#06060C"',
                                '}'
                            )
                        )
                    )
                )
            );
    }
}