// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Strings.sol";

contract TheEuropeans is ERC721A {
    uint256 public mint_status;

    uint256 public MAX_SUPPLY;
    uint256 public TEAM_SUPPLY = 300;
    uint256 public FREE_SUPPLY = 5000;

    address public owner;
    string private baseURI;

    uint256 public public_price;

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {
        owner = msg.sender;
        setMintStatus(0);
        setMintMaxSupply(10000);
        setMintPublicPrice(700000000000000);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setMintStatus(uint256 _status) public onlyOwner {
        mint_status = _status;
    }

    function setMintMaxSupply(uint256 _max_supply) public onlyOwner {
        MAX_SUPPLY = _max_supply;
    }

    function setMintFreeSupply(uint256 _free_supply) public onlyOwner {
        FREE_SUPPLY = _free_supply;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setMintPublicPrice(uint256 _price) public onlyOwner {
        public_price = _price;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function getPrice(uint256 amount) public view returns (uint256) {
        if (totalSupply() <= FREE_SUPPLY) {
            return 0;
        }
        return amount * public_price;
    }

    function mint(uint256 amount) external payable {
        require(mint_status == 1, "Mint has not started yet.");
        require(amount <= 3, "The maximum amount of NFT per Tx is 3");
        require(
            totalSupply() + amount <= MAX_SUPPLY - TEAM_SUPPLY,
            "This will exceed the total supply."
        );
        require(msg.value >= getPrice(amount), "Not enought ETH sent");
        _safeMint(msg.sender, amount);
    }

    function giveaway(address[] calldata _to, uint256 amount)
        external
        onlyOwner
    {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "This will exceed the total supply."
        );
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], amount);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
}