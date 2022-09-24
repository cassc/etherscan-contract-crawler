// SPDX-License-Identifier: MIT

/**
*  _________                                           
 /   _____/____   __ __  ___________     ____   ____  
 \_____  \\__  \ |  |  \/  ___/\__  \   / ___\_/ __ \ 
 /        \/ __ \|  |  /\___ \  / __ \_/ /_/  >  ___/ 
/_______  (____  /____//____  >(____  /\___  / \___  >
        \/     \/           \/      \//_____/      \/ 
*  _________                                           
 /   _____/____   __ __  ___________     ____   ____  
 \_____  \\__  \ |  |  \/  ___/\__  \   / ___\_/ __ \ 
 /        \/ __ \|  |  /\___ \  / __ \_/ /_/  >  ___/ 
/_______  (____  /____//____  >(____  /\___  / \___  >
        \/     \/           \/      \//_____/      \/ /
/**  _________                                           
 /   _____/____   __ __  ___________     ____   ____  
 \_____  \\__  \ |  |  \/  ___/\__  \   / ___\_/ __ \ 
 /        \/ __ \|  |  /\___ \  / __ \_/ /_/  >  ___/ 
/_______  (____  /____//____  >(____  /\___  / \___  >
        \/     \/           \/      \//_____/      \/ 
 *  _________                                           
 /   _____/____   __ __  ___________     ____   ____  
 \_____  \\__  \ |  |  \/  ___/\__  \   / ___\_/ __ \ 
 /        \/ __ \|  |  /\___ \  / __ \_/ /_/  >  ___/ 
/_______  (____  /____//____  >(____  /\___  / \___  >
        \/     \/           \/      \//_____/      \/
 */

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SausageHero is ERC721A, Ownable {
    string public baseURI = "ipfs://QmXd6rKNxdxh3kDRZfuBvoUEedmvMUVBpxQmqzGz5MjgfK/";

    uint256 public immutable mintPrice = 0.001 ether;
    uint32 public immutable maxSupply = 5000;
    uint32 public immutable perTxLimit = 10;

    mapping(address => bool) public freeMinted;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    ERC721A ("Sausage Hero Official", "SH") {
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 0;
    }

    function PublicMint(uint32 amount) public payable callerIsUser{
        require(totalSupply() + amount <= maxSupply,"sold out");
        require(amount <= perTxLimit,"max 10 amount");
        if(freeMinted[msg.sender])
        {
            require(msg.value >= amount * mintPrice,"insufficient");
        }
        else 
        {
            freeMinted[msg.sender] = true;
            require(msg.value >= (amount-1) * mintPrice,"insufficient");
        }
        _safeMint(msg.sender, amount);
    }

    function getMintedFree(address addr) public view returns (bool){
        return freeMinted[addr];
    }

    function withdraw() public onlyOwner {
        uint256 sendAmount = address(this).balance;

        address h = payable(msg.sender);

        bool success;

        (success, ) = h.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
    }
}