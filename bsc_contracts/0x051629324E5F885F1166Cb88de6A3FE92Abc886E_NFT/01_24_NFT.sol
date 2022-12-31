// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/CustomNFT.sol";

contract NFT is ERC721EnumerableUpgradeable, CustomNFT, OwnableUpgradeable {
    event SetSaleAndTreasury(address sale, address treasury);
    event ReceiveNFT(address indexed receiver, uint256 indexed tokenId);
    event SetURI(string uri);

    string public NAME;
    string public SYMBOL;
    string private baseURI;

    address public nftSale;
    address public treasury;
    address public constant GNOSIS = 0xe69C24fA49FC2fF52305E4300D627a9094b648f5;
    uint256[50] __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(string memory _name, string memory _symbol)
        external
        initializer
    {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();

        NAME = _name;
        SYMBOL = _symbol;
        transferOwnership(GNOSIS);
    }

    function receiveNFT(address _to, uint256 _tokenId) external override {
        require(
            msg.sender == nftSale || msg.sender == treasury,
            "Not allowed to call contract"
        );

        if (_exists(_tokenId)) safeTransferFrom(msg.sender, _to, _tokenId);
        else _safeMint(_to, _tokenId);

        emit ReceiveNFT(_to, _tokenId);
    }

    function safeMint(address _to, uint256 _tokenId) external onlyOwner {
        _safeMint(_to, _tokenId);
    }

    function setUri(string memory _uri) external onlyOwner {
        baseURI = _uri;

        emit SetURI(_uri);
    }

    function setNftSaleAndTreasury(address _nftSale, address _treasury)
        external
        onlyOwner
    {
        require(
            _nftSale != address(0) && _treasury != address(0),
            "Can't set zero address"
        );

        nftSale = _nftSale;
        treasury = _treasury;

        emit SetSaleAndTreasury(nftSale, treasury);
    }

    function tokensOwnedByUser(address _addr)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        uint256 balance = balanceOf(_addr);
        tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++)
            tokenIds[i] = tokenOfOwnerByIndex(_addr, i);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}