//
//
//
////////////////////////////////////////////////////////////////////////////////////////
// __________        .__                        ___ ___                     .__       //
// \______   \_____  |__| ____   ___________   /   |   \  ____  ______ ____ |  |__    //
//  |       _/\__  \ |  |/    \_/ __ \_  __ \ /    ~    \/  _ \/  ___// ___\|  |  \   //
//  |    |   \ / __ \|  |   |  \  ___/|  | \/ \    Y    (  <_> )___ \\  \___|   Y  \  //
//  |____|_  /(____  /__|___|  /\___  >__|     \___|_  / \____/____  >\___  >___|  /  //
//         \/      \/        \/     \/               \/            \/     \/     \/   //
////////////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "./EditionsByRainerHosch.sol";

contract EditionsByRainerHoschJordanMinter is Ownable {
    address public rainerHoschEditionsAddress = 0xadB4eCDABeeD8eBC69fA02F60cD43e8A2ce511e1;
    
    uint256 public mintTokenId = 5;

    uint256 public maxSupply = 32292;
    uint256 public currentSupply = 0;

    uint256 public mintLimit = 10;
    
    bool public isMintEnabled = true;
    
    uint256 public mintTokenPrice = 23000000 gwei;
    
    uint[] public burnAmount = [2, 5, 10, 20, 52, 69, 90, 111, 123, 321]; 

    constructor() {}

    function mint(uint256 amount) public payable{
        require(isMintEnabled, "Mint not enabled");
        require(amount <= mintLimit && burnAmount[amount-1] <= maxSupply - currentSupply, "Not enough Supply");

        EditionsByRainerHosch token = EditionsByRainerHosch(rainerHoschEditionsAddress);
        require(currentSupply < maxSupply, "Max supply reached");
        require(msg.value >= mintTokenPrice * amount, "Not enough funds");

        address[] memory senderArray = new address[](1);
        senderArray[0] = msg.sender;

        uint256[] memory mintTokenIdArray = new uint256[](1);
        mintTokenIdArray[0] = mintTokenId;

        uint256[] memory mintTokenAmountArray = new uint256[](1);
        mintTokenAmountArray[0] = amount;
        
        token.airdrop(senderArray, mintTokenIdArray, mintTokenAmountArray);
        //add to currentSupply
        currentSupply += amount;
        
        //remove from maxSupply
        maxSupply -= burnAmount[amount-1];
        
    }

    function returnOwnership() public onlyOwner {
        EditionsByRainerHosch token = EditionsByRainerHosch(rainerHoschEditionsAddress);
        token.transferOwnership(msg.sender);
    }

    function setMintTokenPrice(uint256 price) public onlyOwner {
        mintTokenPrice = price;
    }

    function setMintLimit(uint256 limit) public onlyOwner {
        mintLimit = limit;
    }

    function setMaxSupply(uint256 max) public onlyOwner {
        maxSupply = max;
    }

    function setCurrentSupply(uint256 current) public onlyOwner {
        currentSupply = current;
    }

    function setIsMintEnabled(bool isEnabled) public onlyOwner {
        isMintEnabled = isEnabled;
    }

    function setBurnAmount(uint[] memory burnAmountArray) onlyOwner public {
        burnAmount = burnAmountArray;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setRainerHoschEditionsAddress(address newAddress) public onlyOwner {
        rainerHoschEditionsAddress = newAddress;
    }

    function setMintTokenId(uint256 tokenId) public onlyOwner {
        mintTokenId = tokenId;
    }
}