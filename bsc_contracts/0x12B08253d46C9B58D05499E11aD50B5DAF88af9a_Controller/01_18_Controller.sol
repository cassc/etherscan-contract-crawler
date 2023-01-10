// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Template.sol";
import "./ERC1155Template.sol";

contract Controller is Ownable{

    enum Kind{ERC721, ERC1155}

    struct Token{
        Kind kind;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    event Create(uint256 indexed uuid, address tokenAddress);

    event Mint(uint256 indexed uuid, address indexed from, address indexed to, Token[] tokens);

    event Deposit(uint256 indexed uuid, address indexed from, address indexed to, Token[] tokens);

    event Withdraw(uint256 indexed uuid, address indexed from, address indexed to, Token[] tokens);

    address private _storageAddress;

    constructor(){
        _storageAddress = address(this);
    }

    function storageAddress() public view returns(address){
        return _storageAddress;
    }

    function setStorageAddress(address storageAddress_) public onlyOwner{
        _storageAddress = storageAddress_;
    }

    function setURI(Kind kind, address tokenAddress, string memory uri) public onlyOwner{
        if(kind == Kind.ERC721){
            ERC721Template(tokenAddress).setURI(uri);
        }else if(kind == Kind.ERC1155){
            ERC1155Template(tokenAddress).setURI(uri);
        }
    }

    function create(uint256 uuid, Kind kind, string memory name_, string memory symbol_, string memory uri_) public onlyOwner{
        address tokenAddress;
        if(Kind.ERC721 == kind){
            ERC721Template template = new ERC721Template(name_, symbol_, uri_);
            tokenAddress = address(template);
        }else if(Kind.ERC1155 == kind){
            ERC1155Template template = new ERC1155Template(name_, symbol_, uri_);
            tokenAddress = address(template);
        }
        emit Create(uuid, tokenAddress);
    }

    function mint(uint256 uuid, Token[] memory tokens) public onlyOwner{
        for(uint i;i<tokens.length;i++){
            Token memory token = tokens[i];
            if(token.kind == Kind.ERC721){
                ERC721Template(token.tokenAddress).mint(storageAddress(), token.tokenId);
            }else if(token.kind == Kind.ERC1155){
                ERC1155Template(token.tokenAddress).mint(storageAddress(), token.tokenId, token.amount, "");
            }
        }
        emit Mint(uuid, address(0), storageAddress(), tokens);
    }

    function deposit(uint256 uuid, Token[] memory tokens) public{
        for(uint i;i<tokens.length;i++){
            Token memory token = tokens[i];
            if(token.kind == Kind.ERC721){
                ERC721(token.tokenAddress).safeTransferFrom(msg.sender, storageAddress(), token.tokenId);
            }else if(token.kind == Kind.ERC1155){
                ERC1155(token.tokenAddress).safeTransferFrom(msg.sender, storageAddress(), token.tokenId, token.amount, "");
            }
        }
        emit Deposit(uuid, msg.sender, storageAddress(), tokens);
    }

    function withdraw(uint256 uuid, address to, Token[] memory tokens) public onlyOwner{
        for(uint i;i<tokens.length;i++){
            Token memory token = tokens[i];
            if(token.kind == Kind.ERC721){
                ERC721(token.tokenAddress).safeTransferFrom(storageAddress(), to, token.tokenId);
            }else if(token.kind == Kind.ERC1155){
                ERC1155(token.tokenAddress).safeTransferFrom(storageAddress(), to, token.tokenId, token.amount, "");
            }
        }
        emit Withdraw(uuid, storageAddress(), to, tokens);
    }

    function call(address destination, bytes memory data, uint256 value) external payable onlyOwner{
        (bool success,) = payable(destination).call{value: value}(data);
        require(success);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4){
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4){
        return this.onERC1155Received.selector;
    }

}