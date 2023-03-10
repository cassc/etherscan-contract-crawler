//
//
//
///////////////////////////////////////////////////
//   __  __ _ _         _  _                     //
//  |  \/  (_) |_____  | || |__ _ __ _ ___ _ _   //
//  | |\/| | | / / -_) | __ / _` / _` / -_) '_|  //
//  |_|  |_|_|_\_\___| |_||_\__,_\__, \___|_|    //
//                               |___/           //
///////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "./TheMintMemes.sol";

contract TheMintMemesBurner is Ownable {
    address public theMintMemesAddress = 0x3820e79dEb5E60F6f488fA2A62C8e190CC69BB47;
    uint256 public mintTokenId = 4;
    uint256 public mintTokenAmount = 1;

    uint256 public burnTokenId = 1; 
    uint256 public burnTokenAmount = 2;

    bool public isMintEnabled = true;

    constructor() {}

    function mint(uint256 amount) public {
        require(isMintEnabled, "Mint not enabled");
        
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(theMintMemesAddress);
        
        require(token.balanceOf(msg.sender, burnTokenId) >= burnTokenAmount * amount, "No tokens");
        require(token.isApprovedForAll(msg.sender, address(this)), "Not approved");
        token.burn(msg.sender, burnTokenId, burnTokenAmount * amount);

        token.mint(msg.sender, mintTokenId, mintTokenAmount * amount, "");
    }

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setTheMintMemesAddress(address newAddress) public onlyOwner {
        theMintMemesAddress = newAddress;
    }

    function setMintTokenId(uint256 tokenId) public onlyOwner {
        mintTokenId = tokenId;
    }

    function setMintTokenAmount(uint256 amount) public onlyOwner {
        mintTokenAmount = amount;
    }

    function setBurnTokenId(uint256 tokenId) public onlyOwner {
        burnTokenId = tokenId;
    }

     function setBurnTokenAmount(uint256 amount) public onlyOwner {
        burnTokenAmount = amount;
    }
}