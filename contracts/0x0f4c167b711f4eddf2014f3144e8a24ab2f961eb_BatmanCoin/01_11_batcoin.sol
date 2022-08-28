pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BatmanCoin is Ownable, ERC721 {

    bool public isOpen;
    uint256 public cost = 0.002 ether;
    uint256 public totalSupply = 10000000000;

    constructor() ERC721("Ring ding ding daa baa Baa aramba baa bom baa barooumba Wh-wha-what's going on-on? Ding, ding This is the Crazy Frog Ding, ding Bem, bem! Ring ding ding ding ding ding Ring ding ding ding bem bem bem Ring ding ding ding ding ding Ring ding ding ding baa baa Ring ding ding ding ding ding Ring ding ding ding bem bem bem Ring ding ding ding ding ding This is the Crazy Frog Breakdown! Ding, ding Br-br-break it, br-break it Dum dum dumda dum dum dum Dum dum dumda dum dum dum Dum dum dumda dum dum dum Bem, bem! Dum dum dumda dum dum dum Dum dum dumda dum dum dum Dum dum dumda dum dum dum This is the Crazy Frog A ram me ma bra ba bra bra rim bran Dran drra ma mababa baabeeeaaaaaaa! Ding, ding This is the Crazy Frog Ding, ding Da, da Ring ding ding ding ding ding Ring ding ding ding bem bem bem Ring ding ding ding ding ding Ring ding ding ding baa baa Ring ding ding ding ding ding Ring ding ding ding bem bem bem Ring ding ding ding ding ding This is the Crazy Frog Ding, ding Br-br-break it, br-break it Dum dum dumda dum dum dum Dum dum dumda dum dum dum Dum dum dumda dum dum dum Bem, bem! Dum dum dumda dum dum dum Dum dum dumda dum dum dum Dum dum dumda dum dum dum This is the Crazy Frog Bem, bem!", "BatcoiRing ding ding daa baa Baa aramba baa bom baa barooumba Wh-wha-what's going on-on? Ding, ding This is the Crazy Frog Ding, ding Bem, bem! Ring ding ding ding ding ding Ring ding ding ding bem bem bem Ring ding ding ding ding ding Ring ding ding ding baa baa Ring ding ding ding ding ding Ring ding ding ding bem bem bem Ring ding ding ding ding ding This is the Crazy Frog Breakdown! Ding, ding Br-br-break it, br-break it Dum dum dumda dum dum dum Dum dum dumda dum dum dum Dum dum dumda dum dum dum Bem, bem! Dum dum dumda dum dum dum Dum dum dumda dum dum dum Dum dum dumda dum dum dum This is the Crazy Frog A ram me ma bra ba bra bra rim bran Dran drra ma mababa baabeeeaaaaaaa! Ding, ding This is the Crazy Frog Ding, ding Da, da Ring ding ding ding ding ding Ring ding ding ding bem bem bem Ring ding ding ding ding ding Ring ding ding ding baa baa Ring ding ding ding ding ding Ring ding ding ding bem bem bem Ring ding ding ding ding ding This is the Crazy Frog Ding, ding Br-br-break it, br-break it Dum dum dumda dum dum dum Dum dum dumda dum dum dum Dum dum dumda dum dum dum Bem, bem! Dum dum dumda dum dum dum Dum dum dumda dum dum dum Dum dum dumda dum dum dum This is the Crazy Frog Bem, bem!n") {}

    modifier open() {
        require(isOpen, "open");
        _;
    }

    function flipOpen() external onlyOwner {
        isOpen = true;
    }

    function flipClose() external onlyOwner {
        isOpen = false;
    }

    function spawnbatman(uint256 quantity) external payable open {
        require(quantity * cost == msg.value, "wrong value");
        for(uint256 i = 0; i < quantity;) {
            _safeMint(msg.sender, totalSupply++);
            unchecked { i++; }
        }
    }

    function setPrice(uint256 _price) external payable onlyOwner {
        cost = _price;
    }

    function withdraw() external onlyOwner {
        owner().call{value: address(this).balance}("");
    }
}