// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IERC721 {
    function mint(address to) external virtual;

    function totalSupply() external view virtual returns (uint);

    function ownerOf(uint tokenId) external view virtual returns (address);
}

contract ERC721MinterSimpleLimited is Ownable {
    IERC721 public erc721;

    //used to verify whitelist user
    uint public maxSupply;
    uint public mintQuantity;
    bool public publicMintStart;
    uint public price;
    address public devPayoutAddress;
    mapping(address => uint) public claimed;

    constructor(IERC721 erc721_, uint price_, uint mintQuantity_, uint _maxSupply) {
        erc721 = erc721_;
        mintQuantity = mintQuantity_;
        price = price_;
        maxSupply = _maxSupply;
        devPayoutAddress = address(0xc891a8B00b0Ea012eD2B56767896CCf83C4A61DD);
        publicMintStart = false;
    }

    function setNFT(IERC721 erc721_) public onlyOwner {
        erc721 = erc721_;
    }

    function setQuantity(uint newQ_) public onlyOwner {
        mintQuantity = newQ_;
    }

    function setPublicMintStart(bool _isStarted) public onlyOwner {
        publicMintStart = _isStarted;
    }

    function setMaxSupply(uint newQ_) public onlyOwner {
        maxSupply = newQ_;
    }

    function setPrice(uint newPrice_) public onlyOwner {
        price = newPrice_;
    }

    function mintPublic(uint quantity_) public payable {
        require(publicMintStart, "mint not started");
        uint supply = erc721.totalSupply();
        //require payment
        require(supply + quantity_ <= maxSupply, "No more left");

        require(msg.value >= price * quantity_, "Insufficient funds provided.");

        //check mint quantity
        require(claimed[msg.sender] + quantity_ <= mintQuantity, "Already claimed.");

        //increase quantity that user has claimed
        claimed[msg.sender] = claimed[msg.sender] + quantity_;

        //mint quantity times
        for (uint i = 0; i < quantity_; i++) {
            erc721.mint(msg.sender);
        }
    }

    function withdraw(address to) public onlyOwner {
        uint devAmount = (address(this).balance * 50) / 1000;
        bool success;
        (success, ) = devPayoutAddress.call{value: devAmount}("");
        require(success, "dev withdraw failed");
        (success, ) = to.call{value: address(this).balance}("");
        require(success, "withdraw failed");
    }
}