// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TiffApes is Ownable, ERC721 {
    uint256 constant public AMOUNT = 5556;
    uint256 public price = 0 ether;
    uint256 public minted = 1;
    string public baseTokenURI = "https://bafybeibkbtd6wairlavkur74v5y4vreocqisfdmc6t223gc5v6oqahsjeq.ipfs.nftstorage.link/";
    string private _contractURI = "https://tiffapes.xyz/metadata.json";

    constructor()
        ERC721("TiffApes", "TAPES")
    {
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function totalSupply() public view returns (uint256) {
        return minted - 1;
    }

    function mint(uint256 amount) external payable {
        uint256 _totalSupply = minted;
        require(msg.sender == tx.origin);
        require(
            _totalSupply + amount - 1 < AMOUNT,
            "no more tokens"
        );
        require(amount > 0, "too less");
        uint256 _balance = balanceOf(msg.sender);
        uint256 freeAmount = _balance < 2 ? 2 - _balance : 0;
        require(msg.value >= (amount - freeAmount) * price, "wrong price");
        _mintMany(msg.sender, amount);
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function _mintMany(address to, uint256 amount) internal virtual {
        uint256 _totalSupply = minted;
        for (uint256 i; i < amount; i++) {
            _mint(to, _totalSupply);
            _totalSupply++;
        }
        minted = _totalSupply;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}