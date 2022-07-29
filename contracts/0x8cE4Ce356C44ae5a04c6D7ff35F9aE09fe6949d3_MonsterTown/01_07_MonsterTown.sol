// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MonsterTown is Ownable, ERC721A {

    uint256 public constant MAX_SUPPLY = 6000;
    uint256 public maxAmount = 5;
    string public _tokenBaseURI = 'ipfs://bafybeib6hidaupmjcfrzpihdlrd3alptssd5ywqqmacdwt7p4e2uea6cjq/';
    bool public resumeMint = false;

    constructor() ERC721A ("MonsterTown.wtf","MONT") {}

    function mint(uint256 quantity) external payable {
        require(totalSupply() < MAX_SUPPLY, "Sold Out");
        require(resumeMint, "Mint OFF");
        require(quantity > 0, "mint should be > 1");
        require(quantity <= maxAmount, "Quantity should be < 5");
        require( getPrice() * quantity == msg.value, "Incorrect TX value");
        require( totalSupply() + quantity <= MAX_SUPPLY, "Exceeds Supply");
        _safeMint(msg.sender, quantity);
    }

    function getPrice() internal view virtual returns (uint256){
        return totalSupply() > 2000 ? 0.005 ether : 0.0 ether;
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        require( totalSupply() < MAX_SUPPLY, "Sold Out");
        require( totalSupply() + quantity <= MAX_SUPPLY, "Exceeds Supply");
        _safeMint(msg.sender, quantity);
    }
    
    function setResumeMint() external onlyOwner {
        resumeMint = !resumeMint;
    }
    

    function setMaxAmount(uint256 _maxAmount) external onlyOwner {
        maxAmount = _maxAmount;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return _tokenBaseURI;
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Tx Failed");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Balance");
        _withdraw(owner(), address(this).balance);
    }
}