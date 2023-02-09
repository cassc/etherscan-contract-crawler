//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GameCertificateTokenAdventure is ERC721 {
    address public owner;
    uint256 public totalSupply;

    // for sell
    uint256 public startTime;
    mapping(address => uint256) public mintTimeLimit;

    string internal baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC721(name_, symbol_) {
        owner = owner_;
        startTime = block.timestamp;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    /* ---------------- sell ---------------- */

    /// @notice Each address can only mint once a month(30 days)
    function mint() public {
        if (mintTimeLimit[_msgSender()] == 0) {
            _mint(_msgSender(), totalSupply);
        } else {
            require(
                block.timestamp > mintTimeLimit[_msgSender()],
                "ERROR: can only mint once a month"
            );
            _mint(_msgSender(), totalSupply);
        }
        uint256 month = 4 weeks + 2 days;
        mintTimeLimit[_msgSender()] =
            startTime +
            ((block.timestamp - startTime) / month + 1) *
            month;
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