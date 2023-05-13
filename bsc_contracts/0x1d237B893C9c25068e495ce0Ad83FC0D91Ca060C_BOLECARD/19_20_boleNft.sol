// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IMosNftPool.sol";

contract BOLECARD is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable
{
    using Counters for Counters.Counter;
    using SafeMath for uint;

    Counters.Counter private _tokenIdCounter;

    mapping(address => mapping(uint => uint)) private ownerTokens;

    mapping(address => bool) public asyncEnable;
    mapping(uint => bool) public tokenEnable;

    uint public nftTotalSupply; //发行总量

    uint public holder; //已发行量，也称作持有量

    IMosNftPool public mosNftPool;

    constructor(address _mosNftPool) ERC721("BOLE_NFT", "BOLE") {
        mosNftPool = IMosNftPool(_mosNftPool);
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

    function setMosNftPoolAddress(address _address) external onlyOwner {
        mosNftPool = IMosNftPool(_address);
    }

    function asyncMint() external returns (bool) {
        //同步条件，满足则向上级铸造一张
        address tempAddress;
        address sender = msg.sender;
        uint tokenId = mosNftPool.nftOwner(sender);
        if (tokenEnable[tokenId] || asyncEnable[sender]) return false;
        for (uint i = 0; i < 10; i++) {
            tempAddress = mosNftPool.getSuperior(sender);
            if (tempAddress == address(0)) break;
            if (mosNftPool.nftOwner(tempAddress) > 0) {
                _mint(tempAddress, "www.asdic.com");
                asyncEnable[sender] = true;
                tokenEnable[tokenId] = true;
                return true;
            }
            sender = tempAddress;
        }

        return false;
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
        address _owner
    ) public view returns (uint256[] memory) {
        uint count = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
}