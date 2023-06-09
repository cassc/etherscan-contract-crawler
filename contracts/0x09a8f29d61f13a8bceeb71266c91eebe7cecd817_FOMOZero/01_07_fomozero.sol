// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FOMOZero is ERC20, ReentrancyGuard, Ownable {
    uint256 public constant TOTAL_SUPPLY = 21000000 * (10 ** 18);
    
    uint256 public constant CYCLE = 10 seconds;

    uint256 public constant PRIZE_CYCLE = 86400 seconds;
    uint256 public constant MAX_CLAIMS = 10240 * (10 ** 18);
    
    uint256 public  RATE = 1024 * (10 ** 18);

    uint256 public mintAmount;

    uint256 public nextMintRate;

    uint256 public resetTime;
    
    mapping(address => uint256) public totalClaimed;

    uint256 public totalMinted;

    address public lastMinter;

    uint256 public lastMinteTime;

    constructor() ERC20("FOMOZero", "FZ") {
        _mint(msg.sender, TOTAL_SUPPLY / 10); // Mint 10% of total supply to deployer to add Liquidity
        resetTime = block.timestamp + CYCLE;
        totalMinted = TOTAL_SUPPLY / 10;
    }

    function getPrize() public {
        require(msg.sender == lastMinter,"NOT LAST MINTER"); 
        require(totalMinted < TOTAL_SUPPLY,"Exceeds total supply"); 
        //if no one mint for morethen 1 day
        require(block.timestamp >= lastMinteTime + PRIZE_CYCLE,"NOT PRIZE TIME"); 
        mintAmount = TOTAL_SUPPLY - totalMinted ;
        _mint(msg.sender, mintAmount);
        totalMinted = TOTAL_SUPPLY;
   }



function halving() public onlyOwner {
        if(totalMinted >= 10500000 * (10 ** 18) && totalMinted < 15750000 * (10 ** 18)){
            RATE = 512 * (10 ** 18);
        }else if(totalMinted >= 15750000 * (10 ** 18) && totalMinted < 18375000 * (10 ** 18)){
            RATE = 256 * (10 ** 18);
        }else if(totalMinted >= 18375000 * (10 ** 18)){
            RATE = 128 * (10 ** 18);
        }
   }



    receive() external payable nonReentrant {
        require(totalClaimed[msg.sender] < MAX_CLAIMS, "Maximum number of claims reached");
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        if(block.timestamp >= resetTime){
          //reset every 10 seconds
          nextMintRate = 1 ;
          mintAmount =RATE;
        }
        mintAmount = mintAmount/nextMintRate ;
        require(totalMinted + mintAmount <= TOTAL_SUPPLY, "Exceeds total supply");
        _mint(msg.sender, mintAmount);

        nextMintRate = nextMintRate*2;
        resetTime = block.timestamp + CYCLE;
        totalClaimed[msg.sender] += mintAmount;
        totalMinted += mintAmount; 
        lastMinter=msg.sender;
        lastMinteTime =block.timestamp;
    }


    function renounceOwnership() public onlyOwner override {
        super.renounceOwnership();
    }
}