// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import  '@openzeppelin/contracts/access/Ownable.sol';
import  '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import  '@openzeppelin/contracts/utils/Strings.sol';
import  '../interfaces/IToken.sol';

contract StandardToken is IToken, Ownable, ERC721 {

    using Strings for uint256;

    uint256 private _currentTokenId;
    
    string public baseUri;

    string public defaultUri;

    bool private _saleIsActive;
    
    uint256 public supplyCap;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory defaultUri_,
        uint256 supplyCap_
    ) ERC721(name_, symbol_) {
        supplyCap = supplyCap_;
        defaultUri = defaultUri_;
    }

    function setSaleState(bool saleIsActive) external onlyOwner {
        _saleIsActive = saleIsActive;
    }

    function setsupplyCap(uint256 newsupplyCap) external onlyOwner {
        supplyCap = newsupplyCap;
    }

    function setBaseUri(string calldata newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
    }

    function totalSupply() public view override returns (uint256) {
        return _currentTokenId;
    }

    function mint() public override returns(uint256){
        require(_saleIsActive == true, "Token: Sale is not active");
        require(_currentTokenId < supplyCap, "Token: Reached mint limit");
        _currentTokenId++;
        _mint(msg.sender, _currentTokenId);
        return _currentTokenId;
    }

     function burn(uint256 tokenId) public override returns(bool){
        require(_isApprovedOrOwner(msg.sender,tokenId),"Token: unauthorized");

        _burn(tokenId);
        
        return true;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : defaultUri;
    }
}