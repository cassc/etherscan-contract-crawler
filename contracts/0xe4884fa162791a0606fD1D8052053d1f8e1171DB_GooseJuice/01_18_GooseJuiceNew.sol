// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//            _ _              __  __      _
//      /\   | (_)            |  \/  |    | |
//     /  \  | |_  ___ _ __   | \  / | ___| |_ __ _
//    / /\ \ | | |/ _ \ '_ \  | |\/| |/ _ \ __/ _` |
//   / ____ \| | |  __/ | | | | |  | |  __/ || (_| |
//  /_/    \_\_|_|\___|_| |_| |_|  |_|\___|\__\__,_|

// AlienMeta.wtf - Mowgli + Dev Lrrr

contract GooseJuice is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    IERC20 public seggzCoin;
    address seggzCoinAddress;
    uint256 public price = 100000 * 10**18;
    string public baseURI =
        "https://nft.nftpeel.com/spaceeggz/gen1/gooseJuice/meta/gooseJuice.json";

    event Minted(uint256 indexed idMinted, address indexed minter);

    constructor(address _seggzCoinAddress) ERC721("GooseJuice", "GooseJuice") {
        seggzCoin = IERC20(_seggzCoinAddress);
        seggzCoinAddress = _seggzCoinAddress;
    }

    function setNewUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function getGoosy() external {
        require(seggzCoin.balanceOf(msg.sender) >= price, "not enough");
        seggzCoin.transferFrom(msg.sender, address(this), price);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        emit Minted(tokenId, msg.sender);
    }

    function updateSEGGZCoinAdd(address newAddress) external onlyOwner {
        seggzCoin = IERC20(newAddress);
    }

    function setPriceInputANormalNumber(uint256 newPrice) external onlyOwner {
        price = newPrice * 10**18;
    }

    function withdraw() external onlyOwner {
        seggzCoin.transfer(seggzCoinAddress, seggzCoin.balanceOf(address(this)));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}