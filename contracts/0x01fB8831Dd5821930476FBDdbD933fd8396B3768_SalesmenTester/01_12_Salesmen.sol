// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SalesmenTester is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 5555;
    uint256 public MAX_MINTS = 2;
    uint256 public TEAM_RESERVED = 555;
    string public projName = "Salesmen";
    string public projSym = "SAL";
    bool public claimedReserved = false;

    bool public DROP_ACTIVE = false;
    string public uriPrefix = "";

    mapping(address => bool) public buyers;

    constructor() ERC721A(projName, projSym) {}

    function mint() public {
        require(msg.sender == tx.origin, "not allowed bots");
        require(DROP_ACTIVE, "Sale not started");
        require(totalSupply() + MAX_MINTS < MAX_SUPPLY, "Sold out");
        require(!buyers[msg.sender], "Already bought");
        buyers[msg.sender] = true;
        _safeMint(msg.sender, MAX_MINTS);
    }

    function mintReserved() external onlyOwner {
        require(!claimedReserved, "already claimed reserved");
        _safeMint(msg.sender, TEAM_RESERVED);
    }

    function flipDropState() public onlyOwner {
        DROP_ACTIVE = !DROP_ACTIVE;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId)));
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setMaxMints(uint256 newMax) public onlyOwner {
        MAX_MINTS = newMax;
    }

    function setSupply(uint256 newSupply) public onlyOwner {
        MAX_SUPPLY = newSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        Address.sendValue(payable(owner()), balance);
    }

    fallback() external payable {}

    receive() external payable {}
}