// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './libraries/EnumerableSet.sol';
import './libraries/Strings.sol';

import './interfaces/IERC165.sol';
import './interfaces/IERC721.sol';
import './interfaces/IERC721Receiver.sol';
import './interfaces/IERC721Metadata.sol';
import './interfaces/IERC721Enumerable.sol';

contract HiveClub {
    using EnumerableSet for EnumerableSet.UintSet;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    mapping(address => EnumerableSet.UintSet) private _tokenOfOwnerByIndex;
    uint256[] public tokenByIndex;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(address => mapping(address => bool)) private _isApprovedForAll;
    mapping(address => bool) public defaultApproved;
    address public keeper;
    string public name;
    string public symbol;
    string private uri;
    mapping(address => bool) public minters;
    mapping(uint256 => uint256) public totalSupplyOfType;
    
    constructor() {
        name = 'HiveClub';
        symbol = 'HIVE';
        uri = 'https://nfts.hiveclub.xyz/repositories/';
        keeper = msg.sender;
        minters[msg.sender] = true;
    }
    
    modifier onlyKeeper(){
        require(keeper == msg.sender, "NFT:onlyKeeper");
        _;
    }
    
    modifier approvedOrOwner(uint256 tokenId){
        address owner = ownerOf[tokenId];
        require(msg.sender == owner || getApproved[tokenId] == msg.sender || isApprovedForAll(owner, msg.sender), "NFT:onlyApprovedOrOwner");
        _;
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool){
        return interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }
    
    function getType(uint256 tokenId) public pure returns (uint256){
        return tokenId >> 32;
    }

    function getTokenId(uint256 typeId, uint256 index) public pure returns(uint256){
        return (typeId << 32) | index; 
    }
    
    function totalSupply() external view returns (uint256){
        return tokenByIndex.length;
    }
    
    function balanceOf(address owner) external view returns (uint256){
        return _tokenOfOwnerByIndex[owner].length();
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256){
        return _tokenOfOwnerByIndex[owner].at(index);
    }
    
    function isApprovedForAll(address owner, address operator) public view returns (bool){
        return defaultApproved[operator] || _isApprovedForAll[owner][operator];
    }
    
    function tokenURI(uint256 tokenId) external view returns(string memory){
        return string(abi.encodePacked(uri, Strings.toString(tokenId)));
    }
    
    function _setKeeper(address _keeper) external onlyKeeper{
        keeper = _keeper;
    }

    function _setMinter(address minter, bool enable) external onlyKeeper{
        minters[minter] = enable;
    }
    
    function _setDefaultApproved(address account, bool enable) external onlyKeeper{
        defaultApproved[account] = enable;
    }
    
    function _setURI(string memory _uri) external onlyKeeper{
        uri = _uri;
    }
    
    function transferFrom(address from,address to,uint256 tokenId) external approvedOrOwner(tokenId){
        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public approvedOrOwner(tokenId){
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                require(retval == IERC721Receiver.onERC721Received.selector, "NFT:incorrect ERC721Receiver return");
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("NFT:non ERC721Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == from, "NFT:from not owner");
        require(to != address(0) && to != from, "NFT:invalid to");
        if(getApproved[tokenId] != address(0)){
            delete getApproved[tokenId];
        }
        _tokenOfOwnerByIndex[from].remove(tokenId);
        _tokenOfOwnerByIndex[to].add(tokenId);
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        require(to != owner, "NFT:approval to owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "NFT:notOwnerOrApproved");
        getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        require(msg.sender != operator, "NFT:approve to owner");
        _isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function mint(address to, uint256 typeId, uint256 number) external {
        require(minters[msg.sender], "NFT:onlyMinter");
        require(to != address(0), "NFT:zero address");
        uint256 index = totalSupplyOfType[typeId];
        require(number > 0 && (index + number) < 0x100000000 , "NFT:invalid number");
        for(uint256 i = 0; i < number; i++){
            uint256 tokenId = getTokenId(typeId, index + i);
            _tokenOfOwnerByIndex[to].add(tokenId);
            tokenByIndex.push(tokenId);
            ownerOf[tokenId] = to;
            emit Transfer(address(0), to, tokenId);
        }
        totalSupplyOfType[typeId] += number;
    }

    
}