//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GameCertificateToken is ERC721 {
    address public owner;
    uint256 public totalSupply;

    // for sell
    uint64 public startTime;
    uint64 public endTime;
    uint128 public price; // max: 3.4e38

    string internal baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC721(name_, symbol_) {
        owner = owner_;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    /* ---------------- sell ---------------- */

    /// @notice for sell
    function sell(uint256 amount_) public payable {
        require(
            block.timestamp < endTime && block.timestamp > startTime,
            "time missed"
        );
        require(msg.value >= price * amount_, "tx value is not correct");

        for (uint i = 0; i < amount_; i++) {
            _mint(_msgSender(), totalSupply);
        }
    }

    function setSellTime(uint64 startTime_, uint64 endTime_) public onlyOwner {
        startTime = startTime_;
        endTime = endTime_;
    }

    function setPrice(uint128 price_) public onlyOwner {
        price = price_;
    }

    function withdraw(address reciever) public onlyOwner {
        payable(reciever).transfer(address(this).balance);
    }

    /* ---------------- reveal ---------------- */

    function setBaseURI(string calldata baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0)) {
            totalSupply++;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
}