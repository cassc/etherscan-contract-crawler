// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Flamingo is ERC1155, Ownable {
    uint256 public constant TOKEN_ID = 0;
    uint256 public constant MAX_SUPPLY = 100000;
    uint256 public constant GRID_SIZE = 1000;
    uint256 public constant MINT_DEADLINE = 1681843200; 
    string public name = unicode"ōLand Swamp Single-Player Craft: Degen Flamingo";
    string public symbol = "FLAMINGO";

    ///https://swamp.overline.network/metadata/flamingo/{id}

    uint256 public totalSupply;
    mapping(address => uint256) public tokenX;
    mapping(address => uint256) public tokenY;

    constructor(string memory uri)
        ERC1155(uri)
    {
        totalSupply = 0;
    }

    function mint() public {
        require(block.timestamp < MINT_DEADLINE, "Minting period has ended");
        require(totalSupply + 1 <= MAX_SUPPLY, "Exceeds max supply");
        _mint(_msgSender(), TOKEN_ID, 1, "");
        totalSupply++;
    }

    function _randomPosition(uint256 step) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(step, msg.sender))) % GRID_SIZE;
    }   

    function eatMushroom() public {
        require(balanceOf(msg.sender, TOKEN_ID) > 0, "Must by on Flamingo");
        tokenX[msg.sender] = _randomPosition(block.timestamp);
        tokenY[msg.sender] = _randomPosition(block.number - 1);
    }
}