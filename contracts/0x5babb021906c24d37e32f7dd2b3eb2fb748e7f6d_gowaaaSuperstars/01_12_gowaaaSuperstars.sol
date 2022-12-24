// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC-721 Token
 * @dev Implementation of the ERC-721 Token standard.
 */
contract gowaaaSuperstars is ERC721, Ownable {
    address payable public withdrawWallet;
    uint256 public totalSupply;
    string internal baseTokenUri;

    constructor() payable ERC721("gowaaaSuperstars", "GS") {
        withdrawWallet = payable(0x9D4Ebe2ec409ec13207B52584069d5eaF254E36d);
    }

    function mintBatch(address[] memory toAddresses) public payable onlyOwner {
        for (uint256 i = 0; i < toAddresses.length; i++) {
            totalSupply++;
            address toAddress = toAddresses[i];
            _safeMint(toAddress, totalSupply);
        }
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "Token does not exist");
        return
            string(
                abi.encodePacked(
                    baseTokenUri,
                    Strings.toString(tokenId_),
                    ".json"
                )
            );
    }

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw fail");
    }
}