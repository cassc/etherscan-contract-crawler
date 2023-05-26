// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IStlmNFT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function creators(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


/// @title LMvXNFT
/// @notice A contract for secondary version living modules in the STARL ecosystem
contract LMvXNFT is ERC721("Living Modules vX", "LMVX"), Ownable, IERC721Receiver {

    /// @notice event emitted when token URI is updated
    event LMvXTokenUriUpdated(
        uint256 indexed _tokenId,
        string _tokenUri
    );

    /// @notice event emitted when creator is updated
    event LMvXCreatorUpdated(
        uint256 indexed _tokenId,
        address _creator
    );

    IStlmNFT public stlmNft;

    /// @dev Base TokenID, tokens below this ID are for old contract.
    uint256 public baseTokenId;

    /// @dev current max tokenId
    uint256 public tokenIdPointer;

    /// @dev TokenID -> Creator address
    mapping(uint256 => address) public creators;

    /**
     @param _baseTokenId Token id starts from this number
     @param _baseUri Base token uri
     */
    constructor(IStlmNFT _stlmNft, uint256 _baseTokenId, string memory _baseUri) public {
        stlmNft = _stlmNft;
        baseTokenId = _baseTokenId;
        tokenIdPointer = _baseTokenId;
        _setBaseURI(_baseUri);
    }

    /**
     @notice Mints a living module
     @dev Only owner can mint token
     @param _beneficiary Recipient of the NFT
     @param _creator Creator of the NFT
     @param _tokenUri URI for the token being minted
     @return uint256 The token ID of the token that was minted
     */
    function mint(address _beneficiary, address _creator, string memory _tokenUri) external onlyOwner returns (uint256) {
        tokenIdPointer = tokenIdPointer.add(1);
        uint256 tokenId = tokenIdPointer;
        _safeMint(_beneficiary, tokenId);
        creators[tokenId] = _creator;
        _setTokenURI(tokenId, _tokenUri);
        emit LMvXTokenUriUpdated(tokenId, _tokenUri);
        emit LMvXCreatorUpdated(tokenId, _creator);
        return tokenId;
    }    

    /**
     @notice Unmigrate LMvX NFT to the old STLM contract
     @dev Only owner of migrated token
     @param tokenId TokenId of token to migrate
     @return uint256 The token ID of the token that is unmigrated
     */
    function unmigrate(uint256 tokenId) external returns (uint256) {
        require(stlmNft.ownerOf(tokenId) == address(this), "Not migrated item");
        require(ownerOf(tokenId) == msg.sender, "Migrated item is not owed");
        stlmNft.safeTransferFrom(address(this), msg.sender, tokenId);

        _burn(tokenId);
        return tokenId;
    }

    /**
     @notice Batch mints living modules
     @dev Only owner can mint tokens
     @param _owners List of owners of tokens created
     @param _creators List of creators of tokens created
     @param _uris List of metadata uri of tokens creating
     */
    function batchMint(address[] calldata _owners, address[] calldata _creators, string[] calldata _uris) external onlyOwner {
        require(_owners.length == 1 || _owners.length == _uris.length, "Length of _owners should be one or same");
        require(_creators.length == 1 || _creators.length == _uris.length, "Length of _creators should be one or same");
        for(uint256 i=0; i<_uris.length; i++) {
            tokenIdPointer = tokenIdPointer.add(1);
            uint256 tokenId = tokenIdPointer;
            _safeMint(_owners.length > 1 ? _owners[i] : _owners[0], tokenId);
            _setTokenURI(tokenId, _uris[i]);
            creators[tokenId] = _creators.length > 1 ? _creators[i] : _creators[0];
            emit LMvXTokenUriUpdated(tokenId, _uris[i]);
            emit LMvXCreatorUpdated(tokenId, creators[tokenId]);
        }
    }

    /**
     @notice Updates the token URI of a given token
     @dev Only admin or smart contract
     @param _tokenId The ID of the token being updated
     @param _tokenUri The new URI
     */
    function setTokenURI(uint256 _tokenId, string calldata _tokenUri) external onlyOwner {
        _setTokenURI(_tokenId, _tokenUri);
        emit LMvXTokenUriUpdated(_tokenId, _tokenUri);
    }

    /**
     @notice Updates the token URI of a given token
     @dev Only admin or smart contract
     @param _tokenIds The ID of the tokens being updated
     @param _tokenUris The new URIs
     */
    function batchSetTokenURI(uint256[] memory _tokenIds, string[] calldata _tokenUris) external onlyOwner {
        require(
            _tokenIds.length == _tokenUris.length,
            "Must have equal length arrays"
        );
        for( uint256 i; i< _tokenIds.length; i++){
            _setTokenURI(_tokenIds[i], _tokenUris[i]);
            emit LMvXTokenUriUpdated(_tokenIds[i], _tokenUris[i]);
        }
    }

    /**
     @notice Updates the token URI of a given token
     @dev Only admin or smart contract
     @param _tokenIds The ID of the token being updated
     @param _creators The new creators
     */
    function batchSetCreator(uint256[] memory _tokenIds, address[] calldata _creators) external onlyOwner {
        require(
            _tokenIds.length == _creators.length || _creators.length == 1,
            "Must have equal length arrays"
        );
        for( uint256 i; i< _tokenIds.length; i++){
            creators[_tokenIds[i]] = _creators.length == 1 ? _creators[0] : _creators[i];
            emit LMvXCreatorUpdated(_tokenIds[i], creators[_tokenIds[i]]);
        }
    }

    /**
     @notice Handler for migrated token transfer
     @dev Only owner of token to migrate
     @param operator Opeartor of token transfer, here should be owner of token
     @param from Owner of token, should be same as operator here
     @param tokenId Token ID of token to migrate from old contract
     @param data Creator address where creator royalty will be paid
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        require(operator==from || operator==address(this), "Should be transferred from owner or this contract");
        require(from!=address(0x00), "Shouldn't be transferred from zero address");
        require(tokenId <= baseTokenId, "Invalid token id");
        require(data.length == 20, "Invalid creator uri passed from data");

        _safeMint(from, tokenId);
        creators[tokenId] = bytesToAddress(data);
        string memory _tokenURI = stlmNft.tokenURI(tokenId);
        _setTokenURI(tokenId, _tokenURI);
        emit LMvXTokenUriUpdated(tokenId, _tokenURI);
        emit LMvXCreatorUpdated(tokenId, creators[tokenId]);

        return this.onERC721Received.selector;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }
}