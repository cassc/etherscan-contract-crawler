// SPDX-License-Identifier: GPL-3.0
/*
    PUNK SKULL - X NFT | CC0
*/

pragma solidity 0.8.7;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "./ERC721A/contracts/ERC721A.sol";

contract PUNKSKULL is ERC721A {
    uint256 public immutable maxSupply = 380;
    uint256 _price = 0.0038 ether;
    uint256 _maxPerTx = 5;
    address public owner;
    uint256 _maxFree;

    function publicmint(uint256 amount) payable public {
        require(totalSupply() + amount <= maxSupply, "Sold Out");
        require(amount <= _maxPerTx);
        uint256 cost = amount * _price;
        require(msg.value >= cost, "Pay For");
        _safeMint(msg.sender, amount);
    }

    function premint() public {
        require(msg.sender == tx.origin, "EOA");
        require(totalSupply() + 1 <= _maxFree, "No Free");
        require(balanceOf(msg.sender) == 0, "Only One");
        _safeMint(msg.sender, 1);
    }
    
    modifier onlyOwner {
        require(owner == msg.sender, "No Permission");
        _;
    }

    constructor() ERC721A("PUNK SKULL-X", "PSX") {
        owner = msg.sender;
        _price = 0.0038 ether;
        _maxFree = 140;
    }

    function changePrice(uint256 mprice) external onlyOwner {
        _price = mprice;
    }

    function changeMaxFree(uint256 mfree) external onlyOwner {
        _maxFree = mfree;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://QmYTwxWwj1dcHqrRVrSizXLGyW1BDQWqzb7Ku1girSrVSa/", _toString(tokenId), ".json"));
    }
    
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}