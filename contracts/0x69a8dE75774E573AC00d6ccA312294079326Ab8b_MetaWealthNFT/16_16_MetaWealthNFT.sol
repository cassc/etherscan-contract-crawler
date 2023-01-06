// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/IMetaWealthModerator.sol";

contract MetaWealthNFT is Initializable, ERC721URIStorageUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIds;

    string private baseURI_;
    IMetaWealthModerator private _metawealthMod;

    modifier onlyAdmin() {
        require(
            _metawealthMod.isAdmin(_msgSender()),
            "MetaWealthNFT: restricted to Admin"
        );
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        IMetaWealthModerator metawealthMod_,
        string memory baseURI
    ) public initializer {
        __ERC721_init(_name, _symbol);
        require(
            address(metawealthMod_) != address(0),
            "MetaWealthNFT: invalid address"
        );
        _metawealthMod = metawealthMod_;
        baseURI_ = baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mint(address to, string memory _tokenURI) external onlyAdmin {
        require(to != address(0), "MetaWealthNFT: invalid address");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
    }

    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) external onlyAdmin {
        _setTokenURI(tokenId, _tokenURI);
    }

    function setBaseURI(string memory _new) external onlyAdmin {
        baseURI_ = _new;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }
}