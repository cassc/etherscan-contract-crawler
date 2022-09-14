// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "ECDSA.sol";
import "ERC721Enumerable.sol";
import "Strings.sol";
import "Ownable.sol";

contract Mint_ANA_NEO_Test is ERC721Enumerable, Ownable {
    using Strings for uint256;

    address constant server_address =
        0xe73dCcC485A1feA5AE623Dfb5c0137e1662E74D6;

    constructor() ERC721("ANA NEO IRL NFT", "ANA-IRL") Ownable() {}

    mapping(uint256 => string) private _tokenURIs;
    uint256 private counter = 0;
    uint256 private max_quantity = 35;

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(from == address(0), "Err: token is SOULBOUND");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}