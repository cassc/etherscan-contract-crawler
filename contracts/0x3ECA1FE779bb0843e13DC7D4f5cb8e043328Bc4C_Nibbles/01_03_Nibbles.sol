// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {ERC721} from "solmate/src/tokens/ERC721.sol";
import {LibString} from "solmate/src/utils/LibString.sol";

contract Nibbles is ERC721 {
    string public baseURI;
    uint256 public tokenID;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function setBaseURI(string memory _baseURI) external {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    function mint(address _to) external {
        _mint(_to, tokenID++);
    }

    function batchMint(address _to, uint256 _amt) external {
        uint256 _tokenID = tokenID;
        for (uint256 index = 0; index < _amt; index++) {
            _mint(_to, index + _tokenID);
        }
        tokenID += _amt;
    }
}