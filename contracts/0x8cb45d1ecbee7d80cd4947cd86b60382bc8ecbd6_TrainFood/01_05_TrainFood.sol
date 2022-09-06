// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrainFood is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 4269;
    uint256 public MAX_FREE_SUPPLY = 4269;
    uint256 public MINT_PRICE = 0.003 ether;
    uint256 public MAX_MINT_PER_TX = 10;
    uint256 public MAX_FREE_PER_WALLET = 1;
    string public baseURI;
    mapping(address => uint256) private _mintedFreeAmount;

    constructor(string memory initBaseURI) ERC721A("TFART", "TF") {
        baseURI = initBaseURI;
    }

    function mint(uint256 count) external payable {
        uint256 cost = MINT_PRICE;
        bool isFree = ((totalSupply() + count < MAX_FREE_SUPPLY + 1) &&
            (_mintedFreeAmount[msg.sender] + count <=
                MAX_FREE_PER_WALLET)) || (msg.sender == owner());

        if (isFree) {
            cost = 0;
        }

        require(msg.value >= count * cost, "Please send the exact amount.");
        require(totalSupply() + count < MAX_SUPPLY + 1, "Sold out!");
        require(count < MAX_MINT_PER_TX + 1, "Max per TX reached.");

        if (isFree) {
            _mintedFreeAmount[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setFreeAmount(uint256 amount) external onlyOwner {
        MAX_FREE_SUPPLY = amount;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        MINT_PRICE = _newPrice;
    }

    function setMaxFreePerWallet(uint256 _amount) external onlyOwner {
        MAX_FREE_PER_WALLET = _amount;
    }

    function teamMint(uint256 _number) external onlyOwner {
        _safeMint(_msgSender(), _number);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}