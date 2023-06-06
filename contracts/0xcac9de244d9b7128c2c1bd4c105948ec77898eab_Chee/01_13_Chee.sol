// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "../lib/ERC721F/ERC721F.sol";

/**
 * @title Chee contract
 * @dev Extends ERC721F Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @simonbuidl.eth
 * 
 */

contract Chee is ERC721F {
    
    uint256 public tokenPrice = 0.005 ether; 
    uint256 public constant MAX_TOKENS=7777;
    
    uint public constant MAX_PURCHASE = 6; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas
    
    bool public saleIsActive;

    address private constant SIMON = 0x11145Fc22221d317784BD5Fdc5dd429354aa0D9C;
    address private constant C = 0xE16F00dBC2f95d29E1f07Ab3699c65342b6e1CAa;
    address private constant K = 0x6aE4595c5F2193f27DC792A79cecFFff81E9e8b2;
    address private constant L = 0xdB188c27587FA291a34F96B82400085e365A91aC;


    mapping(address => uint256) private amount;
    
    constructor() ERC721F("Chee", "CHEE") {
        setBaseTokenURI("ipfs://QmTdC5wVAV7Z43J9ubnSdJqcBxdBkibgXugSrpst2JXADr/"); 
        _safeMint(SIMON, 0);
    }

    /**
     * Mint Tokens to a wallet.
     */
    function adminMint(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 25 tokens at a time");
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
        }
    }
     /**
     * Mint Tokens to the owners reserve.
     */   
    function reserveTokens() external onlyOwner {    
        adminMint(owner(),MAX_RESERVE-1);
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * Mint your tokens here.
     */
    function mint(uint256 numberOfTokens) external payable{
        require(saleIsActive,"Sale NOT active yet");
        require(amount[msg.sender]+numberOfTokens<MAX_PURCHASE,"Purchase would exceed max mint for walet");
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");


        if (amount[msg.sender] == 0) {
            require(((tokenPrice * numberOfTokens) - tokenPrice) <= msg.value, "Ether value sent is not correct");
        } else {
            require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        }

        uint256 supply = totalSupply();
        require(supply + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, supply + i );
        }
        amount[msg.sender] = amount[msg.sender]+numberOfTokens;
    }
    
    function withdraw() public onlyOwner {
            uint256 balance = address(this).balance;
            require(balance > 0, "Insufficent balance");

        if (saleIsActive) {
            _withdraw(SIMON,(balance * 10) / 100);
            _withdraw(L,(balance * 10) / 100);
            _withdraw(K,(balance * 40) / 100);
            _withdraw(C, address(this).balance);
        } else {
            _withdraw(SIMON,(balance * 25) / 100);
            _withdraw(C, address(this).balance);
        }

    }
}