// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract llacfm is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string ipfs;
    mapping(uint256 => uint256) types;
    string title;
    string description;
    address ownerd;
    uint256 thtime;
    mapping (uint256 => string) token;
    mapping (uint256 => uint256)  transtime;
    address[] allowaddress;
    uint256 maxsupply;
    constructor(string memory name_,string memory symbol_,string memory title_,string memory description_,string memory ipfs_,uint256 maxsupply_) ERC721(name_,symbol_){
        title = title_;
        description = description_;
        ownerd = msg.sender;
        ipfs = ipfs_;
        thtime = 365 * 3600 * 24;
        maxsupply = maxsupply_;
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        bytes memory json = abi.encodePacked(
            '{"name": "', title ,' #',
            Strings.toString(tokenId),
            '", "description": "', description ,'", "image": "', ipfs,'"}' );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }
    function mint(address user) public onlyOwner returns (uint256)  {
        require(_tokenIds.current() < maxsupply);
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(user, newItemId);
        transtime[newItemId] = block.timestamp;
        return newItemId;
    }
    function isTime(uint256 _lastTransferredAt, uint256 _now) public view returns (bool) {
        return (_now - _lastTransferredAt) >= thtime;
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        if (from == address(0) || from == owner()) {
        } else {
            require(isTime(transtime[tokenId], block.timestamp),"ERC721Transfer: This NFT is currently locked");
        }
        super._beforeTokenTransfer(from, to, tokenId,batchSize);
    }
    function setApprovalForAll(address ope,bool approved) public virtual override {
        require(list(ope) == true, "ERC721Approve: This contract is not authorized");
        super.setApprovalForAll(ope, approved);
    }
    function approve(address to,uint256 tokenId) public virtual override {
        require(list(to) == true, "ERC721Approve: This contract is not authorized");
        super.approve(to, tokenId);
    }
    function list(address to) public view returns (bool) {
        for (uint ins;ins<allowaddress.length; ins++) {
            if (allowaddress[ins] == to) {
                return true;
            }
        }
        return false;
    }
    function _ViewList() public view returns (address[] memory) {
        return allowaddress;
    }
    function _ViewMaxsupply() public view returns (uint256) {
        return maxsupply;
    }
    function _SetList(address to) public onlyOwner {
        allowaddress.push(to);
    }
    function _DelList(uint256 id) public onlyOwner {
        delete allowaddress[id];
    }
    function _ViewTime(uint256 tokenId) public view returns (uint256) {
        return block.timestamp - transtime[tokenId];
    }

}