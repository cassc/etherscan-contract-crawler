// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "erc721a/contracts/ERC721A.sol";

abstract contract NFT {
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
}

contract ERC721ACustom is ERC721A, Ownable, PaymentSplitter {

    using Strings for uint256;

    struct Token {
        uint16 maxSupply;
        uint16 maxPerWallet;
        uint72 pubSalePrice;
        bool saleIsActive;
        bool supplyLock;
    }

    mapping(address => bool) public fiatAllowlist;
    mapping(address => uint16) public hasMinted;
    Token public token;
    string private baseURI;
    NFT genesis;

    modifier onlyFiatMinter() {
        require(fiatAllowlist[msg.sender], "Not authorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        Token memory _token
    ) ERC721A(_name, _symbol)
      PaymentSplitter(_payees, _shares) {
        baseURI = _uri;
        token = _token;
        transferOwnership(_owner);
    }

    function _startTokenId() override internal pure returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function getClaimIneligibilityReason(address _address, uint256 _quantity) public view returns (string memory) {
        if (totalSupply() + _quantity > uint256(token.maxSupply)) return "NOT_ENOUGH_SUPPLY";
        if (token.saleIsActive) return "";
    }

    function unclaimedSupply() public view returns (uint256) {
        return uint256(token.maxSupply - uint16(totalSupply()));
    }

    function price() public view returns (uint256) {
        return token.pubSalePrice;
    }

    function setGenesis(address _address) external onlyOwner {
        genesis = NFT(_address);
    }

    function addFiatMinter(address _address) public onlyOwner {
        fiatAllowlist[_address] = true;
    }

    function removeFiatMinter(address _address) public onlyOwner {
        delete fiatAllowlist[_address];
    }

    function lockSupply() public onlyOwner {
        token.supplyLock = true;
    }

    function updateConfig(
        uint16 _maxSupply,
        uint16 _maxPerWallet,
        uint72 _pubSalePrice
    ) public onlyOwner {
        require(_maxSupply >= totalSupply(), "Invalid supply");
        if (token.supplyLock) {
            require(_maxSupply == token.maxSupply, "Supply is locked");
        }
        token.maxSupply = _maxSupply;
        token.maxPerWallet = _maxPerWallet;
        token.pubSalePrice = _pubSalePrice;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function updateSaleState(
        bool _saleIsActive
    ) public onlyOwner {
        token.saleIsActive = _saleIsActive;
    }

    function mint(uint16 _quantity) public payable {
        require(token.saleIsActive, "Sale inactive");
        require(price() * _quantity <= msg.value, "ETH incorrect");
        require(uint16(totalSupply()) + _quantity <= token.maxSupply, "Insufficient supply");
        require(genesis.balanceOf(msg.sender) > 0, "No genesis NFT found.");
        uint16 mintedAmount = hasMinted[msg.sender] + _quantity;
        require(mintedAmount <= token.maxPerWallet, "Invalid quantity");
        hasMinted[msg.sender] = mintedAmount;
        _safeMint(msg.sender, _quantity);
    }

    function claimTo(address _address, uint256 _quantity) public payable onlyFiatMinter {
        require(token.saleIsActive, "Sale is not active.");
        require(totalSupply() + _quantity <= uint256(token.maxSupply), "Insufficient supply");
        require(price() * _quantity <= msg.value, "ETH incorrect");
        _safeMint(_address, _quantity);
    }

    function reserve(address _address, uint16 _quantity) public onlyOwner {
        require(totalSupply() + _quantity <= token.maxSupply, "Insufficient supply");
        _safeMint(_address, _quantity);
    }
}