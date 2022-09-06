// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PunkApesWTF is ERC721AQueryable, Ownable, Pausable {
    using Strings for uint;

    error NotEnoughSupply();
    error QueryForNonexistentToken();

    string baseURI;
    string contractURI;

    uint256 public maxSupply = 250_001;
    uint256 public price = 0.001 ether;
    
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_
    ) ERC721A(name_, symbol_) {
        baseURI = baseURI_;
        contractURI = contractURI_;
        pause();
    }

    receive() external payable {
        publicMint(msg.sender, msg.value / price);
    }

    function mintTo(address to, uint256 quantity) public payable onlyOwner {
        _mintTo(to, quantity);
    }

    function publicMint(address to, uint256 quantity) internal whenNotPaused {
        _mintTo(to, quantity);
    }

    function _mintTo(address to, uint256 quantity) internal {
        if (_totalMinted() + quantity > maxSupply) revert NotEnoughSupply();
        _mint(to, quantity);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert QueryForNonexistentToken();

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /**
     * Pause Minting
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * Unpause Minting
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        contractURI = uri;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}