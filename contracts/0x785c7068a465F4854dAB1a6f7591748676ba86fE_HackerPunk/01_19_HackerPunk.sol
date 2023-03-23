// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IHackerPunk.sol";
import "../access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract HackerPunk is Context, ERC721URIStorage, ERC721Enumerable, Pausable, Ownable, IHackerPunk {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    string internal baseURI;

    Counters.Counter private _tokenIds;

    mapping (uint256 => uint256) private _o3Burns; // tokenId -> o3 burned
    mapping (address => bool) private _authorizedMintCaller;

    event LOG_MINT(address indexed to, uint256 tokenId, uint256 o3Burned);
    event LOG_ADD_MINT_CALLER(address indexed caller);
    event LOG_REMOVE_MINT_CALLER(address indexed caller);

    modifier onlyAuthorizedMintCaller() {
        require(_msgSender() == owner() || _authorizedMintCaller[_msgSender()],"HackerPunk: MINT_CALLER_NOT_AUTHORIZED");
        _;
    }

    constructor () ERC721("O3 Hacker Punks", "HP") {}

    function getO3Burned(uint256 tokenId) external override view returns (uint256) {
        require(_exists(tokenId), "HackerPunk: operator query for nonexistent token");
        return _o3Burns[tokenId];
    }

    function mint(address to, uint256 o3Burned) external override whenNotPaused onlyAuthorizedMintCaller {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(to, newTokenId);
        _o3Burns[newTokenId] = o3Burned;

        emit LOG_MINT(to, newTokenId, o3Burned);
    }

    function setBaseURI(string memory _uri) external override onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external override onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function isMintCallerAuthorized(address caller) external override view returns (bool) {
        return caller == owner() || _authorizedMintCaller[caller];
    }

    function setAuthorizedMintCaller(address caller) external override onlyOwner {
        _authorizedMintCaller[caller] = true;
        emit LOG_ADD_MINT_CALLER(caller);
    }

    function removeAuthorizedMintCaller(address caller) external override onlyOwner {
        _authorizedMintCaller[caller] = false;
        emit LOG_REMOVE_MINT_CALLER(caller);
    }

    // Incase erc20 token deposit by mistake.
    function withdraw(address token, address to) external override onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, balance);
    }

    // Pause mint method only, transfer will not be affected.
    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // NFT is not burnable.
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}