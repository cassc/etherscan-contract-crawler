// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract UnisnapNFT is ERC721("Unisnap", "SNAP"), Owned(msg.sender) {
    error InsufficientFee();
    error WithdrawFailed();

    uint256 public totalSupply;
    uint256 public mintFee = 0.001 ether;
    string public baseURI = "https://unisnap.xyz/token/";

    function mint() external payable {
        if (msg.value < mintFee) revert InsufficientFee();
        _mint(msg.sender, totalSupply);
        totalSupply++;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }

    function withdraw(address recipient) external onlyOwner {
        (bool success, ) = recipient.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
        require(success, "UnisnapNFT: withdraw failed");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string.concat(baseURI, Strings.toString(tokenId));
    }
}