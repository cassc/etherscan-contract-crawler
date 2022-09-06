// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

 /// @title A modified ERC721 token with non transferability and roles.
 /// @author Inish Crisson
 /// @author Jesse Farese
 /// @author Kunz Mainali
 /// @author Pat White
 /// @dev This contract is a modified version of the ERC721 token. 
 /// @dev Intended for deployment via a factory contract.
contract BitwaveNTTBaseUri is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct BaseUri {
        string uri;
        string suffix;
    }

    /// @notice Constructor, sets name, symbol, and admin/minter roles.
    constructor(string memory _name, string memory _symbol, address _admin) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _admin);
    }

    /// @notice Iterating uint for tokenId creation.
    uint256 public _currentTokenIndex;

    /// @notice Iterating uint for URI storage.
    uint256 internal _currentUriIndex;

    /// @notice two mappings for constant time URI retrieval.
    mapping(uint256 => uint256) internal _tokenUriMap;
    mapping (uint256 => BaseUri) internal _baseUriMap;

    /// @notice A custom function to mint NTTs in bulk. 
    /// @notice Only callable by the owner of the contract.
    /// @param to the array of addresses to mint the NTTs to.
    /// @param baseUri the base URI to use for the NTTs.
    /// @param suffix the suffix to use for the NTTs.
    /// @param startingTokenId the expected existing value of _currentTokenIndex.
    function mint(address[] memory to, string memory baseUri, string memory suffix, uint256 startingTokenId) public onlyRole(MINTER_ROLE) {
        require(_currentTokenIndex + 1 == startingTokenId, "expectedTokenId does not match _currentTokenIndex");
        _currentUriIndex += 1;
        _baseUriMap[_currentUriIndex] = BaseUri(baseUri, suffix);
        for (uint256 i = 0; i < to.length; i++) {
            _currentTokenIndex += 1;
            _mint(to[i], _currentTokenIndex);
            _tokenUriMap[_currentTokenIndex] = _currentUriIndex;
        }
    }

    /// @notice Overrides the ERC721 transferFrom function to add NTT functionality.
    /// @notice NTT transfers require approval from Bitwave & the owner of the NTT.
    /// @param from address of the sender
    /// @param to address of the recipient
    /// @param tokenId the id of the token to be transferred
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) virtual override {
        ERC721._approve(msg.sender, tokenId);
        ERC721.transferFrom(from, to, tokenId);
    }

    /// @notice Transfers a token to a new owner. This function is called by the owner of the contract.  
    /// @param from the address of the current owners of the token.
    /// @param to the address of the new owner of the token.
    /// @param tokenId the id of the token to be transfered.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) virtual override {
        ERC721._approve(msg.sender, tokenId);
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    /// @notice Transfers a token to a new owner. This function is called by the owner of the contract.  
    /// @param from the address of the current owners of the token.
    /// @param to the address of the new owner of the token.
    /// @param tokenId the id of the token to be transfered.
    /// @param data additional data to be sent with the transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public onlyRole(DEFAULT_ADMIN_ROLE) virtual override {
        ERC721._approve(msg.sender, tokenId);
        ERC721.safeTransferFrom(from, to, tokenId, data);
    }

    /// @notice Transfers a token to a new owner. This function is called by the admin of the contract.
    /// @param _to the address of the new owner of the token.
    /// @param _tokenId the id of the token to be transfered.
    function approve(address _to, uint256 _tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) virtual override {
        ERC721._approve(_to, _tokenId);
    }

    /// @notice Burns a token. This function is called by the admin of the contract.
    /// @param _tokenId the id of the token to be burnt.
    function burn(uint256 _tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC721._burn(_tokenId);
    }

    /// @notice returns the URI of the image associated with the token.
    /// @param tokenId the id of the token to be queried.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "UN1");
        return string(
            abi.encodePacked(_baseUriMap[_tokenUriMap[tokenId]].uri, 
            "/", 
            Strings.toString(tokenId), 
            _baseUriMap[_tokenUriMap[tokenId]].suffix));
    }

    /// @notice override function required by solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}