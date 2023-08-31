// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/specs/IEIP2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EmpropsTokenContract is
    ERC721,
    Ownable,
    DefaultOperatorFilterer,
    EIP2981RoyaltyOverrideCore
{
    using Counters for Counters.Counter;
    Counters.Counter public _mintCount;
    string public baseTokenURI;
    address public minter;
    uint64 public maxSupply;
    mapping(uint256 => string) public dm;

    constructor(
        string memory name,
        string memory symbol,
        uint64 newMaxSupply
    ) ERC721(name, symbol) {
        maxSupply = newMaxSupply;
    }

    // OVERRIDES
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        if (bytes(dm[tokenId]).length > 0) {
            return dm[tokenId];
        }

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
                : "";
    }

    // MESSAGES
    function lockMetadata(uint256 tokenId, string memory metadataLink) public {
        require(
            _ownerOf(tokenId) == msg.sender,
            "ERC721: sender is not the owner"
        );
        dm[tokenId] = metadataLink;
    }

    function updateMaxSupply(uint64 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setBaseTokenURI(string memory newBaseUri) public onlyOwner {
        baseTokenURI = newBaseUri;
    }

    function setMinter(address newMinter) public onlyOwner {
        minter = newMinter;
    }

    function mint(
        address owner,
        uint256 tokenId,
        address author,
        uint16 bps
    ) public {
        require(msg.sender == minter, "Invalid sender, only minter may mint");
        require(_mintCount.current() + 1 <= maxSupply, "Max supply exceeded");
        _mint(owner, tokenId);

        // Increment counter
        _mintCount.increment();

        // Set royalties
        TokenRoyaltyConfig[] memory royaltyConfigs = new TokenRoyaltyConfig[](
            1
        );
        royaltyConfigs[0] = TokenRoyaltyConfig(tokenId, author, bps);
        _setTokenRoyalties(royaltyConfigs);
    }

    // ROYALTIES
    function setTokenRoyalties(
        TokenRoyaltyConfig[] calldata royaltyConfigs
    ) external override onlyOwner {
        _setTokenRoyalties(royaltyConfigs);
    }

    function setDefaultRoyalty(
        TokenRoyalty calldata royalty
    ) external override onlyOwner {
        _setDefaultRoyalty(royalty);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, EIP2981RoyaltyOverrideCore)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
    }

    // Queries
    function getTokensOf(
        address _owner,
        uint256 _collectionId,
        uint256 _maxSupply
    ) public view returns (uint256[] memory) {
        uint256 oneMillion = 1000000;

        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownerTokens = new uint256[](ownerTokenCount);

        uint256 ownerTokenIdx = 0;
        uint256 maxTokenAvailable = (_collectionId * oneMillion) + _maxSupply;
        for (
            uint256 tokenIdx = _collectionId * oneMillion;
            tokenIdx <= maxTokenAvailable;
            tokenIdx++
        ) {
            if (_ownerOf(tokenIdx) == _owner) {
                ownerTokens[ownerTokenIdx] = tokenIdx;
                ownerTokenIdx++;
            }
        }
        return ownerTokens;
    }
}