//SPDX-License-Identifier: MIT
//SimpleNetArtDiagram.sol by MTAA
pragma solidity ^0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Royalty } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

contract SimpleNetArtDiagram is Ownable, ERC721Royalty {
    /**
     * @dev Keeps track of the number of tokens and is returned from totalSupply function
     */
    uint256 private _tokenCount; // default to 0

    /**
     * @dev Keeps track of whether mintMax has ever been called.
     */
    bool private _minted; // default to false

    string public constant NAME = "Simple Net Art Diagram";
    string public constant DESCRIPTION = "The simplest possible net art diagram. CC0 1.0 Universal";

    /**
     * @notice data URI of the Simple Net Art Diagram
     */
    string public constant SIMPLE_NET_ART_DIAGRAM =
        "data:image/gif;base64,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";
    uint256 public constant MAX_SUPPLY = 3; // there will only ever be 3 SNAD tokens

    constructor() ERC721(NAME, "SNAD") {
        // set a 10% royalty
        _setDefaultRoyalty(owner(), 1000);
    }

    /**
     * @notice Contract owner may mint max supply to the contract owner only once
     */
    function mintMax() public onlyOwner {
        require(_minted == false, "Already minted");
        for (uint256 i = 1; i <= MAX_SUPPLY; i++) {
            _mint(owner(), i);
        }
        _tokenCount = MAX_SUPPLY;
        _minted = true;
    }

    /**
     * @notice Returns the license name
     * conforms to ICantBeEvil https://github.com/a16z/a16z-contracts/blob/master/contracts/licenses/ICantBeEvil.sol
     */
    function getLicenseName() public pure returns (string memory) {
        return "CC0 1.0 Universal";
    }

    /**
     * @notice Returns the license URI
     * conforms to ICantBeEvil https://github.com/a16z/a16z-contracts/blob/master/contracts/licenses/ICantBeEvil.sol
     */
    function getLicenseURI() public pure returns (string memory) {
        return "ipfs://QmZcU7ZkmVSNfVZjsxoHSoCtw89Az5hmqufLPowZxCURn8";
    }

    /**
     * @notice Returns current token supply
     */
    function totalSupply() public view returns (uint256) {
        return _tokenCount;
    }

    /**
     * @notice ...can't think of a reason someone would want to burn
     * one of these precious tokens, but you never know!
     * Let's hope this function is never called on mainnet.
     */
    function burn(uint256 _tokenId) public {
        _burn(_tokenId);
        require(_tokenCount > 0, "decrement overflow");
        unchecked {
            _tokenCount = _tokenCount - 1;
        }
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `_tokenId` token if it's a valid token id
     */
    function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
        // ownerOf will revert if _tokenId belongs to address 0
        ownerOf(_tokenId);
        string memory edition = string.concat(_tokenIdToString(_tokenId), "/3");
        string memory licence = string.concat(getLicenseName(), " ", getLicenseURI());
        string memory attributes = string.concat(
            '"attributes": [{"trait_type":"Artist","value":"MTAA"},{"trait_type":"License","value":"',
            licence,
            '"},{"trait_type":"Edition", "value":"',
            edition,
            '"}]'
        );
        string memory metadata = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"',
                    NAME,
                    " #",
                    edition,
                    '","description":"',
                    DESCRIPTION,
                    '","image":"',
                    SIMPLE_NET_ART_DIAGRAM,
                    '","license":"',
                    licence,
                    '","edition":"',
                    edition,
                    '",',
                    attributes,
                    "}"
                )
            )
        );
        return string.concat("data:application/json;base64,", metadata);
    }

    /**
     * @dev Since only 1, 2 or 3 are valid, turn the token ID into a string in this simple manner.
     */
    function _tokenIdToString(uint256 _tokenId) private pure returns (string memory tokenId) {
        if (_tokenId == 1) {
            return "1";
        }
        if (_tokenId == 2) {
            return "2";
        }
        if (_tokenId == 3) {
            return "3";
        }
        revert("Invalid token ID");
    }
}