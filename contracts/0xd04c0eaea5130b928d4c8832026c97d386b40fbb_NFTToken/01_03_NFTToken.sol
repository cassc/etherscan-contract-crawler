// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";

error TokenDoesNotExist();

/// @title ERC721 NFT Many Mint
/// @title NFTToken
/// @author drbh <github.com/drbh>
contract NFTToken is ERC721 {
    using Strings for uint256;

    uint256 public totalSupply = 0;
    string public baseURI;

    /// @notice Create and mint many NFTs
    /// @param _name The name of the token.
    /// @param _symbol The Symbol of the token.
    /// @param _baseURI The baseURI for the token that will be used for metadata.
    /// @param _numberOfTokens The numberOfTokens is the number of tokens we'll mint on init.
    /// @param _recipient The recipient is the address that gets all of the tokens.
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _numberOfTokens,
        address _recipient
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        for (uint256 index = 0; index < _numberOfTokens; index++) {
            uint256 tokenId = totalSupply;
            _mint(_recipient, tokenId);
            totalSupply++;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_ownerOf[tokenId] == address(0)) {
            revert TokenDoesNotExist();
        }

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }
}