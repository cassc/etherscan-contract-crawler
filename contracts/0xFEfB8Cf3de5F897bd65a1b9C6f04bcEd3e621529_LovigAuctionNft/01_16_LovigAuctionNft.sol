pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';


contract LovigAuctionNft is ERC2981, ERC721Enumerable, Ownable, ReentrancyGuard {
    
    using Strings for uint256;

    string public uriPrefix = '';
    string public uriSuffix = '.json';

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _uriPrefix,
        address[] memory royaltyReceivers,
        uint96[] memory royalties
    ) ERC721(_tokenName, _tokenSymbol) {
        require(royaltyReceivers.length == royalties.length, "number of royatlies and receivers must match");

        uriPrefix = _uriPrefix;

        for (uint i = 0; i < royalties.length; ++i) {
            _setTokenRoyalty(i, royaltyReceivers[i], royalties[i]);
        }
    }

    modifier paperOnly() {
        require(msg.sender == 0x927a5D4d0e720379ADb53a895f8755D327faF0F5
            || msg.sender == 0xf3DB642663231887E2Ff3501da6E3247D8634A6D);
        _;
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 royalty) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, royalty);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function claimTo(address receipient, uint256 tokenId) public payable paperOnly {
        _safeMint(receipient, tokenId);
    }

    function ownerMint(uint256 tokenId) public onlyOwner {
        _safeMint(owner(), tokenId);
    }

    function setUriPrefix(string calldata _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}