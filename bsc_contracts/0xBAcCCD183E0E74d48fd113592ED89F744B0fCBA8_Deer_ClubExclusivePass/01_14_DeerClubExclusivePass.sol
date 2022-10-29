// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.0;

/**
 * @title Multichain pegged Deer Club Exclusive Pass NFT
 * Add mint (onlyGateway, random tokenId)
 * Add burn (onlyApproved, onlyGateway)
 * Add setGateway (onlyOwner)
 */
contract Deer_ClubExclusivePass is 
    ERC721Enumerable, 
    Ownable, 
    ReentrancyGuard
{
    using Strings for uint256;
    
    bool public enableMint;

    // Base URI for NFT token.
    string private baseTokenURI;

    // Total supply of token.
    uint public MAX_DCE_COUNT = 700;

    struct TokenMintInfo {
        address creater;
        uint64 mintedTimestamp;
    }

    mapping(uint256 => TokenMintInfo) public tokenMintInfo;

    address public gateway;

    modifier onlyGateway() {
        require(msg.sender == gateway);
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor() ERC721 ("Deer Club Exclusive Pass", "DCE Pass") {
        baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmadE6gQ9w2JZesyBgbvS17nTZQLucXMnts96CB3jpxEv8";
    }

    function setEnableMint(bool enable) external onlyOwner {
        enableMint = enable;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function setGateway(address gateway_) public onlyOwner {
        gateway = gateway_;
    }

    function tokenURI(uint256 tokenId)
            public
            view
            virtual
            override
            returns (string memory) {
        require(_exists(tokenId), "DCE: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return baseURI;
    }

    function tokensOfOwner(address owner) public view returns (uint[] memory) {
        uint tokenLength = super.balanceOf(owner);
        uint256[] memory tokenIds = new uint[](tokenLength);
        for (uint i = 0; i < tokenLength; i++) {
            tokenIds[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
        }

        return tokenIds;
    }

    /**
     * @dev Get the tokenId's information
     */
    function getTokenMintInfo(uint _tokenId) public view returns (TokenMintInfo memory) {
        return tokenMintInfo[_tokenId];
    }

    function mint(address account, uint256 tokenId) external onlyGateway {
        require(enableMint, "Mint not enabled now");
        require(totalSupply() < MAX_DCE_COUNT, 
            "Would exceed max supply");

        _mint(account, tokenId);

        tokenMintInfo[tokenId] = TokenMintInfo({creater: account, mintedTimestamp: uint64(block.timestamp)});
    }

    function burn(uint256 tokenId) external onlyGateway {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _burn(tokenId);

        tokenMintInfo[tokenId] = TokenMintInfo({creater: address(0), mintedTimestamp: uint64(0)});
    }
}