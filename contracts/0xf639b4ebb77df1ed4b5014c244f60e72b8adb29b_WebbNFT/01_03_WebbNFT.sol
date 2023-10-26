// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";

// @title free-mint, commemorative NFTs to celebrate the first images from the James Webb Space Telescope (JWST)
// @author jamiedubs <https://jamiedubs.com>
contract WebbNFT is Owned, ERC1155 {
    string public baseURI;
    uint256 public maxID;
    bool public enabled;

    string public name = "James Webb Space Telescope NFTs";
    string public symbol = "WEBB3";

    error TokenDoesNotExist();
    error MintingNotEnabled();

    event BaseURIUpdated(string newBaseURI);
    event MaxIDUpdated(uint256 newMaxID);
    event EnabledUpdated(bool newEnabled);

    modifier tokenExists(uint256 id) {
        if (id > maxID) {
            revert TokenDoesNotExist();
        }
        _;
    }

    modifier mintingEnabled() {
        if (!enabled) {
            revert MintingNotEnabled();
        }
        _;
    }

    constructor(string memory _baseURI, uint256 _maxID) Owned(msg.sender) {
        baseURI = _baseURI;
        maxID = _maxID;
        enabled = true;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURIUpdated(_baseURI);
    }

    function setMaxID(uint256 _maxID) public onlyOwner {
        maxID = _maxID;
        emit MaxIDUpdated(_maxID);
    }

    function setEnabled(bool _enabled) public onlyOwner {
        enabled = _enabled;
        emit EnabledUpdated(_enabled);
    }

    function mint(uint256 id) public tokenExists(id) mintingEnabled {
        _mint(msg.sender, id, 1, "");
    }

    function uri(uint256 id)
        public
        view
        override
        tokenExists(id)
        returns (string memory)
    {
        // use vanilla URLs instead of ERC-1155 {id} urls
        return string.concat(baseURI, Strings.toString(id));
    }
}

// ripped from OZ Strings; we don't need the other two functions in that library
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}