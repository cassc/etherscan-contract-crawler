// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title WebacyToken
 * Reference ERC721 token for testing purposes
 */
contract WebacyNFT is ERC721 {
    mapping(string => uint8) public hashes;
    uint256 _tokenIds = 0;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function mint(address recipient, string memory hash)
        public
        returns (uint256)
    {
        require(hashes[hash] != 1, "Hash already minted");

        hashes[hash] = 1;

        uint256 newItemId = _tokenIds;
        _mint(recipient, newItemId);

        _tokenIds++;

        return newItemId;
    }
}