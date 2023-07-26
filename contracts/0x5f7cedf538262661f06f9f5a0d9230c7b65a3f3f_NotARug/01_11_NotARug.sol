// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NotARug is ERC721, Ownable {
    string internal baseTokenURI;

    uint public totalSupply = 5000;
    uint public nonce = 0;

    mapping (address => uint256) public owners;

    constructor() ERC721("NOT A RUG", "NAR") {}
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }
    
    function getAssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < nonce; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    
    function getMyAssets() external view returns(uint[] memory){
        return getAssetsByOwner(tx.origin);
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
    function GimmeThatFuckingShit() external {
        uint256 claimed = owners[msg.sender];
        require(5 + nonce <= totalSupply, "2 LATE");
        require(claimed != 5, "ALREADY CLAIMED MF");
        owners[msg.sender] = 5;
        for(uint i = 0; i < 5; i++){
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
            nonce++;
        }
    }
}