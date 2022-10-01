// SPDX-License-Identifier: GPL-3.0
/*
 * Bored Duck Bit Club
 */                                                                                                

pragma solidity >=0.7.0 <0.9.0;
import "./ERC721A.sol";

contract BoredDuckBitClub is ERC721A {
    address owner;
    uint256 maxPerTx = 20;
    uint256 public cost = 0.001 ether;
    uint256 public maxSupply = 4444; // max supply
    mapping(address => uint256) public addrMinted;
    
    modifier onlyOwner {
        require(owner == msg.sender, "No Permission");
        _;
    }

    modifier verify(uint256 amount) {
        uint256 need;
        if (addrMinted[msg.sender] > 0) {
            need = amount * cost;
        } else {
            need = (amount - 1) * cost;
        }
        require(msg.value >= need, "No enough ether");
        _;
    }

    constructor() ERC721A("Bored Duck Bit Club", "BDBC") {
        owner = msg.sender;
        _mint(msg.sender, 20);
    }

    function mint(uint256 amount) payable public verify(amount) {
        require(totalSupply() + amount <= maxSupply, "SoldOut");
        require(amount <= maxPerTx, "MaxPerTx");
        addrMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked("ipfs://QmTyXe6Uf9gPRrSEk85K9yFMXApc3CxV19UXs4vsWx2LuV/", _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

