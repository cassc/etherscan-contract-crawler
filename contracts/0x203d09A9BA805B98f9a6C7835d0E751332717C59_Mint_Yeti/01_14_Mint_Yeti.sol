// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ECDSA.sol";
import "ERC721Enumerable.sol";
import "Strings.sol";
import "Ownable.sol";

contract Mint_Yeti is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using ECDSA for bytes;
    using Strings for uint256;

    address constant server_address =
        0xe73dCcC485A1feA5AE623Dfb5c0137e1662E74D6;

    constructor() ERC721("Callback Yeti", "CY") Ownable() {}

    mapping(uint256 => string) private _tokenURIs;
    uint256 private counter = 0;
    uint256 private max_quantity = 300;

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        return _tokenURI;
    }

    function mint(
        address addr,
        string memory ipfs_url,
        bool ipfs_append_tokenID
    ) public {
        require(msg.sender == server_address, "Address mismatch");
        require(counter < max_quantity, "Max tokenID reached");
        _safeMint(addr, counter + 1);
        _setTokenURI(counter + 1, ipfs_url, ipfs_append_tokenID);
        counter += 1;
    }

    function add_to_max_tokenID(uint256 quantity) public {
        require(msg.sender == server_address, "Address mismatch");
        max_quantity = max_quantity + quantity;
    }

    function update_tokenURI(
        uint256 token_id,
        bytes memory holder_sig, // Sig data is formatted {contract_address}_{token_id}_{old_ipfs_url}_{new_ipfs_url}
        string memory new_ipfs_url
    ) public {
        require(msg.sender == server_address, "Address mismatch");

        // Require sig works
        address holder_addr = ownerOf(token_id);
        string memory old_ipfs_url = tokenURI(token_id);
        bytes memory data = bytes(
            string(
                abi.encodePacked(
                    uint256(uint160(address(this))).toHexString(),
                    "_",
                    Strings.toString(token_id),
                    "_",
                    old_ipfs_url,
                    "_",
                    new_ipfs_url
                )
            )
        );
        bool correct_sig = data.toEthSignedMessageHash().recover(holder_sig) ==
            holder_addr;
        require(correct_sig, "Bad sig.");

        _setTokenURI(token_id, new_ipfs_url, false);
    }

    function burn(
        uint256 token_id,
        bytes memory holder_sig // Sig data is formatted {contract_address}_{token_id}
    ) public {
        require(msg.sender == server_address, "Address mismatch");

        // Require sig works
        address holder_addr = ownerOf(token_id);
        bytes memory data = bytes(
            string(
                abi.encodePacked(
                    uint256(uint160(address(this))).toHexString(),
                    "_",
                    Strings.toString(token_id)
                )
            )
        );
        bool correct_sig = data.toEthSignedMessageHash().recover(holder_sig) ==
            holder_addr;
        require(correct_sig, "Bad sig.");

        _burn(token_id);
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI,
        bool ipfs_append_tokenId
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        if (ipfs_append_tokenId) {
            _tokenURIs[tokenId] = string(
                abi.encodePacked(_tokenURI, "/", Strings.toString(tokenId))
            );
        } else {
            _tokenURIs[tokenId] = _tokenURI;
        }
    }
}