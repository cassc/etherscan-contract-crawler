// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC721A.sol";

// ._. _________                      
// | | \_   ___ \  ____   ____  ____  
// | | /    \  \/ /  _ \_/ ___\/  _ \ 
//  \| \     \___(  <_> )  \__(  <_> )
//  __  \______  /\____/ \___  >____/ 
//  \/         \/            \/    
// @author 0xBori <https://twitter.com/0xBori>   
contract Coco is ERC20Burnable, Ownable{
    uint256 public EMISSION_RATE = 1157407407407407;
    uint256 public immutable DEFAULT_START_TIMESTAMP;
    address public waveCatchers;
    mapping (uint256 => uint256) tokenToLastClaimed;

    constructor() ERC20("Coco", "COCO") {
        DEFAULT_START_TIMESTAMP = 1646158260;
        waveCatchers = 0x1A331c89898C37300CccE1298c62aefD3dFC016c;
    }

    function claim(uint16[] memory _tokenIds) public {
        uint256 rewards = 0;

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint16 tokenId = _tokenIds[i];
            require(
                ERC721A(waveCatchers).ownerOf(tokenId) == msg.sender,
                "You are not the owner of this token"
            );

            rewards +=
            (block.timestamp - (tokenToLastClaimed[tokenId] == 0 ? DEFAULT_START_TIMESTAMP : tokenToLastClaimed[tokenId])) * EMISSION_RATE;
            tokenToLastClaimed[tokenId] = block.timestamp;
        }
        _mint(msg.sender, rewards);
    }

    function getRewardsForId(uint256 _id) public view returns (uint) {
        return (block.timestamp - (tokenToLastClaimed[_id] == 0 ? DEFAULT_START_TIMESTAMP : tokenToLastClaimed[_id])) * EMISSION_RATE;
    }

    function setWaveCatchersAddress(address _address) external onlyOwner {
        waveCatchers = _address;
    }
}