// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Reli3fUkr2 is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bool public isActive = false;
    uint256 public endTime = 0;
    uint256 public saleDuration = 15 minutes;

    uint256 public price = 0.05 ether;
    uint256 public artworks = 25;
    uint256 public maxPerTransaction = 2;

    string private _uri = "ipfs://QmcixBeDqgb4n28p22hJdcUhSoTYsCeEC5XMfsUUTwwhsn/"; 
    string private suffix = ".json";

    Counters.Counter private _counter;
    
    constructor() ERC1155(_uri) {}

    function mint(uint256 _amount)
        public
        payable
        nonReentrant
    {   
        require(isActive, "Minting is closed");
        require(block.timestamp < endTime, "Sold out");
        require(msg.sender == tx.origin, "You cannot mint from a smart contract");
        require(msg.value >= price * _amount, "Not enough eth");
        require(_amount > 0 && _amount <= maxPerTransaction, "The amount must be between 1 and 2");
        
        for (uint i = 0; i < _amount; ++i){
            uint256 tokenId = (_counter.current() % artworks) + 1;
            _counter.increment();
            _mint(msg.sender, tokenId, 1, "");  
        }
    }

    // Getters
    function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
        return string(abi.encodePacked(super.uri(_id), _id.toString(), suffix));
    }

    function totalSupply() public view returns (uint256) {
        return _counter.current();
    }

    // Setters
    function toggleActive() external onlyOwner {
        isActive = !isActive;
        endTime = block.timestamp + saleDuration;
    }

    function setURI(string memory newuri, string memory _suffix) public onlyOwner {
        _setURI(newuri);
        suffix = _suffix;
    }

    // Withdraw
    function withdraw(address payable withdrawAddress)
        external
        payable
        nonReentrant
        onlyOwner
    {
        require(withdrawAddress != address(0), "Withdraw address cannot be zero");
        require(address(this).balance >= 0, "Not enough eth");
        payable(withdrawAddress).transfer(address(this).balance);
    }
}