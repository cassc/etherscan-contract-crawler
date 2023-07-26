// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract KevinMfers is ERC721A, Ownable {
    uint256 public constant PRICE = 0.0069 ether;
    uint256 public constant MAX_PER_TXN = 20;

    bool public publicSale = false;
    uint256 public maxSupply = 10000;
    uint256 public freeMaxSupply = 1000;
    string private baseURI;

    constructor() ERC721A("Kevin Mfers", "KEVIN") {}

    // public sale
    modifier publicSaleOpen() {
        require(publicSale, "Public Sale Not Started");
        _;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    // public mint
    modifier insideLimits(uint256 _quantity) {
        require(totalSupply() + _quantity <= maxSupply, "Hit Limit");
        _;
    }

    modifier insideMaxPerTxn(uint256 _quantity) {
        require(_quantity > 0 && _quantity <= MAX_PER_TXN, "Over Max Per Txn");
        _;
    }

    function mint(uint256 _quantity)
        public
        payable
        publicSaleOpen
        insideLimits(_quantity)
        insideMaxPerTxn(_quantity)
    {
        if (totalSupply() + _quantity > freeMaxSupply) {
            require(msg.value >= PRICE * _quantity, "Not Enough Funds");
        }
        _safeMint(msg.sender, _quantity);
    }

    // admin mint
    function adminMint(address _recipient, uint256 _quantity)
        public
        onlyOwner
        insideLimits(_quantity)
    {
        _safeMint(_recipient, _quantity);
    }

    // lock total mintable supply forever
    function decreaseTotalSupply(uint256 _total) public onlyOwner {
        require(_total <= maxSupply, "Over Current Max");
        require(_total >= totalSupply(), "Must Be Over Total");
        maxSupply = _total;
    }

    function setFreeSupply(uint256 _total) public onlyOwner {
        require(_total <= maxSupply, "Over Current Max");
        require(_total >= totalSupply(), "Under Total");
        freeMaxSupply = _total;
    }

    // base uri
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // payout
    address private constant payoutAddress1 =
        0x169F86544558aC4a1a6d90CE2F2a75F9c860A9C9;
    address private constant payoutAddress2 =
        0x43926Fb9676c91412Ba9A7e68ebD70cA080C8Ac4;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAddress1), (balance * 50) / 100);
        Address.sendValue(payable(payoutAddress2), (balance * 50) / 100);
    }
}