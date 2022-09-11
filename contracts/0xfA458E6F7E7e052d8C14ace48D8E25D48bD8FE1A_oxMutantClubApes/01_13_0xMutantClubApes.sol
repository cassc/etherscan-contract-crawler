//SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "erc721a/contracts/ERC721A.sol";


contract oxMutantClubApes is ERC721A, Ownable {

    string  public uriPrefix = "https://boredapeyachtclub.com/api/mutants/";

    uint256 public cost = 0.0025 ether; // FreeMint for first 2 minutes - after price 0.0025 wei 2500000000000000
    uint32 public immutable maxSupply = 30006;
    uint32 public immutable maxPerTx = 50;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier callerIsWhitelisted(uint256 amount, uint256 _signature) {
        require(uint256(uint160(msg.sender))+amount == _signature,"invalid signature");
        _;
    }

    constructor()
    ERC721A ("0xMutantClubApes", "0xMCA") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return uriPrefix;
    }

    function setUri(string memory uri) public onlyOwner {
        uriPrefix = uri;
    }
     
     function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;

  }

    

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function publicMint(uint256 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply, "sold out");
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