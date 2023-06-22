// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MissPH is ERC721, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Overide the base token URI
    string private _baseURIPrefix;
    // How many NFTs can buy per transaction
    uint256 public constant maxTokensPerTransaction = 10;
    // NFTs Price
    uint256 public constant TOKEN_PRICE = 666e18; // 666 RFOX
    // Max total supply of NFTs
    uint256 public constant MAX_NFT = 10000;
    // NFTs sale's currency
    IERC20 public immutable RFOX;
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
        IERC20 _RFOX
    ) ERC721(name, symbol) {
        _baseURIPrefix = baseURI;
        RFOX = _RFOX;
    }

    /// @dev Only owner can migrate base URI
    /// @param baseURIPrefix string prefix of start URI
    function setBaseURI(string memory baseURIPrefix) external onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    /// @dev Owner can safe mint to address
    /// @param to Address of receiver
    function safeMint(address to) external onlyOwner tokenInSupply {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
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
    ) internal override whenNotPaused {
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

    /// @notice Owner withdraw revenue from Sales
    function withdraw() external onlyOwner {
        uint256 balance = RFOX.balanceOf(address(this));
        RFOX.safeTransfer(msg.sender, balance);
    }

    /// @dev Emergency function for direct mint for users
    /// @param to Address of receiver
    /// @param tokenId Which token ID
    function directMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    /// @notice Function that allow user to buy NFTs
    /// @dev Multiple purchase are allowed
    /// @param tokensNumber How many NFTs for buying this round
    function buyNFTs(uint256 tokensNumber) external whenNotPaused {
        require(
            tokensNumber <= maxTokensPerTransaction,
            "Max purchase per one transaction exceeded"
        );

        RFOX.safeTransferFrom(
            msg.sender,
            address(this),
            TOKEN_PRICE.mul(tokensNumber)
        );

        for (uint256 i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}