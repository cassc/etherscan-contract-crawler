// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Overide the base token URI
    string private _baseURIPrefix;
    // Max total supply of NFTs
    uint256 public immutable MAX_NFT;
    // Limit 1 per 1 account address
    mapping(address => bool) public claimed;
    // The token id tracker
    Counters.Counter private _tokenIdCounter;
    // NFTs can not min exceed MAX_NFT
    modifier tokenInSupply() {
        require(
            _tokenIdCounter.current() < MAX_NFT,
            "Exceeded Max NFTs for sales"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 maxNft
    ) ERC721(name, symbol) {
        _baseURIPrefix = baseURI;
        MAX_NFT = maxNft;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Owner can pause the contract in emergency
    function tokensOf(address owner) external view returns (uint256[] memory) {
        uint256 tokenBalance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenBalance);

        for (uint256 i = 0; i < tokenBalance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokenIds;
    }

    /// @dev Only owner can migrate base URI
    /// @param baseURIPrefix string prefix of start URI
    function setBaseURI(string memory baseURIPrefix) external onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    /// @dev Owner can pause the contract in emergency
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Owner can unpause the contract in emergency
    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /// @param tokenId IF of NFTs token
    /// @return Return the token URL link
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @dev Emergency function for direct mint for users
    /// @param to Address of receiver
    /// @param tokenId Which token ID
    function directMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    /// @notice Function that allow user to buy NFTs
    /// @dev Multiple purchase are not allowed
    function buyNFT() external payable whenNotPaused {
        require(
            _tokenIdCounter.current() < MAX_NFT,
            "Tokens number to mint exceeds number of public tokens"
        );

        require(!claimed[msg.sender], "Limit 1 per account");

        claimed[msg.sender] = true;
        safeMint(msg.sender);
    }

    /// @param to Address of receiver
    function safeMint(address to) internal tokenInSupply {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
}