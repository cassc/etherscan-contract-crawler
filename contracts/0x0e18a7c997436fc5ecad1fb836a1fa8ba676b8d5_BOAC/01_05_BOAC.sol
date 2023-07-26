// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗
🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗
🐗🐗🐗🐗 Welcome to BOAR CLUB, you can mint your BOAR through the mint function, or visit our official website https://boarclub.vip/🐗🐗🐗🐗
🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗
🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗🐗
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BOAC is ERC721A, Ownable {

    enum EPublicMintStatus {
        NOTACTIVE,
        ALLOWLIST_MINT,
        PUBLIC_MINT,
        CLOSED
    }

    EPublicMintStatus public publicMintStatus;

    string  public baseTokenURI;
    string  public defaultTokenURI;
    uint256 public maxSupply;
    uint256 public publicSalePrice=0.0015 ether;
    mapping(address => uint256) public usermint;

    constructor(
        string memory _baseTokenURI,
        uint _maxSupply
    ) ERC721A ("Boar Club", "BOAC") {
        baseTokenURI = _baseTokenURI;
        maxSupply = _maxSupply;
    _safeMint(_msgSender(), 1);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function mint(uint256 _quantity) external callerIsUser payable {
        require(publicMintStatus == EPublicMintStatus.PUBLIC_MINT, "Public sale closed");
        require(_quantity <= 20, "Invalid quantity");
        require(totalSupply() + _quantity <= maxSupply, "Exceed supply");

        uint256 _remainFreeQuantity = 0;
        if (totalSupply() + _quantity < 4000) {
            if (1 > usermint[msg.sender]) {
                _remainFreeQuantity = 1 - usermint[msg.sender];
            }
        }

        uint256 _needPayPrice = 0;
        if (_quantity > _remainFreeQuantity) {
            _needPayPrice = (_quantity - _remainFreeQuantity) * publicSalePrice;
        }

        require(msg.value >= _needPayPrice, "Ether is not enough");
        usermint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setPublicPrice(uint256 mintprice) external onlyOwner {
        publicSalePrice = mintprice;
    }

    function setPublicMintStatus(uint256 status) external onlyOwner {
        publicMintStatus = EPublicMintStatus(status);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function airdrop(address[] memory airdropaddress, uint256[] memory airdropquantity) public payable onlyOwner {
        for (uint256 i = 0; i < airdropaddress.length; i++) {
            require(totalSupply() + airdropquantity[i] <= maxSupply, "Exceed supply");
            _safeMint(airdropaddress[i], airdropquantity[i]);
        }
    }

    function withdrawMoney() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

}