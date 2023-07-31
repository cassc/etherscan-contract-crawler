/*

 ,-----.,--. ,--.,--------.,------.     ,---.         ,-----.,------. ,------.,------.,------.,--.   ,--.     ,----.     ,---.  ,--.  ,--. ,----.    
'  .--./|  | |  |'--.  .--'|  .---'    |  o ,-.      '  .--./|  .--. '|  .---'|  .---'|  .--. '\  `.'  /     '  .-./    /  O  \ |  ,'.|  |'  .-./    
|  |    |  | |  |   |  |   |  `--,     .'     /_     |  |    |  '--'.'|  `--, |  `--, |  '--' | '.    /      |  | .---.|  .-.  ||  |' '  ||  | .---. 
'  '--'\'  '-'  '   |  |   |  `---.    |  o  .__)    '  '--'\|  |\  \ |  `---.|  `---.|  | --'    |  |       '  '--'  ||  | |  ||  | `   |'  '--'  | 
 `-----' `-----'    `--'   `------'     `---'         `-----'`--' '--'`------'`------'`--'        `--'        `------' `--' `--'`--'  `--' `------'  

,-----.  ,--. ,--. ,-----.,--. ,--.    ,--.   ,--. ,-----.  ,-----. ,--.  ,--. 
|  |) /_ |  | |  |'  .--./|  .'   /    |   `.'   |'  .-.  ''  .-.  '|  ,'.|  | 
|  .-.  \|  | |  ||  |    |  .   '     |  |'.'|  ||  | |  ||  | |  ||  |' '  | 
|  '--' /'  '-'  ''  '--'\|  |\   \    |  |   |  |'  '-'  ''  '-'  '|  | `   | 
`------'  `-----'  `-----'`--' '--'    `--'   `--' `-----'  `-----' `--'  `--' 

*/

/**
 * @title  Smart Contract for the Cute & Creepy Gang : Buck Moon (airdrop)
 * @author SteelBalls
 * @notice NFT Airdrop
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BuckMoon is ERC721A, DefaultOperatorFilterer, Ownable {

    string public baseTokenURI;
    uint256 public maxTokens = 100;
    uint256 public tokenReserve = 100;

    event EtherReceived(address sender, uint256 amount);

    // Constructor
    constructor()
        ERC721A("Cute & Creepy Gang: Buck Moon", "BUCKMOON")
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

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        payable(msg.sender).transfer(address(this).balance);
    }

}