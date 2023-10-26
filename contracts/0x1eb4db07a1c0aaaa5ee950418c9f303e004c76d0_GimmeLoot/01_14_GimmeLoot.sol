/**
 *Submitted for verification at Etherscan.io on 2021-08-27
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GimmeLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public constant MAX_SUPPLY = 6666;
    uint256 private constant MAX_MINTS = 10;
    uint256 private constant MAX_PER_TX = 10;
    uint256 public reservedLoot = 100;
    uint256 public price = 10000000000000000; //0.01 ETH

    // Collection metatdata URI
    string private _baseURIExtended;

    mapping(address => uint256) private addressToMintCount;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function mint(uint256 amount) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(amount <= MAX_PER_TX, "Exceeds max mint per transaction!");
        require(
            addressToMintCount[msg.sender] + amount <= MAX_MINTS,
            "Exceeded wallet mint limit!"
        );
        require(
            supply + amount <= MAX_SUPPLY - reservedLoot,
            "Exceeds max supply!"
        );
        require(msg.value >= price * amount, "Invalid Eth value sent!");

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        addressToMintCount[msg.sender] += amount;
    }

    function reserveTeamTokens(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        require(_reserveAmount <= reservedLoot, "Not enough reserves");

        uint256 supply = totalSupply();

        for (uint256 i = 1; i <= _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        reservedLoot = reservedLoot - _reserveAmount;
    }

    function withdraw() public onlyOwner {
        address recipient1 = 0x53DB9542E3A0cdBFEBB659d001799ba0b37B2275;
        address recipient2 = 0x54c0E8300162561f60947f6F6e002a21DaD8165a;

        // Withdraw 20% of the tokens
        payable(recipient1).transfer((address(this).balance * 20) / 100);
        // Withdraw the rest of the tokens
        payable(recipient2).transfer(address(this).balance);
    }

    constructor(string memory metadataBaseURI)
        ERC721("Gimme (the Loot)", "GIMME")
    {
        _baseURIExtended = metadataBaseURI;
    }
}