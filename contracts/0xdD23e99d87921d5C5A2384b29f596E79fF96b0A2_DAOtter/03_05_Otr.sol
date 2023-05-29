// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAOtter is ERC721A, Ownable {
    string public baseURI =
        "ipfs://QmPxA6646ELdhKXjpTDRVSpxNc4obaTAiYaNkYvhpciSzN/";

    uint256 public singleMintPrice = 0.005 ether;
    uint256 public fiveMintPrice = 0.02 ether;
    uint256 public tenMintPrice = 0.038 ether;
    uint32 public maxMintsPerAddress = 20;
    uint32 public immutable maxSupply = 10000;

    mapping(address => uint32) public totalMintsByAddress;
    mapping(address => bool) public freeMintUsed;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor() ERC721A("DAOtter", "OTR") {}

    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    function mint(uint32 amount) public payable callerIsUser {
        require(totalSupply() + amount <= maxSupply, "sold out");
        require(
            totalMintsByAddress[msg.sender] + amount <= maxMintsPerAddress,
            "Exceed max mints per address"
        );

        uint256 cost;

        if (amount == 1) {
            if (!freeMintUsed[msg.sender]) {
                cost = 0;
                freeMintUsed[msg.sender] = true;
            } else {
                cost = singleMintPrice;
            }
        } else if (amount == 5) {
            cost = fiveMintPrice;
        } else if (amount == 10) {
            cost = tenMintPrice;
        } else {
            revert("Invalid amount to mint");
        }

        require(msg.value >= cost, "insufficient");

        _safeMint(msg.sender, amount);
        totalMintsByAddress[msg.sender] += amount;
    }

    function mintForAdmin(uint32 amount) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "sold out");
        _safeMint(msg.sender, amount);
    }

    function setPrice(
        uint256 single,
        uint256 five,
        uint256 ten
    ) public onlyOwner {
        singleMintPrice = single;
        fiveMintPrice = five;
        tenMintPrice = ten;
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}