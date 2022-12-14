// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Mintable.sol";

//           _____                    _____                    _____          
//          /\    \                  /\    \                  /\    \         
//         /::\____\                /::\    \                /::\____\        
//        /::::|   |               /::::\    \              /::::|   |        
//       /:::::|   |              /::::::\    \            /:::::|   |        
//      /::::::|   |             /:::/\:::\    \          /::::::|   |        
//     /:::/|::|   |            /:::/  \:::\    \        /:::/|::|   |        
//    /:::/ |::|   |           /:::/    \:::\    \      /:::/ |::|   |        
//   /:::/  |::|   | _____    /:::/    / \:::\    \    /:::/  |::|___|______  
//  /:::/   |::|   |/\    \  /:::/    /   \:::\ ___\  /:::/   |::::::::\    \ 
// /:: /    |::|   /::\____\/:::/____/  ___\:::|    |/:::/    |:::::::::\____\
// \::/    /|::|  /:::/    /\:::\    \ /\  /:::|____|\::/    / ~~~~~/:::/    /
//  \/____/ |::| /:::/    /  \:::\    /::\ \::/    /  \/____/      /:::/    / 
//          |::|/:::/    /    \:::\   \:::\ \/____/               /:::/    /  
//          |::::::/    /      \:::\   \:::\____\                /:::/    /   
//          |:::::/    /        \:::\  /:::/    /               /:::/    /    
//          |::::/    /          \:::\/:::/    /               /:::/    /     
//          /:::/    /            \::::::/    /               /:::/    /      
//         /:::/    /              \::::/    /               /:::/    /       
//         \::/    /                \::/____/                \::/    /        
//          \/____/                                           \/____/         
                                                                           



contract NewGanymedeAsset is ERC721, ERC721Enumerable, Mintable {
    string public baseURI;

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {}
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
  
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function tokensOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

}