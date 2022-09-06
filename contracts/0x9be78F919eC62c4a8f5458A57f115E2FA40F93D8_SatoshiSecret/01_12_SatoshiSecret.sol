// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SatoshiSecret is ERC721A, Ownable {
    uint public constant maxWalletFree = 2;
    uint public constant maxPerTrx = 10;
    uint public constant maxItem = 3000;
    uint public cost = 0.0025 ether;
    bool public _pause = false;
    bool public _mint = false;
    string public baseURI = "ipfs://QmeqbSuFVQ1PtD33rjRHejaourhumyUQizFmBvoKfV5TbH/";
    string public constant ext = ".json";

    constructor() ERC721A("Secret of Satoshi", "SOSAT") {}

    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }

    function howmuch() external view returns (uint256){
        return cost;
    }

    function mint(uint _amount) external payable {
        address _caller = _msgSender();
        require(!_pause, "Paused");
        require(_mint, "Not live!");
        require(maxItem >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0, "No 0 mints");
        require(tx.origin == _caller, "No bots");
        require(maxPerTrx >= _amount , "Excess max trx");
        
      if(_numberMinted(msg.sender) >= maxWalletFree){
            require(msg.value >= _amount * cost, "Insufficient funds");
        }else{
            uint count = _numberMinted(msg.sender) + _amount;
            if(count > maxWalletFree){
                require(msg.value >= (count - maxWalletFree) * cost , "Insufficient funds");
            }   
        }
        _safeMint(_caller, _amount);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed");
    }

    function first() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function pause(bool val) external onlyOwner {
        _pause = val;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function live(bool val) external onlyOwner {
        _mint = val;
    }

    function setCost(uint _amt) external onlyOwner {
        cost = _amt;
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Invalid id.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ext
            )
        ) : "";
    }
}