// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MintLimiter.sol";
import "./Whitelistable.sol";

contract LNFTCollection is
    ERC721URIStorage,
    Ownable,
    MintLimiter,
    Whitelistable
{
    using Strings for uint256;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string public hiddenMetadataUri;

    bool public isRevealed = true;

    address private marketplaceAddress;

    function _onlyMarket() private view {
        require(_msgSender() == marketplaceAddress);
    }

    modifier onlyMarket() {
        _onlyMarket();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _marketplaceAddress
    ) ERC721(_name, _symbol) {
        marketplaceAddress = _marketplaceAddress;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mint(
        address _to,
        uint256 _amount,
        string memory _uriPrefix
    ) public onlyMarket returns (uint256[] memory) {
        uint256[] memory mintedTokens = new uint256[](_amount);
        uint256 newTokenId;
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            newTokenId = totalSupply();
            _safeMint(_to, newTokenId);
            _setTokenURI(newTokenId, _uriPrefix);
            mintedTokens[i] = newTokenId;
        }
        return mintedTokens;
    }

    function getTokenURI(uint256 _tokenId) public view returns (string memory) {
        return tokenURI(_tokenId);
    }

    function setTokenURI(uint256 _tokenId, string memory _ipfsLink)
        public
        onlyOwner
    {
        _setTokenURI(_tokenId, _ipfsLink);
    }

    function burnToken(uint256 tokenId) public onlyOwner {
        super._burn(tokenId);
    }

    function setRevealed(bool _isRevealed) public onlyOwner {
        isRevealed = _isRevealed;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }
}