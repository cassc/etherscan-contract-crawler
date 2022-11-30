// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GlieseZombiesPFP is ERC721, Pausable, Ownable {
    string private baseURI =
        "https://gateway.pinata.cloud/ipfs/bafybeidkteto6ad63xmnbbci3pj375h266enhpqq7jryqxdqemjntlggwu/";

    uint256 public constant maxSupply = 3333;
    uint256 public totalSupply = 0;
    uint256 public price = 0.01 ether;

    // TODO before deploying set developer address
    address public developer = 0xC21d08431f5848352fA6F4B4374dc49d256D048D;

    uint256 public developerCut = 50; // percentage

    constructor() ERC721("GlieseZombiesPFPs", "GZP") {
        pause();
    }

    function pause() public onlyOwnerOrDeveloper {
        _pause();
    }

    function unpause() public onlyOwnerOrDeveloper {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwnerOrDeveloper {
        baseURI = baseURI_;
    }

    function setDeveloper(address _developer) public onlyDeveloper {
        require(_developer != address(0), "Inalid address");

        developer = _developer;
    }

    function setDeveloperCut(uint256 _developerCut) public onlyDeveloper {
        require(_developerCut <= 50, "Inalid value");

        developerCut = _developerCut;
    }

    function setPrice(uint256 _price) public onlyOwnerOrDeveloper {
        price = _price;
    }

    function mint() public payable {
        require(totalSupply < maxSupply, "All NFTs are minted.");

        require(!_exists(totalSupply), "Token already minted");
        require(price <= msg.value, "Invalid value");

        _safeMint(msg.sender, totalSupply);
        totalSupply++;
    }

    function mintAmount(uint256 amount) public onlyDeveloper {
        require(totalSupply < maxSupply, "All NFTs are minted.");

        while (totalSupply < maxSupply && amount > 0) {
            _safeMint(msg.sender, totalSupply);
            totalSupply++;

            amount--;
        }
    }

    function withdraw() public onlyOwnerOrDeveloper {
        uint256 balance = address(this).balance;
        payable(developer).transfer((balance / 100) * developerCut);
        payable(owner()).transfer(address(this).balance);
    }

    modifier onlyOwnerOrDeveloper() {
        require(
            msg.sender == developer || msg.sender == owner(),
            "Inalid sender"
        );
        _;
    }

    modifier onlyDeveloper() {
        require(msg.sender == developer, "Inalid sender");
        _;
    }
}