// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./ProductFactory.sol";
/**
 * @title Product
 * Product - a contract for my non-fungible product.
 */
contract Product is ERC721Tradable {

    ProductFactory private productFactory;
    mapping(address=>uint256[]) private firstOwnerTokens;
    mapping(uint256=>address) private tokenFirstOwner;
    mapping(uint256 => string) private _baseTokenURIs;
    string private currentBaseTokenURI;

    constructor()
    ERC721Tradable("GSMC", "GSMC")
    {
        currentBaseTokenURI = baseTokenURI();
        _setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }

    function baseTokenURI() override public pure returns (string memory){
        return "ipfs://gsmc/";
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId));
        return string(abi.encodePacked(_baseTokenURIs[_tokenId], Strings.toString(_tokenId)));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(balanceOf(to) < productFactory.maxMintQuantity(),"Receiver has reached maximum quantity allowed");
        _transfer(from, to, tokenId);
    }

    function updateFactory (ProductFactory _productFactory) onlyOwner  public {
        productFactory = _productFactory;
        _setupRole(DEFAULT_ADMIN_ROLE,address(_productFactory));
    }

    function updateBaseTokenURI (string memory _baseTokenURI) onlyOwner  public {
        currentBaseTokenURI = _baseTokenURI;
    }

    function listOwnerTokens(address owner) public view returns ( uint256[] memory){
        uint256[] memory ownerTokens;
        uint ownerBalance = balanceOf(owner);
        for(uint i=0; i<ownerBalance ;i++){
            ownerTokens[i] = tokenOfOwnerByIndex(owner,i);
        }
        return ownerTokens;
    }

    function listAllTokens() public view returns (uint256[] memory){
        return _allTokens;
    }

    function _safeMint(address to, uint256 tokenId) internal virtual override {
        _safeMint(to, tokenId, "");
        firstOwnerTokens[to].push(tokenId);
        tokenFirstOwner[tokenId] = to;
        _baseTokenURIs[tokenId] = currentBaseTokenURI;
    }

    function firstOwnerOfToken(uint256 tokenId) public view returns (address) {
        return tokenFirstOwner[tokenId];
    }

    function firstOwnerTokensOf(address owner) public view returns (uint256[] memory){
        return firstOwnerTokens[owner];
    }

}