// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title WebacyToken
 * Reference ERC1155 token for testing purposes
 * with easy method for creating many tokenIds
 *
 */
contract Webacy1155 is ERC1155 {
    uint256 public tokenID = 0;
    mapping(uint256 => uint256) public existence;
    string public symbol;

    constructor(string memory _symbol)
        ERC1155("https://webacy.example/api/item/{id}.json")
    {
        symbol = _symbol;
    }

    function selfMint(uint256 _amount) external {
        privateMint(_amount, msg.sender);
    }

    function publicMint(uint256 _amount, address _address) external {
        privateMint(_amount, _address);
    }

    function privateMint(uint256 _amount, address _address) private {
        _mint(_address, tokenID, _amount, "");
        existence[tokenID] = _amount;
        tokenID++;
    }
}