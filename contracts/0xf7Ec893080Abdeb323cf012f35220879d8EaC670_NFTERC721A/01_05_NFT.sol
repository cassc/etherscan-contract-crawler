// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error WithdrawFailed();
error InvalidQuantity();

contract NFTERC721A is ERC721A, Ownable{
    
    uint256 public price = 0.002 ether;
    uint256 public maxPerTransaction = 10;
    uint256 public constant supply = 999;

    string private _baseTokenURI;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    ) ERC721A(_name, _symbol) {
        _baseTokenURI = _baseUri;
    }

    function mint(uint256 quantity) external payable {
        require(msg.value >= price * quantity, "Transaction value did not equal the mint price");
        require(quantity <= maxPerTransaction, "The quantity could not bigger then 10");

        _safeMint(msg.sender, quantity);
    }

    function _startTokenId() internal view virtual override returns(uint256){
        return 1;
    }

    function _baseURI() internal view virtual override returns(string memory){
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function freeMint(uint256 qty, address recipient) external onlyOwner{
        require(_nextTokenId() + (qty - 1) < supply, "The NFT is soldout!");
        
        _safeMint(recipient, qty);
    }

    function setPerTransactionMax(uint256 _val) external onlyOwner {
        maxPerTransaction = _val;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        if (!success) revert WithdrawFailed();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        _withdraw(owner(), balance);
    }
}