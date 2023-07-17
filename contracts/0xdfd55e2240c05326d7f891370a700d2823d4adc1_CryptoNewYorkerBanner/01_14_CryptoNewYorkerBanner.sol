// SPDX-License-Identifier: MIT
// Dev: @Brougkr
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CryptoNewYorkerBanner is ERC1155, Ownable, Pausable, ERC1155Burnable
{
    //Initialization
    string public name;
    string public symbol;
    mapping (uint256 => string) private _uris;

    constructor() ERC1155("https://ipfs.io/ipfs/QmejRMtmqH7CnFLoeHTNFSY6Tna5gqdzyFn53SJvL8qZJi/{id}.json") 
    {
        name = "CryptoNewYorkerBanner";
        symbol = "CNYB";
        setTokenURI(0, "https://gateway.pinata.cloud/ipfs/QmejRMtmqH7CnFLoeHTNFSY6Tna5gqdzyFn53SJvL8qZJi/0.json");
        setTokenURI(1, "https://gateway.pinata.cloud/ipfs/QmejRMtmqH7CnFLoeHTNFSY6Tna5gqdzyFn53SJvL8qZJi/1.json");
        setTokenURI(2, "https://gateway.pinata.cloud/ipfs/QmejRMtmqH7CnFLoeHTNFSY6Tna5gqdzyFn53SJvL8qZJi/2.json");
        setTokenURI(3, "https://gateway.pinata.cloud/ipfs/QmejRMtmqH7CnFLoeHTNFSY6Tna5gqdzyFn53SJvL8qZJi/3.json");
        setTokenURI(4, "https://gateway.pinata.cloud/ipfs/QmejRMtmqH7CnFLoeHTNFSY6Tna5gqdzyFn53SJvL8qZJi/4.json");
        mint(msg.sender, 0, 50);
        mint(msg.sender, 1, 50);
        mint(msg.sender, 2, 50);
        mint(msg.sender, 3, 50);
        mint(msg.sender, 4, 50);
    }

    function uri(uint256 tokenId) override public view returns (string memory) { return(_uris[tokenId]); }

    function setTokenURI(uint256 tokenId, string memory _uri) public onlyOwner { _uris[tokenId] = _uri; }

    function setURI(string memory newuri) public onlyOwner { _setURI(newuri); }

    function pause() public onlyOwner { _pause(); }

    function unpause() public onlyOwner { _unpause(); }

    function mint(address account, uint256 id, uint256 amount) public onlyOwner { _mint(account, id, amount, ""); }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public onlyOwner { _mintBatch(to, ids, amounts, ""); }

    function batchTransfer(address[] memory recipients, uint256[] memory tokenIDs, uint256[] memory amounts) public onlyOwner 
    { 
        for(uint i=0; i < recipients.length; i++) { _safeTransferFrom(msg.sender, recipients[i], tokenIDs[i], amounts[i], ""); }
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override 
    { 
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data); 
    }
}