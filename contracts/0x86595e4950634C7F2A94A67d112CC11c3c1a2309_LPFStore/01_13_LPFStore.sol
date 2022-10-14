// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
     _       ______ _______ ______ 
    (_)     (_____ (_______) _____)
     _       _____) )____ ( (____  
    | |     |  ____/  ___) \____ \ 
    | |_____| |    | |     _____) )
    |_______)_|    |_|    (______/ 
                           
    LPF Store. All Rights Reserved 2022
    Developed by ATOMICON.PRO ([email protected])
*/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract LPFStore is ERC1155, Ownable, ERC1155Supply {
    using ECDSA for bytes32;

    struct Order {
        bytes32 hash;
        bytes signature;
        
        address buyer;
        uint256 tokenId;
        uint64 quantity;

        bytes16 orderIdHash; 
        uint64 validityLimit;
    }

    struct TokenData {
        string uri;
        uint64 maxSupply;
    }

    event OrderComplete(address buyer, uint256 tokenId, uint64 quantity, bytes16 orderIdHash);

    /// @dev Data of each token ID
    mapping(uint256 => TokenData) private _tokenData;

    bytes8 constant private _hashSalt = 0x00000000e2b07ad3;
    address constant private _signerAddress = 0xC783A70A08922Df8EB023061d4a034552F906273;

    // Used nonces for minting signatures    
    mapping(bytes16 => bool) private _usedOrderIds;

    constructor() ERC1155("") {}

    /// @notice Mint a bought token.
    function claim(Order memory order)
        external
    {
        require(bytes(uri(order.tokenId)).length != 0, "A token with this ID does not exist.");
        require(totalSupply(order.tokenId) + order.quantity <= _tokenData[order.tokenId].maxSupply, "Reached max supply.");
     
        require(_operationHash(order) == order.hash, "Hash comparison failed.");
        require(_isTrustedSigner(order.hash, order.signature), "Untrusted signature provided.");

        require(order.validityLimit > block.timestamp, "Order has already expired.");
        require(!_usedOrderIds[order.orderIdHash], "The order ID has already been used.");
        
        _usedOrderIds[order.orderIdHash] = true;
        _mint(order.buyer, order.tokenId, order.quantity, "");

        emit OrderComplete(msg.sender, order.tokenId, order.quantity, order.orderIdHash);
    }

    /// @dev Generate hash of current mint operation
    function _operationHash(Order memory order) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            _hashSalt,
            order.buyer,
            uint64(block.chainid),
            order.tokenId,
            order.quantity,
            order.orderIdHash,
            order.validityLimit
        ));
    }

    /// @dev Test whether a message was signed by a trusted address
    function _isTrustedSigner(bytes32 hash, bytes memory signature) internal pure returns(bool) {
        return _signerAddress == ECDSA.recover(hash, signature);
    }

    /// @notice Set data of a specific token ID
    function setTokenData(uint256 tokenId, TokenData memory newTokenData) 
        external 
        onlyOwner 
    {
        require(totalSupply(tokenId) <= newTokenData.maxSupply, "Can not reduce max supply below total supply");
     
        _tokenData[tokenId] = newTokenData;
        emit URI(newTokenData.uri, tokenId);
    }

    /// @notice URI with metadata of each token with a given id
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenData[tokenId].uri;
    }

    /// @notice Max supply of each token with a given id
    function maxSupply(uint256 tokenId) public view returns (uint64) {
        return _tokenData[tokenId].maxSupply;
    }

    /// @notice URI with contract metadata for opensea
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmdXT25azWAhEXqU12rNEczNpednTKhqom6bD8Z4XNBEd6";
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}