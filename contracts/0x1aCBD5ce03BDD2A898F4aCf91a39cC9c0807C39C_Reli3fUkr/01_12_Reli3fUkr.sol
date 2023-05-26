// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Reli3fUkr is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool public isActive = false;

    string public _uri = "https://smilesssvrs.mypinata.cloud/ipfs/Qmf9CH9xbCZsnd9idtUqwZYo6NujogjYCTVboW6itoG6ew/";
    uint256 public artworks = 37;
    uint256 public editions = 200;
    uint256 public supply = artworks * editions;
    

    uint256 public maxPerTransaction = 2;

    uint256 public price = 0.05 ether;

    uint256 private counter = 0;
    uint256 public minted = 0;
    
    constructor() ERC1155(_uri) {}

    function mint(uint256 _amount)
        public
        payable
        nonReentrant
    {   
        require(isActive, "Minting is closed");
        require(minted < supply, "Sold out");
        require(msg.sender == tx.origin, "You cannot mint from a smart contract");
        require(msg.value >= price * _amount, "Not enough eth");
        require(_amount > 0 && _amount <= maxPerTransaction, "The amount must be between 1 and 2");
        require(_amount + minted <= supply, "Not enough NFTs");
        
        minted += _amount;

        for (uint i = 0; i < _amount; i++){
            uint256 tokenId = (counter % artworks) + 1;
            _mint(msg.sender, tokenId, 1, "");
            counter ++;
        }
    }

    // Getters
    function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
        return string(abi.encodePacked(_uri, _id.toString()));
    }

    // Setters
    function toggleActive() external onlyOwner {
        isActive = !isActive;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        _uri = newuri;
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