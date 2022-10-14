// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title Karafuru Friends
/// @author 69hunter
contract WeTheFest is Ownable, ERC721Enumerable {
    string private _contractURI;
    string private _tokenBaseURI;

    constructor() ERC721("We The Fest", "WETHEFEST") {}

    /// @notice Gift new tokens for `receivers`.
    /// @param receivers addresses to receive newly created tokens
    function gift(address[] calldata receivers) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    // To support Opensea contract-level metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // To support Opensea token metadata
    // https://docs.opensea.io/docs/metadata-standards
    function _baseURI()
        internal
        view
        override(ERC721)
        returns (string memory)
    {
        return _tokenBaseURI;
    }
}