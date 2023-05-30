// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./BabyLlamaSerum.sol";

contract AlienLlama is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    mapping( uint256=>string ) _baseTokenURIs;
    address private _serum;
    address private _babyLLama;

    mapping( uint256=>uint256 ) _injectedSerum;
    bool private _startInjection = false;

    constructor(address babyLlama, address serum) ERC721("ALIEN LLAMA", "ALIEN LLAMA") {
        _serum = serum;
        _babyLLama = babyLlama;
    }

    function injectionSerum( uint256 llamaTokenId, uint256 serumType ) public nonReentrant{
        _injectionSerum(llamaTokenId, serumType);
    }

    function batchInjectionSerum( uint256[] memory llamaTokenIds, uint256[] memory serumTypes ) public nonReentrant{
        require(llamaTokenIds.length == serumTypes.length, "Invalid Parameter");
        require(llamaTokenIds.length <= 30, "Max is 30");
        for( uint256 i; i < llamaTokenIds.length ; i++ ){
            _injectionSerum(llamaTokenIds[i], serumTypes[i]);
        }
    }

    function _injectionSerum( uint256 llamaTokenId, uint256 serumType ) internal{
        require( _injectedSerum[llamaTokenId] == 0, "This is a llama already injected with serum.");
        require( BabyLlamaSerum(_serum).exists(serumType), "The serum type does not match." );
        require( ERC721Enumerable(_babyLLama).ownerOf(llamaTokenId) == msg.sender, "You are not Llama's parents." );
        require( BabyLlamaSerum(_serum).balanceOf(msg.sender, serumType) > 0, "You don't have serum." );
        
        BabyLlamaSerum(_serum).burnSerumForAddress(serumType, msg.sender);
        _injectedSerum[llamaTokenId] = serumType;
        _safeMint(msg.sender, llamaTokenId);
    }

    function injectedSerumOfLlama( uint256 llamaTokenId ) public view returns( uint256 ){
        return _injectedSerum[llamaTokenId];
    }

    function injectedSerumByPage( uint256 page ) public view returns( uint256 [] memory ){
        uint256 [] memory results = new uint256[](101);
        for( uint i; i < 101; i++ ){
            results[i] = _injectedSerum[(page*77)+i];
        }
        return results;
    }

    function injectedSerumsOfOnwer( address owner ) public view returns( uint256[] memory ){
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory serumTypes = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            serumTypes[i] = injectedSerumOfLlama(tokenOfOwnerByIndex(owner, i));
        }
        return serumTypes;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function setBaseURI(string memory baseURI, uint256 serumType) public onlyOwner {
        _baseTokenURIs[serumType] = baseURI;
    }

    function baseTokenURI(uint256 serumType) public view returns (string memory) {
        return _baseTokenURIs[serumType];
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = baseTokenURI( injectedSerumOfLlama( tokenId ) );
        if( bytes(baseURI).length == 0 ){
            return "https://gateway.pinata.cloud/ipfs/QmYwnwndUZV8EQGXoLRPAz79NybaicUyycAwrj2saRn3QM";
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function isStartInjection() public view returns(bool){
        return _startInjection;
    }

    function startInjection() public onlyOwner{
        _startInjection = true;
    }

    function endInjection() public onlyOwner{
        _startInjection = false;
    }

}