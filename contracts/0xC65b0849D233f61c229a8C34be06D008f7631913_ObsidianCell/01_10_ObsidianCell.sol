// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
* @title ObsidianCell
* @author lileddie.eth (@lileddie_eth) / Enefte Studio
*/
contract ObsidianCell is ERC721 {
    using Strings for uint256;

    string private BASE_URI = "https://www.metashima.com/minted/";
    uint256 nextToken = 1;
    address private _owner;
        
    function airdropWallets(address[] calldata _wallets) external onlyOwner {
        for(uint i = 0; i < _wallets.length; i++){
            _mint(_wallets[i], nextToken+i);
        }
        nextToken += _wallets.length;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),"/obsidiancell")) : "";
    }
    
    function setBaseURI(string memory _uri) external onlyOwner {
        BASE_URI = _uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    constructor() ERC721("ObsidianCell", "CELL") {
        _owner = msg.sender;
    }

}