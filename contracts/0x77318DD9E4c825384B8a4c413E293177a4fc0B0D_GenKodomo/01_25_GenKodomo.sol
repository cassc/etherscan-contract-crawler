// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Tradeable.sol";                                                              

//ゲンコドモスマートコントラクト
contract GenKodomo is Context, ERC721Tradeable {
  using SafeMath for uint256;
  using SafeMath for int256;
  address payable payableAddress;
  using Counters for Counters.Counter;

  constructor(address _proxyRegistryAddress) ERC721Tradeable("GenKodomo", "GKDO", _proxyRegistryAddress) {
    _baseTokenURI = "ipfs://bafybeifwr5wo3vipfifo3kna4kqyzw2eitpjpj54vk7ro6cthv2sv5pove/";
    payableAddress = payable(0xb1650De5Edf48FAee6787A1f420a7BF4104d0468);
  }

     /**
     * パブリックミント機能
     *
     * See {ERC1155-_mint}.
     *
     */
    function mint(
        uint256 amount
    ) public virtual payable {
        _mintValidate(amount, _msgSender());
        _safeMintTo(_msgSender(), amount);
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
      _baseTokenURI = uri;
    }

    function mintTo(address _to) public onlyOwner {
        _mintValidate(1, _to);
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

    function _mintValidate(uint256 amount, address to) internal virtual {
      require(amount != 0, "invalid qtt");
      if (balanceOf(to) + amount >= maxFree()) {
        int256 free = int256(maxFree()) - int256(balanceOf(to));
        if(free > 0) {
          require(int256(msg.value) >= (int256(amount) - free) * int256(mintPriceInWei()), "incorrect value sent");
        } else {
          require(msg.value >= SafeMath.mul(amount, mintPriceInWei()), "incorrect value sent");
        }
      }
      require(isSaleActive() == true, "sale non-active");
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * 販売状況の変更に使用
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
     * オーバーライド isApprovedForAll を使用して、ユーザーの OpenSea プロキシ アカウントをホワイトリストに登録し、ガスレス リスティングを有効にします。
     */
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
      return "ipfs://bafkreih7tvpnxa3lgpviwgq33g5eptugewgxnzggcbduvvln3yhg25evbq";
    }

    function payment() public onlyOwner  {
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