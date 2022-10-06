// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract Infernals is ERC721A, Ownable {

    string  public uriPrefix = "ipfs://QmfRZJGZcQs5KR445eBGzWk7h8g9nTe1xwSLRsWGRz6MHZ/";

    uint256 public immutable mintPrice = 0.001 ether;
    uint32 public immutable maxSupply = 5000;
    uint32 public immutable maxPerTx = 10;

    mapping(address => bool) freeMintMapping;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("The Infernals", "INFERNAL") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return uriPrefix;
    }

    function setUri(string memory uri) public onlyOwner {
        uriPrefix = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function spawnInfernal(uint256 amount) public payable callerIsUser{
        uint256 mintAmount = amount;

        if (!freeMintMapping[msg.sender]) {
            freeMintMapping[msg.sender] = true;
            mintAmount--;
        }
        require(msg.value > 0 || mintAmount == 0, "Insufficient balance");

        if (totalSupply() + amount <= maxSupply) {
            require(totalSupply() + amount <= maxSupply, "Sold Out");


             if (msg.value >= mintPrice * mintAmount) {
                _safeMint(msg.sender, amount);
            }
        }
    }

    function infernalRise(address _to, uint256 numberOfSpawns) external onlyOwner {
      uint256 infernalPopulation = totalSupply();
      require(infernalPopulation + numberOfSpawns <= maxSupply, "INFERNAL OVERLOAD");
      _safeMint(_to, numberOfSpawns);
    }

    function withdraw() public onlyOwner {
      (bool os, ) = payable(owner()).call{value: address(this).balance}('');
      require(os);
    }

}