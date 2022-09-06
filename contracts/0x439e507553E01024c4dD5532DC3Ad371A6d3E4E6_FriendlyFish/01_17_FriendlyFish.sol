// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright 2022 FriendlyFish

pragma solidity ^0.8.15;

import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
/*
 _____  ____   ____    ___  ____   ___    _      __ __  _____  ____ _____ __ __
|     ||    \ |    |  /  _]|    \ |   \  | |    |  |  ||     ||    / ___/|  |  |
|   __||  D  ) |  |  /  [_ |  _  ||    \ | |    |  |  ||   __| |  (   \_ |  |  |
|  |_  |    /  |  | |    _]|  |  ||  D  || |___ |  ~  ||  |_   |  |\__  ||  _  |
|   _] |    \  |  | |   [_ |  |  ||     ||     ||___, ||   _]  |  |/  \ ||  |  |
|  |   |  .  \ |  | |     ||  |  ||     ||     ||     ||  |    |  |\    ||  |  |
|__|   |__|\_||____||_____||__|__||_____||_____||____/ |__|   |____|\___||__|__|
*/

contract FriendlyFish is ERC721, ERC721Enumerable, ERC721Royalty, Ownable {
    event PermanentURI(string _value, uint256 indexed _id);

    string public constant baseTokenURI = "ipfs://QmPod5EwbZDrP9rEH2gkUBKYbXPP68S91VuXKWvy1L4joM/";
    uint256 public constant maxSupply = 10000;
    uint256 public constant maxMintAmount = 5;

    uint256 public price;
    address public proxyRegistryAddress;
    uint public mintStartTime;

    constructor(
        uint256 price_,
        address proxyRegistryAddress_
    ) ERC721("friendlyfish", unicode"ƒƒ") {
        price = price_;
        proxyRegistryAddress = proxyRegistryAddress_;
        setDefaultRoyalty(owner(), 1000);
        mintStartTime = 1660849200;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    function hasMintingStarted() public view returns (bool) {
      return block.timestamp >= mintStartTime;
    }


    function getTime() public view returns (uint) {
      return block.timestamp;
    }

    function mint(uint256 mintCount) public payable {
        uint256 supply = totalSupply();

        require(hasMintingStarted(), "minting has not started yet");
        require(mintCount <= maxMintAmount, "max mint count of 5 exceeded");
        require(supply + mintCount <= maxSupply, "max token supply exceeded");
        require(msg.value >= price * mintCount, "insufficient payment value");

        for (uint256 i = 0; i < mintCount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function reserveMint(uint256 mintCount) public onlyOwner {
        uint256 supply = totalSupply();

        require(supply + mintCount <= maxSupply, "max token supply exceeded");

        for (uint256 i = 0; i < mintCount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(owner()).send(address(this).balance));
    }

    function setDefaultRoyalty(address recipient, uint96 fraction) public onlyOwner {
        _setDefaultRoyalty(recipient, fraction);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    // Required overrides
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Emit frozen token URI, which always is on IPFS
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to
     * enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override(ERC721, IERC721)
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress != address(0)) {
          ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
          if (address(proxyRegistry.proxies(owner)) == operator) {
              return true;
          }
        }

        return super.isApprovedForAll(owner, operator);
    }
}

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on
 * unneeded transactions to approve contract use for users.
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}