// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// 1 tx per wallet
// 3 max per tx
// Free Mint, No Royalties

contract Circles is ERC721A {
    using Strings for uint256;

    uint256 immutable MAX_SUPPLY = 333;
    string public ipfs = "QmVRZBQRDzP8iu2kzb2aT6QmCCdHZ4A5BpD7BmTmb1qYYD";
    address public owner;

    mapping(address => bool) public hasMinted;

    constructor() ERC721A("Circles", "circles") {
        owner = msg.sender;
        _mint(msg.sender, 1);
    }

    function mint(uint256 quantity) external payable {
        require(quantity + totalSupply() <= MAX_SUPPLY, "oos");
        require(quantity <= 3, "too many");
        require(!hasMinted[msg.sender], "alr minted");

        hasMinted[msg.sender] = true;
        _mint(msg.sender, quantity);
    }

    function setIpfs(string memory _ipfs) external onlyOwner {
        ipfs = _ipfs;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "ipfs://",
                    ipfs,
                    "/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}