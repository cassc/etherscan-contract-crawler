//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./MintPermit.sol";

contract GoodByCatz is ERC721, Ownable, MintPermit {
    event TokenMinted(
        uint256 userId,
        address indexed recipient,
        uint256 tokenId
    );

    string private baseURI;

    constructor(
        address owner,
        address mintPermitSigningWallet,
        string memory uri
    ) ERC721("GoodBye Catz", "GBC") MintPermit(mintPermitSigningWallet) {
        transferOwnership(owner);
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function mint(MintPermitStruct memory mintPermit, bytes calldata signature)
        public
        payable
        requiresMintPermit(mintPermit, signature)
    {
        require(mintPermit.tokenId < 3001, "Token does not exist");
        require(msg.value >= mintPermit.price, "Insufficient funding");

        _mint(mintPermit.recipient, mintPermit.tokenId);
        emit TokenMinted(
            mintPermit.userId,
            mintPermit.recipient,
            mintPermit.tokenId
        );
    }

    function mintAdmin(address to, uint16 token) public onlyOwner {
        require(token < 3001, "Token does not exist");
        _mint(to, token);
        emit TokenMinted(0, to, token);
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "There is no value to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");

        require(success, "Withdrawal Failed!");
    }

    function totalSupply() public pure returns (uint256) {
        return 3000;
    }
}