// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract SanadaWarriors is ERC721A, Ownable, ReentrancyGuard {

    uint256 public maxWarriors = 3000;
    uint256 public walletLimit = 6;
    uint256 public entryPrice = 1 ether;
    uint256 public maxPerTx = 3;
    
    string public baseURI;

    bool public saleLive;

    // Only the most loyal warriors will earn their blessing of Sanada.
    mapping (address => bool) public firstBorn; 

    constructor() 
    ERC721A("SanadaWarriors", "SW")  {}

    function mint(uint256 _amount) external payable {

        require(msg.sender == tx.origin);
        require(saleLive, "Recruiting has not commenced!");
        require(totalSupply() + _amount <= maxWarriors, "You are late young one.");
        require(msg.value == entryPrice * _amount, "To become a warrior, one must study the art of battle.");
        require(_amount <= maxPerTx, "Move too swiftly, you risk defeat.");
        require(_numberMinted(msg.sender) + _amount <= walletLimit, "Greed is not an acceptable trait of a warrior in Sanada.");

        _mint(msg.sender, _amount);
        firstBorn[msg.sender] = true;
    }

    function ownerMint(uint256 amount, address wallet) external onlyOwner {
        require(totalSupply() + amount <= maxWarriors);
        _mint(wallet, amount);
    }

    function toggleSale() external onlyOwner {
        saleLive = !saleLive;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        entryPrice = _price;
    }

    function setMaxPerTx(uint256 _amount) external onlyOwner {
        maxPerTx = _amount;
    }

    function setMaxWarrior(uint256 _newSupply) external onlyOwner {
        maxWarriors = _newSupply;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function isFirstBorn(address _address) view public returns (bool) {
        bool value = firstBorn[_address];
        return value;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}