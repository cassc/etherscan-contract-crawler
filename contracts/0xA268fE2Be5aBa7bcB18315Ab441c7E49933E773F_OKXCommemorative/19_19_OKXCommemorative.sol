// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./lib/ERC721LazyMintURIStorageUpgradeable.sol";

interface IProxyRegistry {
    function proxies(address user) external view returns (address);
}

contract OKXCommemorative is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC721LazyMintURIStorageUpgradeable
{
    mapping(address => bool) public _lazyMintWhitelist;

    IProxyRegistry public registry;

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(string memory name_, string memory symbol_)
        public
        initializer
    {
        __ERC721_init(name_, symbol_);
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    //-------------------------------
    //------- Owner functions -------
    //-------------------------------
    function setLazyMintWhitelist(address[] calldata accounts, bool knob)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _lazyMintWhitelist[accounts[i]] = knob;
        }
    }

    function setRegistry(address _registry) external onlyOwner {
        registry = IProxyRegistry(_registry);
    }

    //-------------------------------
    //------- User functions --------
    //-------------------------------

    // transferFrom
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _lazyMintTransferFrom(from, to, tokenId);
    }

    // safeTransferFrom
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _lazyMintSafeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory
    ) public override {
        _lazyMintSafeTransferFrom(from, to, tokenId);
    }

    function _lazyMintSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) private {
        address creator = address(uint160(tokenId >> 96));
        if (creator == from && !_exists(tokenId)) {
            _lazyMintERC721(from, to, tokenId);
        } else {
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
            super.safeTransferFrom(from, to, tokenId, "");
        }
    }

    function _lazyMintTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) private {
        address creator = address(uint160(tokenId >> 96));
        if (creator == from && !_exists(tokenId)) {
            _lazyMintERC721(from, to, tokenId);
        } else {
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
            super.transferFrom(from, to, tokenId);
        }
    }

    function _lazyMintERC721(
        address from,
        address to,
        uint256 tokenId
    ) private {
        address delegator = registry.proxies(from);
        require(
            _lazyMintWhitelist[msg.sender] ||
                msg.sender == from ||
                msg.sender == delegator,
            "OKXCommemorative::safeTransferFrom: msg.sender should be a delegator or in mintWhite list"
        );
        _lazyMint(from, to, tokenId);
    }
}