//Contract based on [https://docs.openzeppelin.com/contracts/4.x/erc721](https://docs.openzeppelin.com/contracts/4.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MatrixCatNFT is ERC721, Ownable {

    constructor() ERC721("Matrix Cat", "MATRIX") {
        _admin = _msgSender();
    }


    /* max cats */
    uint256 private _MAX_CATS = 100;

    function MAX_CATS() public view virtual returns (uint256) {
        return _MAX_CATS;
    }

    event ChangeMaxCats(uint256 _afterMaxCats);

    function setMaxCats(uint256 newMaxCats) public onlyOwner {
        require(newMaxCats >= _MAX_CATS, 'Matrix Cat NFT: can not reduce MAX_CATS!');
        _MAX_CATS = newMaxCats;
        emit ChangeMaxCats(_MAX_CATS);
    }

    // can't easily get totalSupply because _owners is private 



    /* URI */ 
    string private __baseURI = 'https://ipfs.io/ipfs/bafybeichsfoc5rmj23euo3vrshrb6h23z2y6fsaltnb36xpkcgeozqh47i/';

    function _baseURI() internal view override virtual returns (string memory) {
        return __baseURI;
    }

    function baseURI() public view returns (string memory) { // for testing
        return __baseURI;
    }

    event ChangeBaseURI(string _afterBaseURI);

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        __baseURI = newBaseURI;
        emit ChangeBaseURI(__baseURI);
    }


    /* admin */ 
    // Besides owner, we define an admin. 
    address private _admin;

    function admin() public view virtual returns (address) {
        return _admin;
    }

    event ChangeAdmin(address _afterAdmin);

    function setAdmin(address newAdmin) public onlyOwner {
        _admin = newAdmin;
        emit ChangeAdmin(_admin);
    }


    /* soft soul bound utility */

    // Utility is only available if the owner of token #id == utilityBindingAddress[#id]
    // owner and write-admin can change this
    mapping(uint256 => address) public _utilityBindingAddress;

    // Place to store additional metadata for the bound utility addresses
    // e.g. the owner's real name
    mapping(uint256 => string) public _utilityMetadata; 

    event ChangeTokenUtilityBinding(uint256 _tokenId, address indexed _utilityBindingAddress, string _utilityMetadata);

    function setTokenUtilityBinding(uint256 tokenId, address bindingAddress, string memory metadata) public {
        _requireMinted(tokenId);
        require(owner() == _msgSender() || _admin == _msgSender(), "MatrxiCatNFT: caller is not the owner or the admin");
        _utilityBindingAddress[tokenId] = bindingAddress;
        _utilityMetadata[tokenId] = metadata;
        emit ChangeTokenUtilityBinding(tokenId, _utilityBindingAddress[tokenId], _utilityMetadata[tokenId]);
    }

    // check if a token's owner is its utility binding address
    function tokenHasUtility(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        return _ownerOf(tokenId) == _utilityBindingAddress[tokenId];
    }


    /* mint */ 

    event MintNFT(address indexed _recipient, uint256 _tokenId);
    event MintNFTWithUtilityBinding(address indexed _recipient, uint256 _tokenId, string metadata);

    function mintNFT(address recipient, uint256 tokenId) public onlyOwner {
        _safeMint(recipient, tokenId);
        emit MintNFT(recipient, tokenId);
    }

    function mintNFTWithUtilityBinding(address recipient, uint256 tokenId, string memory metadata) public onlyOwner {
        _safeMint(recipient, tokenId);
        _utilityBindingAddress[tokenId] = recipient;
        _utilityMetadata[tokenId] = metadata;
        emit MintNFTWithUtilityBinding(recipient, tokenId, metadata);
    }
}