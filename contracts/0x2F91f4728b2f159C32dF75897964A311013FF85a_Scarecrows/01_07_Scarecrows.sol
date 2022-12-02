// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//    _____
//   / ____|
//  | (___   ___ __ _ _ __ ___  ___ _ __ _____      _____
//   \___ \ / __/ _` | '__/ _ \/ __| '__/ _ \ \ /\ / / __|
//   ____) | (_| (_| | | |  __/ (__| | | (_) \ V  V /\__ \
//  |_____/ \___\__,_|_|  \___|\___|_|  \___/ \_/\_/ |___/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Scarecrows is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 2000;
    uint256 public MAX_MINT = 5;
    uint256 public SALE_PRICE = 0.002 ether;
    bool public mintStarted = false;

    string public baseURI = "ipfs://QmYQnWfvuH2z1NPX9ZYtD9RFo6ANpgJWhraF83dA2JWETK/";
    mapping(address => uint256) public mintPerWallet;

    constructor() ERC721A("Scarecrows", "Scs") {}

    function mint(uint256 _quantity) external payable {
        require(mintStarted, "Minting is not live yet.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Beyond max supply."
        );
        require(
            (mintPerWallet[msg.sender] + _quantity) <= MAX_MINT,
            "Wrong mint amount."
        );
        require(msg.value >= (SALE_PRICE * _quantity), "Wrong mint price.");

        mintPerWallet[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserveMint(uint256 mintAmount) external onlyOwner {
        _safeMint(msg.sender, mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        mintStarted = !mintStarted;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        SALE_PRICE = _newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}