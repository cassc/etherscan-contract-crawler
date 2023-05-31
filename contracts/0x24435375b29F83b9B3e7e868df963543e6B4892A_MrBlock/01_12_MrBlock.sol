// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MrBlock is ERC721A, Ownable {
    uint public constant MAX_PER_WALLET_FREE = 2;
    uint public constant MAX_PER_TX = 10;
    uint public MAX_SUPPLY = 8888;
    uint public price = 0.004 ether;
    string public baseURI = "ipfs://Qma7gXeqgKNuwK2qt9GT9CQYbnsgGvmK3hvWfCGht4ky3s/";
    string public constant baseExtension = ".json";

    bool public paused = false;
    bool public _live = false;

    constructor() ERC721A("MrBlock", "MRBLK") {}
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function goMint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "Paused");
        require(_live, "Not live!");
        require(MAX_SUPPLY >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No contracts");
        require(MAX_PER_TX >= _amount , "Excess max per paid tx");
        
        if(_numberMinted(msg.sender) >= MAX_PER_WALLET_FREE) {
            require(msg.value >= _amount * price, "Invalid funds provided");
        } else{
            uint count = _numberMinted(msg.sender) + _amount;
            if(count > MAX_PER_WALLET_FREE){
                require(msg.value >= (count - MAX_PER_WALLET_FREE) * price , "Insufficient funds");
            } 
        }
        _safeMint(_caller, _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    function initialize() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function live(bool _state) external onlyOwner {
        _live = _state;
    }

    function setCost(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
        ) : "";
    }
}