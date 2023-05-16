// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IOldCard.sol";

contract STARCARD is
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable
{
    using Counters for Counters.Counter;
    using SafeMath for uint;

    Counters.Counter private _tokenIdCounter;

    mapping(address => mapping(uint => uint)) private ownerTokens;
    mapping(uint => bool) public tokenEnable;

    IOldCard public oldNft;

    uint public nftTotalSupply;  

    uint public holder; 

    uint public startTime;  

    constructor(address _oldNft) ERC721("STAR_NFT", "STAR") {
        startTime = block.timestamp;
        oldNft = IOldCard(_oldNft);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function _mint(address to, string memory uri) internal returns (uint) {
        require(to != address(0), "safeMint to address is 0x0");

        _tokenIdCounter.increment(); //从1开始
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        holder++;

        return tokenId;
    }

    function map() external {
        //映射
        address sender = msg.sender;
        uint length = oldNft.balanceOf(sender);
        uint[] memory tokenIds = new uint[](length);
        tokenIds = oldNft.tokensOf(sender, 0, length);
        for (uint i = 0; i < tokenIds.length; i++) {
            if (
                oldNft._cardType(tokenIds[i]) == 3 && !tokenEnable[tokenIds[i]]
            ) {
                _mint(sender, "");
                tokenEnable[tokenIds[i]] = true;
            }
        }
    }

    function batchTransfer(
        address _from,
        address _to,
        uint256[] memory _tokens
    ) external {
        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "Not authorized"
        );
        require(_to != address(0), "Invalid recipient address");

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 tokenId = _tokens[i];
            require(ownerOf(tokenId) == _from, "Token not owned by sender");
            safeTransferFrom(_from, _to, tokenId);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getAllTokenIds(
        address owner_
    ) public view returns (uint256[] memory) {
        uint count = balanceOf(owner_);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return tokenIds;
    }
}