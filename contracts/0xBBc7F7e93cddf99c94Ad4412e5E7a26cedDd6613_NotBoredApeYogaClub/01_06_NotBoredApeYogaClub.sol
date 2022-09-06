//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NotBoredApeYogaClub is ERC721A, Ownable, Pausable{
    // Mint constants
    uint256 public MAX_SUPPLY = 10000;
    uint256 public MAX_PER_TXN = 10;
    uint256 public MAX_PER_WALLET = 10;
    uint256 public TEAM_RESERVED = 1000;
    uint256 public TEAM_MINTED = 0;

    string public _uriPart;

    constructor() ERC721A("NotBoredApeYogaClub", "NBAYC") {
        _pause();
    }

    function mint(uint256 quantity) external whenNotPaused{
        require(_totalMinted() + quantity <= MAX_SUPPLY - TEAM_RESERVED, "no more available");
        require(_numberMinted(msg.sender) + quantity <= MAX_PER_WALLET, "max per wallet passed");
        require(msg.sender == tx.origin, "no contracts please");
        require(quantity <= MAX_PER_TXN, "max per txn passed");
        require(quantity > 0, "larger than zero quantity please");

        _safeMint(msg.sender, quantity);
    }

    function teamMint(uint256 quantity, address mintTo) external onlyOwner{
        require(TEAM_MINTED + quantity < MAX_SUPPLY, "surpassed team limit");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "minting too many");
        require(quantity > 0, "larger than zero quantity please");
        TEAM_MINTED += quantity;
        _safeMint(mintTo, quantity);
    }

    function setURIPart(string memory part) external onlyOwner {
        _uriPart = part;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _uriPart;
    }

    function flipState() external onlyOwner {
        if(paused()){
            _unpause();
        }else{
            _pause();
        }
    }
}