// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Tradeable.sol";

contract WKTK is Context, ERC721Tradeable {
  using SafeMath for uint256;
  using SafeMath for int256;
  address payable payableAddress;
  using Counters for Counters.Counter;
  uint256 mintStage = 0;

  constructor(address _proxyRegistryAddress) ERC721Tradeable("WKTK", "WKTK", _proxyRegistryAddress) {
    _baseTokenURI = "ipfs://tbd/";
    payableAddress = payable(0xb1650De5Edf48FAee6787A1f420a7BF4104d0468);
  }

    function publicMint(
        uint256 amount
    ) public virtual payable {
        require(mintStage == 2, "Public mint not started");
        _mintValidate(amount, _msgSender(), false);
        _safeMintTo(_msgSender(), amount);
    }

    function allowlistMint(
        uint256 amount
    ) public virtual payable {
        require(approvedAddresses[_msgSender()] == true, "Not approved for allowlist");
        _mintValidate(amount, _msgSender(), true);
        _safeMintTo(_msgSender(), amount);
    }

    function teamMint(
        uint256 amount,
        address to
    ) public virtual onlyOwner {
        _safeMintTo(to, amount);
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
      _baseTokenURI = uri;
    }

    function mintTo(address _to) public onlyOwner {
        _mintValidate(1, _to, false);
        _safeMintTo(_to, 1);
    }

    function _safeMintTo(
        address to,
        uint256 amount
    ) internal {
      uint256 startTokenId = _nextTokenId.current();
      require(SafeMath.sub(startTokenId, 1) + amount <= MAX_SUPPLY, "collection sold out");
      require(to != address(0), "cannot mint to the zero address");
      
      _beforeTokenTransfers(address(0), to, startTokenId, amount);
        for(uint256 i; i < amount; i++) {
          uint256 tokenId = _nextTokenId.current();
          _nextTokenId.increment();
          _mint(to, tokenId);
        }
      _afterTokenTransfers(address(0), to, startTokenId, amount);
    }

    function _mintValidate(uint256 amount, address to, bool isAllowlist) internal virtual {
      require(amount != 0, "cannot mint 0");
      require(isSaleActive() == true, "sale non-active");
      uint256 balance = balanceOf(to);
      if (balance + amount >= maxFree()) {
        int256 free = int256(maxFree()) - int256(balance);
        if(isAllowlist && free > 0) {
          require(int256(msg.value) >= (int256(amount) - free) * int256(mintPriceInWei()), "incorrect value sent");
        } else {
          require(msg.value >= SafeMath.mul(amount, mintPriceInWei()), "incorrect value sent");
        }
      }
      require(amount <= maxMintPerTx(), "quantity is invalid, max reached on tx");
      require(balance + amount <= maxMintPerWallet(), "quantity is invalid, max reached on wallet");
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function setPublicSale(bool toggle) public virtual onlyOwner {
        _isActive = toggle;
    }

    function setMintStage(uint256 stage) public virtual onlyOwner {
        mintStage = stage;
    }

    function isSaleActive() public view returns (bool) {
        return _isActive;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
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
      return "ipfs://bafkreifig3ip3vr2ryz3zlt2wmkcn6fk5omnzri7mdpvh4nzgflmwa4f74";
    }

    function withdraw() public onlyOwner  {
      (bool success, ) = payableAddress.call{value: address(this).balance}('');
      require(success);
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
}