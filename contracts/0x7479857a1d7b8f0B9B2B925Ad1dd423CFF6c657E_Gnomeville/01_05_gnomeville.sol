// SPDX-License-Identifier: MIT
// Sponsored by Gnomeshire Hathaway

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract Gnomeville is ERC721A, Ownable {
    uint256 public constant maxSupply = 8888;
    string public baseURI = "ipfs://GNOMETA/";
    string public contractURI = "ipfs://QmSVUYPWQKa4VH2ZPHwtush8tYjnxNgxqK1JgbK93rxxnk";
    bool public gnomingActive = false;
    bool public canRug = true;

    mapping(address => uint256) public antiGoblinCounter;

    constructor() ERC721A("Gnomeville", "GNOME") {}

    modifier callerIsNotGoblin() {
        require(tx.origin == _msgSender(), "Caller is from Chinese alpha group.");
        _;
    }

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function shutOffGnoming() external onlyOwner {
        gnomingActive = false;
    }

    function turnOnGnoming() external onlyOwner {
        gnomingActive = true;
    }

    function setBaseURI(string memory _updatedURI) public onlyOwner {
        require(canRug, "Rug is not allowed.");
        baseURI = _updatedURI;
        canRug = false;
    }

    function setContractURI(string memory _updatedURI) public onlyOwner {
        // Gnot checking for anti-rug. Gno one cares about this.
        contractURI = _updatedURI;
    }

    function publicMint() public callerIsNotGoblin {
        require(gnomingActive, "Gnoming is not active you fucking genius.");
        require(antiGoblinCounter[_msgSender()] == 0, "You have already claimed you greedy Fucker.");
        uint256 totalSupply = totalSupply();
        require(
            totalSupply < maxSupply,
            "Gone. Out of Gnomes. You are a fucking goblin."
        );
        _safeMint(_msgSender(), 2);
        antiGoblinCounter[_msgSender()]++;
    }
}