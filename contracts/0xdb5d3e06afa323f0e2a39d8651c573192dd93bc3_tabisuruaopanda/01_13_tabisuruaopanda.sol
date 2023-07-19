pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract tabisuruaopanda is ERC721, Ownable {
    using Strings for uint256;
    using Strings for string;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 thtime;
    mapping (uint256 => string) token;
    mapping (uint256 => uint256)  transtime;
    address[] allowaddress;
    constructor(string memory name_, string memory symbol_) ERC721(name_,symbol_) {
        thtime = 365 * 3600 * 24;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns  (string memory)  {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return token[tokenId];
    }
    function createToken(string[] memory metas) public onlyOwner payable returns (string memory) {
        for(uint ins; ins<metas.length; ins++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            token[newItemId] = metas[ins];
            _mint(owner(), newItemId);
        }
    }
    function isTime(uint256 _lastTransferredAt, uint256 _now) public view returns (bool) {
        return (_now - _lastTransferredAt) >= thtime;
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (from == address(0) || from == owner()) {
            transtime[tokenId] = block.timestamp;
        } else {
            require(isTime(transtime[tokenId], block.timestamp),"ERC721Transfer: This NFT is currently locked");
        }
        super._beforeTokenTransfer(from, to, tokenId);
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
    function _SetList(address to) public onlyOwner returns (string memory) {
        allowaddress.push(to);
    }
    function _DelList(uint256 id) public onlyOwner returns (string memory) {
        delete allowaddress[id];
    }
    function _ViewTime(uint256 tokenId) public view returns (uint256) {
        return block.timestamp - transtime[tokenId];
    }
}