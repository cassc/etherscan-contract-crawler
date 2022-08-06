// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "openzeppelin/contracts/token/ERC721/ERC721.sol";

contract VipPass is ERC721 {
    string public uriPrefix =
        "ipfs://bafkreidsfibhp4qffcqbm7bl56q2wvz2c3xabg2ccdbj5lwxvvewjc33ki";
    uint256 public tokenId;
    uint256 public price = 0.04 ether;
    uint256 public maxSupply = 10;
    bool paused;
    address owner;

    constructor() ERC721("LOLVIPPASS", "VIP") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT OWNER");
        _;
    }

    function mint() public payable {
        require(!paused, "Minting paused");
        require(msg.sender == tx.origin, "NOT EOA");
        require(tokenId < maxSupply, "MAX_SUPPLY_EXCEEDED");
        require(msg.value >= price, "INSUFFICIENT_FUND");
        _mint(msg.sender, tokenId);
        ++tokenId;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return uriPrefix;
    }

    // onlyOwner Functions

    function totalSupply() public view returns (uint256) {
        return tokenId;
    }

    function updateMaxSupply(uint256 _newSupply) public onlyOwner {
        require(totalSupply() < _newSupply, "WRONG SUPPLY");
        maxSupply = _newSupply;
    }

    function setPause(bool _pause) public onlyOwner {
        paused = _pause;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function updateMintingprice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function withdraw() public onlyOwner {
        (bool hs, ) = payable(owner).call{value: address(this).balance}("");
        require(hs, "WITHDRAW_ERROR");
    }
}