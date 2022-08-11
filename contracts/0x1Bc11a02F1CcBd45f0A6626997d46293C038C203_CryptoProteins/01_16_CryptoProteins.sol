//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


import "./Whitelist.sol";


contract CryptoProteins is ERC721URIStorage, Ownable, Whitelist {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    string PRESALE = "PRESALE";
    string WHITELIST = "WHITELIST";
    string PUBLIC = "PUBLIC";

    // TODO put the prereveal JSON URL
    string PREREVEALED_URI = "https://dnaverse.mypinata.cloud/ipfs/QmbXiJBeHcghZ5vb4W64TVnWrxmyG87gLYQPoiAWoaQyjT";
    bool isRevealed = false;

    uint public presaleTokenPrice = 0.9 ether;
    uint public whitelistTokenPrice = 1.37 ether;
    uint public publicTokenPrice = 1.618 ether;
    uint8 public tokenLimitCount = 200;
    uint8 public totalTokensPerWallet = 10;

    string public saleStatus = "PRESALE";
    string private _baseTokenURI;

    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("CryptoProteins", "DNAVRS") {}

    function _baseURI() override internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setSaleStatus(string memory _status) external onlyOwner {
        require (
            equals(_status, PRESALE) ||
            equals(_status, WHITELIST) ||
            equals(_status, PUBLIC),
            "The status has to be one of the available"
        );

        saleStatus = _status;
    }

    function getCurrentSupply() public view returns (uint256) {
        return tokenLimitCount - _tokenIds.current();
    }

    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    function tokenURI(uint256 tokenId)
        public view override returns (string memory)
    {
        if (!isRevealed) {
            return PREREVEALED_URI;
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function mintToken(address _recipient, string memory _tokenURI)
        public payable inWhitelist(_recipient)
    {
        require(
            _tokenIds.current() <= tokenLimitCount,
            "The NFT is closed, we reached the limit"
        );
        require(
            balanceOf(_recipient) < totalTokensPerWallet,
            "You have reach the token limit, can't buy more for now");
        require(
            msg.value >= getTokenPrice(),
            "Not enough ETH sent; check the price!");

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(_recipient, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        payable(owner()).transfer(msg.value);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");

        _tokenURIs[tokenId] = _tokenURI;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        external onlyOwner {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");

        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function getTokenPrice() public view returns (uint) {
        if (equals(saleStatus, PRESALE)) {
            return presaleTokenPrice;
        }

        if (equals(saleStatus, WHITELIST)) {
            return whitelistTokenPrice;
        }

        return publicTokenPrice;
    }

    function equals(string memory a, string memory b) public pure returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}