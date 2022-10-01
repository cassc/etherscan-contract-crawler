// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721, ERC2981, ERC721URIStorage, Ownable {
    using Address for address payable;
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    // Hash of tiers sequence used as proof that sequence was pre-generated
    // before smart contract was deployed and was not manipulated.
    uint8[1000] private tiers;
    bytes32 public tiersProof;

    // NFT mint rate
    uint256 public mintRate;

    // Whitelisted addresses that can participate in pre-sale
    mapping(address => bool) public preSaleWhitelist;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;

    constructor(bytes32 _tiersProof, uint256 _mintRate)
        ERC721("Insrt.finance", "INSRT")
    {
        tiersProof = _tiersProof;
        mintRate = _mintRate;

        // Set royalty to 15%
        _setDefaultRoyalty(msg.sender, 1500);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // tiers management
    // -----

    // Reveal tiers for minted NFTs
    function setTiers(uint8[1000] memory _tiers) public onlyOwner {
        require(
            sha256(abi.encodePacked(_tiers)) == tiersProof,
            "Tiers does not match"
        );
        tiers = _tiers;
    }

    // Pre-Sale management methods
    // -----

    // Verify if provided address is whitelisted
    function isPreSaleWhitelisted(address _addr) public view returns (bool) {
        if (preSaleWhitelist[_addr]) {
            return true;
        } else {
            return false;
        }
    }

    // Allow owner to add addresses to the whitelist
    function addManyToPreSaleWhitelist(address[] memory _addrs)
        public
        onlyOwner
    {
        unchecked {
            for (uint256 i; i < _addrs.length; i++) {
                preSaleWhitelist[_addrs[i]] = true;
            }
        }
    }

    // Start pre-sale where only whitelisted addresses can participate
    function setPreSaleTime(uint256 _preSaleStartTime, uint256 _preSaleEndTime)
        public
        onlyOwner
    {
        require(
            _preSaleStartTime >= block.timestamp,
            "Pre-sale start time is in the past"
        );
        require(
            _preSaleEndTime >= _preSaleStartTime,
            "Pre-sale end time should be greater then start time"
        );

        preSaleStartTime = _preSaleStartTime;
        preSaleEndTime = _preSaleEndTime;
    }

    // Minting methods
    // -----

    modifier mintAllowed(address _addr) {
        require(preSaleStartTime != 0, "Pre-sale is not initialized yet");
        require(
            preSaleStartTime < block.timestamp,
            "Pre-sale have not started yet"
        );
        require(
            preSaleEndTime < block.timestamp || isPreSaleWhitelisted(_addr),
            "Pre-sale available only for whitelisted addresses"
        );
        require(tokenIdCounter.current() < 1000, "We are sold out");
        _;
    }

    function safeMint(address to)
        public
        payable
        mintAllowed(to)
        returns (uint256 tokenId)
    {
        require(msg.value >= mintRate, "Not enough ETH sent: check price");

        tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        // Allow one NFT per whitelisted address
        if (preSaleWhitelist[to]) {
            preSaleWhitelist[to] = false;
        }

        _safeMint(to, tokenId);
    }

    function withdraw() public {
        payable(owner()).sendValue(address(this).balance);
    }

    // Other methods
    // -----

    // Give away X number of tokens. Will be available only before pre-sale
    function giveAway(address _addr, uint8 limit) public onlyOwner {
        require(
            preSaleStartTime == 0 || preSaleStartTime > block.timestamp,
            "Pre-sale has already started, can't give away"
        );

        unchecked {
            for (uint256 i; i < limit; i++) {
                uint256 tokenId = tokenIdCounter.current();
                tokenIdCounter.increment();

                _safeMint(_addr, tokenId);
            }
        }
    }

    // ERC721 methods required by OpenZeppelin
    // -----

    modifier validTokenId(uint256 _tokenId) {
        require(_tokenId < tiers.length, "Token ID is out of range");
        _;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "http://mint.insrt.finance/nft/";
    }

    function _burn(uint256 _tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(_tokenId);
        _resetTokenRoyalty(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    function tokenTier(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (uint8)
    {
        return tiers[_tokenId] >> 4;
    }

    function tokenVariation(uint256 _tokenId) public view returns (uint8) {
        return tiers[_tokenId] & 15;
    }
}