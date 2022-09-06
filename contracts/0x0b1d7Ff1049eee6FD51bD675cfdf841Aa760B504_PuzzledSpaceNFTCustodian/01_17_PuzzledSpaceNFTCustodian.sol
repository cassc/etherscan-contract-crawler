//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./NFTTransfer.sol";

contract PuzzledSpaceNFTCustodian is
    Ownable,
    ERC721Holder,
    ERC1155Holder,
    ReentrancyGuard,
    NFTTransfer 
{
    using ECDSA for bytes32;
    using ERC165Checker for address;
    
    event Received(
        address indexed contractAddress,
        address indexed from,
        uint256 indexed id,
        uint256 value
    );

    event Withdrawn(
        address indexed sender,
        address indexed contractAddress,
        uint256 indexed tokenId
    );

    mapping(uint256 => bool) public operationStatus;
    
    constructor(){
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) public virtual override returns (bytes4) {
        emit Received(msg.sender, from, tokenId, 1);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) public virtual override returns (bytes4) {
        emit Received(msg.sender, from, id, value);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) public virtual override returns (bytes4) {
        for(uint16 i = 0; i<ids.length; i++){
            emit Received(msg.sender, from, ids[i], values[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function withdrawal(
        address contractAddress,
        uint256 tokenId,
        uint256 value,
        address to,
        uint256 signatureExpirationTime,
        uint256 operationId,
        bytes memory signature
    ) external nonReentrant {
        require(!operationStatus[operationId], "operation executed");
        operationStatus[operationId] = true;
        
        require(
            signatureExpirationTime > block.timestamp,
            "withdrawal: signature expired"
        );
        bytes32 hash = keccak256(
               abi.encodePacked(
                    contractAddress,
                    tokenId,
                    value,
                    to,
                    signatureExpirationTime,
                    operationId,
                    msg.sender,
                    block.chainid,
                    address(this)
                )
            );
        bytes32 hashEth = hash.toEthSignedMessageHash();
        require(
            hashEth.recover(signature) == owner(), 
            "withdrawal: wrong signature"
        );
        
        _transfer(contractAddress, tokenId, address(this), to, value);

        emit Withdrawn(msg.sender, contractAddress, tokenId);
    }

}