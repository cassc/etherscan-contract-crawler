//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

/**************************************************
 * REBL.sol
 *
 * Modified for Yuser by: minato
 *
 * Special thanks goes to: tom
 ***************************************************
 */


contract REBL is Ownable, ERC721A {

    uint256 public constant REBL_PRICE = 0.05 ether;
    
    uint256 public STARTING_TIMESTAMP = 1689782400; 

    uint256 public constant REBL_QUANTITY = 8888; 

    uint256 public limitAmount = 20;

    uint256 public currentSupply;

    uint256 public whitelistTimeRange = 86400;

    uint256 public PUBLIC_STARTING_TIMESTAMP = STARTING_TIMESTAMP + whitelistTimeRange;

    string public BASE_URI;

    address public constant REBLADDRESS = 0x7dF84a83eace3e358F052Eaa3B775ecB80a24c6a; 

    mapping(address => bool) public _whitelisted;

    constructor() ERC721A("REBL District", "REBL") {} 

    function mintREBL(uint8 quantity) public payable {

        //Max supply
        require(
            currentSupply + quantity <= REBL_QUANTITY,
            "Max supply for REBL reached!"
        );

        require(
            block.timestamp >= STARTING_TIMESTAMP,
            "Sale has not started!"
        );

        if(block.timestamp <= PUBLIC_STARTING_TIMESTAMP) {
            require(_whitelisted[msg.sender] == true, "You are not whitelist");
        }

        require(quantity <= limitAmount, "Can't mint over 20 NFTs per transaction!");

        uint256 value = REBL_PRICE * quantity;

        require(msg.value >= value, "Insufficient Balance");

        _safeMint(msg.sender, quantity);

        currentSupply+= quantity;
    }

    function teamMint(address member, uint256 quantity) public onlyOwner {
        require(
            currentSupply + quantity <= REBL_QUANTITY,
            "Max supply for REBL reached!"
        );

        _safeMint(member, quantity);

        currentSupply+= quantity;
    }

    function setStartTime(uint256 startTime) external onlyOwner {
        STARTING_TIMESTAMP = startTime;
    }

    function setWhitelistTime(uint256 TimeRange) external onlyOwner {
        whitelistTimeRange = TimeRange;
    }


    function setBaseURI(string memory _baseURI) external onlyOwner {
        BASE_URI = _baseURI;
    }

    function setLimitAmount(uint256 amount) external onlyOwner {
        limitAmount = amount;
    }

    function setWhitelists(address[] calldata whitelists) external onlyOwner {
        for(uint256 i; i < whitelists.length; i++) {
        _whitelisted[whitelists[i]] = true;
        }
    }

    function setWhitelist(address whitelist) external onlyOwner {
        _whitelisted[whitelist] = true;
    }

    function withdrawFunds(address revenueAddress, uint256 amount) external onlyOwner {
        uint256 funds = address(this).balance;
        require(amount <= funds, "Insufficient funds");
        payable(revenueAddress).transfer(amount);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(BASE_URI, Strings.toString(tokenId), ".json"));
    }
}