// oooWiiaahhh wii invisble hehi ooh yea goblino ooh invisble

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract InvisibleGoblins is Ownable, ERC721A, ReentrancyGuard {

    uint256 public immutable MAX_POPULATION = 1111;

    uint256 public maxGoblinsPerGoblining = 1;

    bool public areGoblinsGoblining = false;

    string public baseURI;

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    modifier getYoGoblinsYea() {
        require(areGoblinsGoblining, "oKi, now fuck off.");
        _;
    }

    modifier goblinTownPopulation(uint256 amount) {
        require(totalSupply() + amount <= MAX_POPULATION, "xseeeds da goblin town population, shmuck.");
        _;
    }

    modifier checkSomethingIdk(uint256 amount) {
        require(amount <= maxGoblinsPerGoblining, "xseeds da limit ooh.");
        _;
    }

    function freeMint(uint256 amount)
        public
        nonReentrant
        getYoGoblinsYea
        goblinTownPopulation(amount)
        checkSomethingIdk(amount)
    {
        _safeMint(msg.sender, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function changeDaGobliningOrSum() external onlyOwner {
        areGoblinsGoblining = !areGoblinsGoblining;
    }

    function oohGimmeMoreMintOohYea(uint256 amount) external onlyOwner {
        maxGoblinsPerGoblining = amount;
    }

    function sumDaytaShit(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function gibFuckingMonies() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}