// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721Tradeable.sol";

contract Gnomio is Context, ERC721Tradeable {
  using SafeMath for uint256;
  using SafeMath for int256;
  using Counters for Counters.Counter;

  address payable payableAddress;
  bytes32 public merkleRoot = 0x5a8498b7027a0fa9ccf592d4a638f6e944733a2136ffe4c990a677a00cae20bc;

  constructor(address _proxyRegistryAddress) ERC721Tradeable("Gnomio NFT", "GNOMIO", _proxyRegistryAddress) {
    _baseTokenURI = "ipfs://bafybeigtws4kd5gl77ep3myltc2753aflcnz2f742y5qg5jq35z24s3ilm/";
    payableAddress = payable(0x8019D318B2e5ef50b8B937E6e19bEB6C8d9cC291);
  }

    function updateMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
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
    ) public virtual payable {
        require(!isWhitelistSaleActive(), "Only whitelist mint is active, wait until public mint");
        _mintValidate(amount, _msgSender(), false, false);
        _safeMintTo(_msgSender(), amount, 0);
    }

    function whitelistMint(
      bytes32[] calldata _merkleProof,
      uint256 amount
    ) public virtual payable {
      require(isWhitelistSaleActive(), "Whitelist sale is not active");
      require(whitelistMinted[_msgSender()] + amount <= MAX_PER_WL, "Whitelist mint limit reached");

      // verify proof
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof");

      _mintValidate(amount, _msgSender(), false, true);
      whitelistMinted[_msgSender()] = whitelistMinted[_msgSender()] + amount;

      _safeMintTo(_msgSender(), amount, 0);
    }

    function vaultMint(
        uint256 amount
    ) public onlyOwner {
        _mintValidate(amount, _msgSender(), true, false);
        _safeMintTo(_msgSender(), amount, 0);
    }

    function mintTo(address _to) public onlyOwner {
        _mintValidate(1, _to, true, false);
        _safeMintTo(_to, 1, 0);
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
      _baseTokenURI = uri;
    }

    function _safeMintTo(
        address to,
        uint256 amount,
        uint256 forcedTokenId // this is useful only for the airdrop scenario
    ) internal {
      uint256 startTokenId = _nextTokenId.current();
      require(SafeMath.sub(startTokenId, 1) + amount <= MAX_SUPPLY, "minting would exceed total supply");
      require(to != address(0), "mint to the zero address");
      require(amount != 0, "quantity must be greater than 0");
      _beforeTokenTransfers(address(0), to, startTokenId, amount);
      if (forcedTokenId > 0) {
        require(amount == 1, "forcedTokenId can only be used for _safeMintTo with 1 token");
        _mint(to, forcedTokenId);
      } else {
        for(uint256 i; i < amount; i++) {
          uint256 tokenId = _nextTokenId.current();
          _nextTokenId.increment();
          _mint(to, tokenId);
        }
      }
      _afterTokenTransfers(address(0), to, startTokenId, amount);
    }

    function airdropSpecific(uint256[] memory tokenIds, address[] memory recipients) public onlyOwner {
      require(tokenIds.length == recipients.length, "tokenIds and recipients must be the same length");
      //require(_nextTokenId.current() + tokenIds.length == (tokenIds[0] + tokenIds.length - 1), "tokenIds must be sequential and match the internal counter");
      for(uint256 i; i < tokenIds.length; i++) {
        _safeMintTo(recipients[i], 1, tokenIds[i]);
      }
    }

    function _mintValidate(uint256 amount, address to, bool isTeamMint, bool isWhitelist) internal virtual {
      require(isSaleActive() == true, "sale not active");
      if (!isTeamMint) {
          if(isWhitelist) {
            require(msg.value >= SafeMath.mul(amount, wlMintPriceInWei()), "incorrect value sent");
          } else {
            require(msg.value >= SafeMath.mul(amount, mintPriceInWei()), "incorrect value sent");
          }
      }
      require((isTeamMint || amount <= MAX_PER_TX), string.concat("max amount per transaction is ", Strings.toString(MAX_PER_TX)));
      require((isTeamMint || balanceOf(to) + amount <= MAX_PER_WALLET), "cannot mint more than the limit tokens per wallet");
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

    function setWhitelistSale(bool toggle) public virtual onlyOwner {
      _whitelistPhase = toggle;
    }

    function isWhitelistSaleActive() public view returns (bool) {
      return _whitelistPhase;
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
      return "ipfs://bafkreih6iajuonsvopsd7gmyz6shpra3gwzotyqo7dysrfoluoozk5zdcu";
    }

    function withdraw() public onlyOwner  {
      (bool success, ) = payableAddress.call{value: address(this).balance}('');
      require(success);
  }
}