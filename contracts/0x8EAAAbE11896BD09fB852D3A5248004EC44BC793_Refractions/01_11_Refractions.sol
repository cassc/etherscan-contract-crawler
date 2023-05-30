// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./contracts/token/ERC1155/ERC1155.sol";
import "./contracts/access/Ownable.sol";
import "./contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract Refractions is ERC1155, Ownable, ERC1155Burnable {
    
    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri = "https://www.muratsayginer.com/nfts/refractions/";
	
    constructor()
        ERC1155(_uri)
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        _uri = newuri;
    }

    function mintOwner(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintOwnerBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            mintOwner(to, ids[i], amounts[i], data);
        }
    }
    
    function airdrop(address[] memory to, uint256 id, uint8[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < to.length; i++) {
            mintOwner(to[i], id, amounts[i], data);
        }
    }
    
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), "{id}/metadata.json"));
    }
    
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, 'Insufficient balance');
        payable(msg.sender).transfer(amount);
    }
    
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_uri, "metadata.json"));
    }
    
    /* Internal functions */
    function _getRandom() internal view returns (uint256) {
       return uint256(blockhash(block.number - 1));
    }
}