// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Store.sol";

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists a trading address, and has minting functionality.
 */
contract DefaultPlayground1155 is ERC1155Upgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    string private _name;
    string private _symbol;

    address public exchangeAddress;
    address public proxyRegistryAddress;
    string private _extendedTokenURI;
    string private contractURI_;

    mapping(uint256 => string) private _eTokenURIs;

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory _tokenURI,
        string memory _contractURI,
        address _proxyRegistryAddress,
        address _exchangeAddress
    ) external initializer {
        __Ownable_init();
        __ERC1155_init(_tokenURI);
        _name = name_;
        _symbol = symbol_;
        proxyRegistryAddress = _proxyRegistryAddress;
        _extendedTokenURI = _tokenURI;
        exchangeAddress = _exchangeAddress;
        contractURI_ = _contractURI;

        transferOwnership(tx.origin);
    }

    function contractURI() external view returns (string memory) {
        return contractURI_;
    }

    function mintTo(
        address _to,
        uint256 _tokenId,
        uint256 amount,
        bytes memory data,
        string memory _metadataURI
    ) public returns (uint256) {
        _mint(_to, _tokenId, amount, data);
        _eTokenURIs[_tokenId] = _metadataURI;
        return _tokenId;
    }

    function transfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 amount,
        bytes memory data,
        string memory _metadataURI
    ) external returns (uint256) {
        uint256 balance = balanceOf(_from, _tokenId);
        uint256 left = amount;
        if (balance != 0) {
            uint256 transfer_ = amount;
            if (balance < amount) {
                transfer_ = balance;
            }
            safeTransferFrom(_from, _to, _tokenId, transfer_, data);
            left = amount - transfer_;
        }
        if (left > 0) {
            _mint(_to, _tokenId, left, data);

            string memory _tokenURI = _eTokenURIs[_tokenId];
            if (bytes(_tokenURI).length == 0)
                _eTokenURIs[_tokenId] = _metadataURI;
        }
        return _tokenId;
    }

    function baseTokenURI() public view virtual returns (string memory) {
        return _extendedTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory _tokenURI = _eTokenURIs[_tokenId];
        string memory base = baseTokenURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, Strings.toString(_tokenId)));
    }

    function modifyExtendedURI(string memory extendedTokenURI_)
        external
        onlyOwner
    {
        _extendedTokenURI = extendedTokenURI_;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}