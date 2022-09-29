// SPDX-License-Identifier: MIT

// /ᐠ｡▿｡ᐟ\*ᵖᵘʳʳ*
// KatMonstarz Honorary
// author: sadat.eth

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KatMonstarzHonorary is ERC721, IERC2981, ERC721URIStorage, Ownable {
    using Strings for uint256;
    
    // Marketplace configuration

    string private baseURI;
    string private collectionURI;
    address private proxyAddr;
    address private royaltyReceiver;
    uint256 private royaltyPercentBps;

    // Project configurations

    bool public paused = false;
    uint256 private counter;
    mapping(address => bool) private partner;

    constructor() ERC721("KatMonstarzHonorary", "KMH") {}

    // Custom functions onlyOwner

    function mint(address to, string memory uri) public onlyOwner {
        require(!paused, "contract paused");
        counter++;
        uint256 tokenId = counter;
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        
    }

    function setCollectionURI(string memory _collectionURI) public onlyOwner {
        collectionURI = _collectionURI;
    }

    function setOpenseaProxy(address _proxyAddr) public onlyOwner {
        proxyAddr = _proxyAddr;
    }

    function setPartner(address _partnerAddr) public onlyOwner {
        partner[_partnerAddr] = !partner[_partnerAddr];
    }

    function setPaused() public onlyOwner {
        paused = !paused;
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setRoyalty(address _royaltyReceiver, uint256 _percentBPs) public onlyOwner {
        royaltyReceiver = _royaltyReceiver;
        royaltyPercentBps = _percentBPs;
    }

    // Standard functions marketplaces

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyAddr);
        if (address(proxyRegistry.proxies(owner)) == operator || partner[operator]) return true;
        return super.isApprovedForAll(owner, operator);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return (royaltyReceiver, (_salePrice * royaltyPercentBps) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    function contractURI() public view returns (string memory) {
        return collectionURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return counter;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function walletOfOwner(address _address) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(_address);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loop = totalSupply();
        for (uint256 i = 0; i < _loop; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == _address) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance -1] == 0) { _loop++; }
        }
        return _tokens;
    }
}

contract OwnableDelegateProxy { }

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}