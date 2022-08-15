// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract CyberBirds is ERC721A, Ownable {


    string  public uriPrefix = "ipfs://bafybeid6xe6wmxvwudl3i75bhuffu5xgzs4mamk3lifuzrdllydngiaj7i/";

    uint256 public immutable cost = 0.005 ether;
    uint32 public immutable maxSUPPLY = 666;
    uint32 public immutable maxPerTx = 3;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("CyberBirds", "CyberBird") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return uriPrefix;
    }

    function setUri(string memory uri) public onlyOwner {
        uriPrefix = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function publicMint(uint256 amount) public payable callerIsUser{
        require(amount <= maxSUPPLY, "sold out");
        require(amount <=  maxPerTx, "invalid amount");
        require(msg.value >= cost * amount,"insufficient");
        _safeMint(msg.sender, amount);
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}