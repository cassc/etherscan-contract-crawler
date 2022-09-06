// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Tradeable.sol";

contract BitMen is Context, ERC721Tradeable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  constructor(address _proxyRegistryAddress) ERC721Tradeable("BitMen", "BMN", _proxyRegistryAddress) {
    _baseTokenURI = "https://nftstorage.link/ipfs/bafkreihz3plunbo4ibyrzljt6szmpqsuwv3j2s4yl5l3wcsx4inm6xr3by";
  }


    function maxSupply() public view virtual returns (uint256) {
        return MAX_SUPPLY;
    }

    function maxMintPerTx() public view virtual returns (uint256) {
        return MAX_PER_TX;
    }

    function maxMintPerWallet() public view virtual returns (uint256) {
        return MAX_PER_WALLET;
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     */
    function mint(
        uint256 amount
    ) public virtual {
        _mintValidate(amount, _msgSender());
        _safeMintTo(_msgSender(), amount);
    }

    function mintTo(address _to) public onlyOwner {
        _mintValidate(1, _to);
        _safeMintTo(_to, 1);
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
      _baseTokenURI = uri;
    }

    function _safeMintTo(
        address to,
        uint256 amount
    ) internal {
      uint256 startTokenId = _nextTokenId.current();
      require(to != address(0), "mint to the zero address");
      require(amount != 0, "quantity must be greater than 0");
      _beforeTokenTransfers(address(0), to, startTokenId, amount);
      for(uint256 i; i < amount; i++) {
        uint256 tokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _mint(to, tokenId);
      }
    }

    function _mintValidate(uint256 amount, address to) internal virtual {
      require(amount <= MAX_PER_TX, string.concat("max amount per transaction is ", Strings.toString(MAX_PER_TX)));
      require(balanceOf(to) + amount <= MAX_PER_WALLET, "cannot mint more than 50 tokens per wallet");
      require(isSaleActive() == true, "sale not active");
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function setPublicSale(bool toggle) public virtual onlyOwner {
        _isActive = toggle;
    }

    function isSaleActive() public view returns (bool) {
        return _isActive;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
        return "https://bafkreihz3plunbo4ibyrzljt6szmpqsuwv3j2s4yl5l3wcsx4inm6xr3by.ipfs.nftstorage.link/";
    }
}