// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "base64-sol/base64.sol";
import "./Freezable.sol";

/* @title GenerativeArtNFT
 * @author minimizer <[email protected]>; https://www.minimizer.art/
 * 
 * Generic smart contract intended to allow for high-quality implementations of a generative art NFT.
 * 
 * Key features:
 *  - Contract initializes with a pre-determined fixed supply and number of tokens to pre-mint.
 *  - Owner can set the price, max tokens to mint at once and whether the sale is active.
 *  - Generates a unique hash for each mint, which the art can use to source entropy. This hash is 
 *    based on the contract address, token id as well as the minter's address and block number.
 *  - The artwork's code can be saved on the contract. It can also be retrieved with the token id and  
 *    hash prepended. This assumes JavaScript as the language used for the art.
 *  - Owner can set token URI for both Web2, IPFS, and Arweave. Each can be read, allowing for owner to 
 *    persist the art in multiple locations. Owner can also decide which URI to use for the tokenURI()
 *    standard interface.
 *  - Owner can freeze contract, after which they can no longer change the artwork or URIs.
 */
contract GenerativeArtNFT is ERC721, Ownable, Freezable {
    
    using SafeMath for uint;
    using Strings for uint;
    using Strings for bytes;
    
    mapping (uint => uint) public tokenCreationBlockNumbers;
    mapping (uint => address) public tokenCreationAddresses;
    
    enum UriType { WEB2, IPFS, ARWEAVE } //WEB2=0, IPFS=1, ARWEAVE=2
    mapping (UriType => string) public baseURIs;
    UriType public activeBaseURI;
    
    string public renderingCode;
    uint public totalSupply;
    uint public maxSupply;
    uint public maxMintAtOnce;
    uint public price;
    bool public isSaleActive;
    

    constructor(string memory name_, string memory symbol_, string memory baseURI_, uint maxSupply_, 
                uint maxMintAtOnce_, uint numberToPremint_, uint initialPrice_) 
    ERC721(name_, symbol_) {
        setBaseURI(UriType.WEB2, baseURI_);
        setActiveBaseURI(UriType.WEB2);
        totalSupply = 0;
        maxSupply = maxSupply_;
        maxMintAtOnce = maxMintAtOnce_;
        isSaleActive = false;
        price = 0;
        
        mintTokens(numberToPremint_);
        price = initialPrice_;
    }
    
    // Provide the hash of the token id. This runs the keccak256 hashing algorithm over contract
    // address, block number of mint, address of minter, and token id to produce a unique value.
    function tokenHash(uint tokenId_) public view onlyValidTokenId(tokenId_) returns(bytes32) {
        return bytes32(keccak256(abi.encodePacked(address(this), 
                                                  tokenCreationBlockNumbers[tokenId_], 
                                                  tokenCreationAddresses[tokenId_], 
                                                  tokenId_)));
    }
    
    // Mint the specified number of tokens to the caller. Sale must be active, and number of tokens 
    // must be less than max mint at once as well as remaining supply. Exact payment required.
    // Owner can mint more than the max mint at once and while the sale is not active.
    // Onwer (or anyone else) cannot exceed max supply.
    function mintTokens(uint numTokens_) public payable {
        require(msg.sender == owner() || numTokens_ > 0, "Did not specify one or more to mint.");
        require(msg.sender == owner() || numTokens_ <= maxMintAtOnce, "Tried to mint more than allowed.");
        require(msg.sender == owner() || isSaleActive, "Sale is not active.");
        
        require(totalSupply + numTokens_ <= maxSupply, "Cannot mint more than remaining supply.");
        require(msg.value == numTokens_.mul(price), "Incorrect amount provided for minting.");
        
        for(uint i = 0; i < numTokens_; i++) {
            uint tokenId = totalSupply;
            _mint(msg.sender, tokenId);
            tokenCreationBlockNumbers[tokenId] = block.number;
            tokenCreationAddresses[tokenId] = msg.sender;
            totalSupply = totalSupply + 1;
        }
    }
    
    // Convenience method, allowing access to all tokens of a given address.
    function tokensOfOwner(address _owner) external view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory result = new uint[](tokenCount);
        uint index = 0;
        for (uint i = 0; i < totalSupply; i++) {
            if(ownerOf(i) == _owner) {
                result[index] = i;
                index += 1;
            }
        }
        return result;
    }
    
    // Owner can set how many tokens can be minted at once. Only relevant when supply remains.
    function setMaxMintAtOnce(uint maxMintAtOnce_) public onlyOwner {
        maxMintAtOnce = maxMintAtOnce_;
    }
    
    // Owner can activate the sale. Only relevant when supply remains.
    function setSaleActive(bool isSaleActive_) public onlyOwner {
        isSaleActive = isSaleActive_;
    }
    
    // Owner can set the price of future mints.
    function setPrice(uint price_) public onlyOwner {
        price = price_;
    }
    
    // Owner can store rendering code (in javascript) which will be persisted forever to re-produce the art
    // Once contract is frozen this can no longer be changed.
    function setRenderingCode(string memory renderingCode_) public onlyOwner onlyWhenNotFrozen {
        renderingCode = renderingCode_;
    }
    
    // Owner can set the base URI for Web2, IPFS, or Arweave. All will be saved separately.
    // Once contract is frozen this can no longer be changed.
    function setBaseURI(UriType uriType_, string memory baseURI_) public onlyOwner onlyWhenNotFrozen { 
        baseURIs[uriType_] = baseURI_;
    }
    
    // Owner can set which URI (Web2, IPFS, or Arweave) will be used for tokenURI(), used by others to retrieve 
    // the metadata of the token.
    // Once contract is frozen this can no longer be changed.
    function setActiveBaseURI(UriType uriType_) public onlyOwner onlyWhenNotFrozen { 
        activeBaseURI = uriType_;
    }
    
    // Owner can transfer accumulated funds to themselves..
    function withdrawAll() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // Owner can freeze the contract, meaning specified fields can no longer be changed by the owner.
    function freeze(string memory confirmation_) public onlyOwner {
        require(keccak256(bytes(confirmation_)) == keccak256(bytes("confirmed to freeze")), 'Invalid confirmation provided for freezing');
        _freeze();
    }
    
    
    // Retreive the rendering code in plain text, for a given token, by combining the token id 
    // and hash with the rendering code. This assumes the language is javascript.
    function renderingCodeForToken(uint tokenId_) public view virtual onlyValidTokenId(tokenId_) returns (string memory) {
        return bytes(renderingCode).length > 0 ? string(abi.encodePacked(bytes("const tokenData={tokenId:"), 
                                                                         bytes(tokenId_.toString()),
                                                                         bytes(",hash:'"),
                                                                         uint(tokenHash(tokenId_)).toHexString(),
                                                                         bytes("'};"),
                                                                         bytes(renderingCode))) : "";
    }
    
    // Similar to the above plain-text version, this retrieves the rendering code in Base64 encoding. This is 
    // useful in cases where the encoding is required or helpful for transmission.
    function renderingCodeForTokenInBase64(uint tokenId_) public view virtual returns (string memory) {
        return Base64.encode(bytes(renderingCodeForToken(tokenId_)));
    }
    
    // Retrieve the web2 token URI if available.
    function web2TokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        return _tokenURI(UriType.WEB2, tokenId_);
    }

    // Retrieve the ipfs token URI if available.
    function ipfsTokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        return _tokenURI(UriType.IPFS, tokenId_);
    }

    // Retrieve the arweave token URI if available.
    function arweaveTokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        return _tokenURI(UriType.ARWEAVE, tokenId_);
    }
    
    // Retrieve the URI which provides the metadata for this token. This is the standard ERC-721 interface
    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        return _tokenURI(activeBaseURI, tokenId_);
    }





    
    function _tokenURI(UriType uriType_, uint tokenId_) internal view virtual onlyValidTokenId(tokenId_) returns (string memory) {
        return bytes(baseURIs[uriType_]).length > 0 ? string(abi.encodePacked(baseURIs[uriType_], tokenId_.toString())) : "";
    }
    
    modifier onlyValidTokenId(uint tokenId_) {
        require(tokenId_ < totalSupply, "Invalid token id.");
        _;
    }
}