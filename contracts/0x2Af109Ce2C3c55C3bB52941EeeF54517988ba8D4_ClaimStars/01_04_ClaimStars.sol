// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract ClaimStars {

    address private constant NFTCONTRACT = 0x5E36F2C564b16697cd6354FD9CA19E707E923a1a;

    address private constant PITBOSSCONTRACT = 0x8E19Be131d16Afd9c00CfFF6A8a60B098E6ab24f;
    
    bool private claimActive = true;

    IERC721 nftToken = IERC721(NFTCONTRACT);
    IERC1155 pitboss = IERC1155(PITBOSSCONTRACT);

    address private _owner;
    address private _manager;

    uint256 private tokenId = 2000;
    uint256 private immutable totalTokens = 3000;

    mapping(address => bool) private claims;
   
    constructor(address manager) {
        _owner = msg.sender;
        _manager = manager;
    }

    function toogleSale() public  {
        require(msg.sender == _owner, "Only the owner can toggle the claim");
        claimActive = !claimActive;
    }

    function getAmountToClaim(address account) public view returns (uint256 amount) {
        require(claimActive, "Claim is not active");
        require(tokenId <= totalTokens, "Claim is over");

        amount = IERC1155(PITBOSSCONTRACT).balanceOf(account, 0);
      
        require(amount > 0 && claims[account] == false, "Error: You does not have PitBoss to Claim.");
        
        return amount;
      
    }

    function claim() external {
        require(claimActive, "Claim is not active");
        require(tokenId <= totalTokens, "Claim is over");
        
        uint256 amount = IERC1155(PITBOSSCONTRACT).balanceOf(msg.sender, 0);

        require(amount > 0 && claims[msg.sender] == false, "Error: You does not have PitBoss to Claim.");

        for (uint256 i = 0; i < amount; i++) {
            nftToken.transferFrom(_manager, msg.sender, tokenId);
            tokenId = tokenId + 1;
        }

        claims[msg.sender] = true;
   
    }

}