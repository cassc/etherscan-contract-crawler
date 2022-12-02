// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract UnsafeNFT is ERC721 {
    address public owner;
    uint256 public totalSupply;
    string public baseURI;

    constructor() ERC721("UnsafeNFT", "SNFT") {
        owner = msg.sender;
    }

    function mint() public {
        totalSupply++;
        _mint(msg.sender, totalSupply);
    }

    function setBaseURI(string calldata newURI) external {
        require(msg.sender == owner, "Not Owner");
        baseURI = newURI;
    }

    mapping(address => bool) public approvedOperators;

    // overriding the setApproval function means that held NFTs can't interact with marketplaces
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(
            approvedOperators[operator],
            "Sales will be enabled after mint out."
        );
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id, ".json"));
    }
}