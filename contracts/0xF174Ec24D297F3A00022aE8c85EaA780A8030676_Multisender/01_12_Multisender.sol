// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Multisender is Ownable, AccessControl, Pausable{
    
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);  
    }

    function transferERC20(address token, address[] memory tos, uint256[] memory amounts) external onlyRole(OPERATOR_ROLE) whenNotPaused(){
        
        uint256 length = tos.length;
        require(length == amounts.length, "Multisender: tos and amounts length mismatch");
        
        for (uint256 i = 0; i < length; ++i) {
            IERC20(token).transferFrom(msg.sender, tos[i], amounts[i]);
        }
    }

    function transferERC721(address nft, uint256[] memory ids, address[] memory tos) external onlyRole(OPERATOR_ROLE) whenNotPaused{
        
        uint256 length = tos.length;
        require(length == ids.length, "Multisender: tos, ids and amounts length mismatch");
        
        for (uint256 i = 0; i < length; ++i) {
            IERC721(nft).transferFrom(msg.sender, tos[i], ids[i]);
        }
    }

    function transferERC1155(address nft, address[] memory tos, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlyRole(OPERATOR_ROLE) whenNotPaused{
        
        uint256 length = tos.length;
        require(length == ids.length && length == amounts.length, "Multisender: tos, ids and amounts length mismatch");
        
        for (uint256 i = 0; i < length; ++i) {
            IERC1155(nft).safeTransferFrom(msg.sender, tos[i], ids[i], amounts[i], data);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}