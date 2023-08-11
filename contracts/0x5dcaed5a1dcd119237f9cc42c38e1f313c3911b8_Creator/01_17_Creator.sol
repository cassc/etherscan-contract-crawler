// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IOriginNft.sol";

contract Creator is ERC721, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    // origin nft collection
    address public immutable originNft;

    address public immutable creator;

    // mapping creator tokenId to Origin tokenId
    // WARN:some contract tokenId starts from 0
    mapping(uint256 => uint256) public tokenMapping;

    mapping(uint256 => string) public tokenURIs;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    modifier onlyIPFSUri(string memory uri) {
        require(
            bytes(uri)[0] == "i" &&
                bytes(uri)[1] == "p" &&
                bytes(uri)[2] == "f" &&
                bytes(uri)[3] == "s",
            "URI must be IPFS URI"
        );
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "only creator can call");
        _;
    }

    constructor(
        address creator_,
        address originNft_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        originNft = originNft_;
        creator = creator_;
    }

    function getInfo()
        external
        view
        returns (address, address, string memory, string memory)
    {
        return (address(this), originNft, name(), symbol());
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return tokenURIs[tokenId];
    }

    function getOriginalTokenId(
        uint256 tokenId
    ) external view returns (uint256) {
        require(_exists(tokenId), "ERC721: token does not exist");
        require(tokenMapping[tokenId] > 0, "ERC721: token does not have origin token");
        return tokenMapping[tokenId] - 1;
    }

    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(owner, i);
            }
            return result;
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        string memory uri,
        uint256 originTokenId
    ) external onlyCreator onlyIPFSUri(uri) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        tokenURIs[tokenId] = uri;
        tokenMapping[tokenId] = originTokenId + 1;

        address ogOwner = IOriginNft(originNft).ownerOf(originTokenId);
        _safeMint(ogOwner, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        if (to != address(0) && from != to && to != BURN_ADDRESS) {
            // check if the receiver owns the origin NFT
            address ogOwner = IOriginNft(originNft).ownerOf(
                tokenMapping[tokenId] - 1
            );
            require(ogOwner == to, "Receiver must own the Origin NFT.");
        }
        // burn token
        if (to == address(0)||to == BURN_ADDRESS) {
            delete tokenMapping[tokenId];
            delete tokenURIs[tokenId];
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}