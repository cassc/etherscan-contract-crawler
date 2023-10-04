// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract NFTTreasury is IERC721Receiver, IERC1155Receiver {
    address public owner;
    uint256 public constant MAX_LOCKTIME = 630720000;                               
    mapping(address => mapping(uint256 => uint256)) public ERC721LockStruct;

    event ERC721Received(address indexed from,address indexed tokenContract,uint256 indexed tokenID);  
    event ERC1155Received(address indexed from,address indexed tokenContract,uint256 indexed tokenID,uint256 value);  

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        if (interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId) {
            return true;
        }
        return false;
    }    

    constructor() payable {
        owner = msg.sender; 
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only the owner can call this function");
        _;
    } 

    function getBlockInfo() public view returns(uint256 block_number,uint256 block_timestamp) {
        return (block.number,block.timestamp);
    }     

    // ETH
    receive() external payable {}        

    function ETHWithDraw() external onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");  
    } 

    // ERC-20
    function ERC20Withdraw(address tokenContract) external onlyOwner returns (bool) { 
        require(IERC20(tokenContract).balanceOf(address(this)) > 0,"Insufficient balance on the contract");
        return IERC20(tokenContract).transfer(owner, IERC20(tokenContract).balanceOf(address(this))); 
    }         

    // ERC-721 
    function onERC721Received(address,address from,uint256 tokenId,bytes calldata) external override returns (bytes4) {
        emit ERC721Received(from,msg.sender,tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    function ERC721GetLocktime(address tokenContract,uint256 tokenID) external view returns(uint) {
        return ERC721LockStruct[tokenContract][tokenID];
    }    

    function ERC721SetLocktime(address tokenContract,uint256 tokenID,uint256 lockTime) external onlyOwner {
        require(IERC721(tokenContract).ownerOf(tokenID) == address(this),"Contract does not own the ERC-721 token");
        require(ERC721LockStruct[tokenContract][tokenID] == 0,"Locktime can only be set once");
        require(lockTime <= MAX_LOCKTIME,"Locktime must be less than 20 years");
        ERC721LockStruct[tokenContract][tokenID]=block.timestamp + lockTime;
    } 

    function ERC721SafeWithdraw(address tokenContract,uint tokenID) external onlyOwner {
        require((block.timestamp == 0) || (block.timestamp >= ERC721LockStruct[tokenContract][tokenID]),"Withdrawal time not reached");
        IERC721(tokenContract).safeTransferFrom(address(this),owner,tokenID);
        ERC721LockStruct[tokenContract][tokenID] = 0;
    }

    function ERC721UnsafeWithdraw(address tokenContract,uint256 tokenID) external onlyOwner {
        require((block.timestamp == 0) || (block.timestamp >= ERC721LockStruct[tokenContract][tokenID]),"Withdrawal time not reached");
        IERC721(tokenContract).transferFrom(address(this),owner,tokenID);
        ERC721LockStruct[tokenContract][tokenID] = 0;
    }

    function ERC721UnsafeWithdrawbyBlocknum(address tokenContract,uint256 tokenID) external onlyOwner {
        require(block.number >= 500000000,"Block number not reached");
        IERC721(tokenContract).transferFrom(address(this),owner,tokenID);
        ERC721LockStruct[tokenContract][tokenID] = 0;
    }        

    // ERC-1155 
    function onERC1155Received(address,address from,uint256 tokenID,uint256 value,bytes calldata) external override returns(bytes4) {
        emit ERC1155Received(from,msg.sender,tokenID,value);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address,address,uint256[] calldata,uint256[] calldata,bytes calldata) external pure override returns(bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }   

    function ERC1155SafeWithdraw(address tokenContract, address to, uint256 id, uint256 value, bytes memory data) external onlyOwner {
        IERC1155(tokenContract).safeTransferFrom(address(this), to, id, value, data);
    }

    function ERC1155SafeBatchWithdraw(address tokenContract, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) external onlyOwner {
        IERC1155(tokenContract).safeBatchTransferFrom(address(this), to, ids, values, data);
    }    
}