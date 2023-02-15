/*

 .o88b. db    db d888888b d88888b      .d888b.        .o88b. d8888b. d88888b d88888b d8888b. db    db       d888b   .d8b.  d8b   db  d888b          
d8P  Y8 88    88 `~~88~~' 88'          8P   8D       d8P  Y8 88  `8D 88'     88'     88  `8D `8b  d8'      88' Y8b d8' `8b 888o  88 88' Y8b      db 
8P      88    88    88    88ooooo      `Vb d8'       8P      88oobY' 88ooooo 88ooooo 88oodD'  `8bd8'       88      88ooo88 88V8o 88 88           VP 
8b      88    88    88    88~~~~~       d88C dD      8b      88`8b   88~~~~~ 88~~~~~ 88~~~      88         88  ooo 88~~~88 88 V8o88 88  ooo         
Y8b  d8 88b  d88    88    88.          C8' d8D       Y8b  d8 88 `88. 88.     88.     88         88         88. ~8~ 88   88 88  V888 88. ~8~      db 
 `Y88P' ~Y8888P'    YP    Y88888P      `888P Yb       `Y88P' 88   YD Y88888P Y88888P 88         YP          Y888P  YP   YP VP   V8P  Y888P       VP 


 db      db    db d8b   db  .d8b.  d8888b.      db   d8b   db d888888b d888888b  .o88b. db   db      d8888b.  .d88b.   .d88b.  d888888b db    db      db   db d88888b  .d8b.  d8888b. d888888b 
88      88    88 888o  88 d8' `8b 88  `8D      88   I8I   88   `88'   `~~88~~' d8P  Y8 88   88      88  `8D .8P  Y8. .8P  Y8. `~~88~~' `8b  d8'      88   88 88'     d8' `8b 88  `8D `~~88~~' 
88      88    88 88V8o 88 88ooo88 88oobY'      88   I8I   88    88       88    8P      88ooo88      88oooY' 88    88 88    88    88     `8bd8'       88ooo88 88ooooo 88ooo88 88oobY'    88    
88      88    88 88 V8o88 88~~~88 88`8b        Y8   I8I   88    88       88    8b      88~~~88      88~~~b. 88    88 88    88    88       88         88~~~88 88~~~~~ 88~~~88 88`8b      88    
88booo. 88b  d88 88  V888 88   88 88 `88.      `8b d8'8b d8'   .88.      88    Y8b  d8 88   88      88   8D `8b  d8' `8b  d8'    88       88         88   88 88.     88   88 88 `88.    88    
Y88888P ~Y8888P' VP   V8P YP   YP 88   YD       `8b8' `8d8'  Y888888P    YP     `Y88P' YP   YP      Y8888P'  `Y88P'   `Y88P'     YP       YP         YP   YP Y88888P YP   YP 88   YD    YP    
                                                                                                                                                                                                                                                                                                                                  
*/

/**
 * @title  Smart Contract for the Cute & Creepy Gang : Lunar Witch Boot Heart (airdrop)
 * @author SteelBalls
 * @notice NFT Minting
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BootyHeart is ERC721A, DefaultOperatorFilterer, Ownable {

    string public baseTokenURI;
    uint256 public maxTokens = 100;
    uint256 public tokenReserve = 100;

    // Constructor
    constructor()
        ERC721A("Cute & Creepy Gang: Lunar Witch Booty Heart", "BOOTYHEART")
    {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json")): "";
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) payable {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
        payable
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Mint from reserve allocation for team, promotions and giveaways
    function reserveTokens(address _to, uint256 _reserveAmount) external onlyOwner {        
        require(_reserveAmount <= tokenReserve, "RESERVE_EXCEEDED");
        require(totalSupply() + _reserveAmount <= maxTokens, "MAX_SUPPLY_EXCEEDED");

        _safeMint(_to, _reserveAmount);
        tokenReserve -= _reserveAmount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setTokenReserve(uint256 _newTokenReserve) external onlyOwner {
        tokenReserve = _newTokenReserve;
    }

    function remainingSupply() external view returns (uint256) {
        return maxTokens - totalSupply();
    }

    function setMaxSupply(uint256 _newMax) external onlyOwner {
        require(maxTokens > totalSupply(), "Can't set below current");
        maxTokens = _newMax;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(msg.sender).transfer(address(this).balance);
    }

}