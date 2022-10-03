// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelRenga is ERC721A, Ownable {

    string public baseTokenURI;
    string  public defaultTokenURI;
    uint256 public maxSupply = 7777;
    uint256 public salePrice = 0.01 ether;
    mapping(address => uint256) public userMint;
    address payable public autoWallet;
    bool public saleActive;

    constructor(string memory _deafultTokenURI) ERC721A ("PixelRenga", "PR") {
        defaultTokenURI = _deafultTokenURI;
        saleActive = false;
        autoWallet = payable(msg.sender);
        _safeMint(msg.sender, 1);
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function mint(uint256 _quantity) external payable {
        require(saleActive, "Sale is not active");
        require(_quantity + userMint[msg.sender] < 3, "Error - Max Wallet Supply Exceeded");
        require(totalSupply() + _quantity <= maxSupply, "Error - Max Global Supply Exceeded");

        uint256 _needPayPrice = 0;
        if (_quantity + userMint[msg.sender] > 1) {
            _needPayPrice = salePrice;
        }

        require(msg.value >= _needPayPrice, "Error - Insufficient Funds Provided");
        if (msg.value > 0) {
            (bool success,) = autoWallet.call{value : msg.value}("");
            require(success, "Transfer failed.");
        }
        userMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : defaultTokenURI;
    }

    function setBaseURI(string memory _newbaseURI) external onlyOwner {
        baseTokenURI = _newbaseURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setPublicPrice(uint256 mintprice) external onlyOwner {
        salePrice = mintprice;
    }

    function withdrawMoney() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Error - Transfer Failed");
    }

}