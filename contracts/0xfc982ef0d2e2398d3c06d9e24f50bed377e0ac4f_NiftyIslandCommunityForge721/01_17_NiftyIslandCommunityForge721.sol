// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./CreatorTracking.sol";

contract NiftyIslandCommunityForge721 is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    CreatorTracking
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;
    string private baseUri;

    function initialize(string memory uri) public initializer {
        __ERC721_init("Nifty Island Community Forge", "FORGE");
        __ERC721Enumerable_init();
        __Ownable_init();
        baseUri = uri;
    }

    function mint() public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(msg.sender, tokenId);
        setCreator(tokenId, msg.sender);
    }

    function currentTokenId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function updateBaseUri(string memory newURI) external onlyOwner {
        baseUri = newURI;
        emit BaseUriChanged(newURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return
            bytes(baseUri).length > 0
                ? string(
                    abi.encodePacked(
                        baseUri,
                        Strings.toString(tokenId),
                        "/metadata.json"
                    )
                )
                : "";
    }

    event BaseUriChanged(string uri);
}