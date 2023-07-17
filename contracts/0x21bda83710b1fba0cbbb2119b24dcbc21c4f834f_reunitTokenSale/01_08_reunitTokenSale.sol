//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.1/contracts/utils/cryptography/ECDSA.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";

contract reunitTokenSale {

    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    address                         public      OWNER;
    address                         public      REUNI_TOKEN;
    address                         public      REUNIT_TREASURY;   
    mapping(address => uint256)     public      ALLOWED_TOKENS; 
    mapping(address => uint256)     public      PARTICIPANT_LIST;
    mapping(address => bool)        public      BLACKLISTED;
    mapping(address => uint256)     public      AMOUNT_WITHDRAWN;
    uint256                         public      MAXIMUM             =   1000000;
    uint256                         public      DEPOSITS            =   0;
    uint256                         public      SALE_OPEN           =   0;
    uint256                         public      CLAIM_OPEN          =   0;
    uint256                         public      REUNI_DECIMALS      =   1e18;
    uint256                         public      CLAIM_MULTIPLIER    =   0;
    
    event Deposit(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event WithdrawToTreasury(address indexed token, uint256 amount);
    event UpdateLock(uint256 conf, uint256 value);

    constructor() {
        OWNER       =   msg.sender;
        ALLOWED_TOKENS[0xdAC17F958D2ee523a2206206994597C13D831ec7]      =   1e6;      // USDT
        ALLOWED_TOKENS[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48]      =   1e6;      // USDC
        ALLOWED_TOKENS[0x4Fabb145d64652a948d72533023f6E7A623C7C53]      =   1e18;     // BUSD
        ALLOWED_TOKENS[0x6B175474E89094C44Da98b954EedeAC495271d0F]      =   1e18;     // DAI
    }

    function transferOwner(address new_owner) public {
        require(msg.sender == OWNER, "You are not the owner");
        OWNER   =   new_owner;
    }

    function updateTreasury(address reunitTreasury) public {
        require(msg.sender == OWNER, "You are not the owner");
        REUNIT_TREASURY =   reunitTreasury;   
    }

    function addToBlacklist(address user, bool value) public {
        require(msg.sender == OWNER, "You are not the owner");
        BLACKLISTED[user]   =   value;
    }

    function buySale(uint256 amount, address token) public {
        require(!BLACKLISTED[msg.sender], "You are blacklisted");
        require(SALE_OPEN == 1, "The presale is closed");
        require(amount > 0, "The amount must be higher than zero");
        require((amount+DEPOSITS) <= MAXIMUM, "The amount exceed the maximum authorized");
        require((ALLOWED_TOKENS[token] == 1e6 || ALLOWED_TOKENS[token] == 1e18), "The token is not allowed");

        PARTICIPANT_LIST[msg.sender] += amount;
        DEPOSITS += amount;
        // Price set at $2 = amount*2
        IERC20(token).safeTransferFrom(msg.sender,address(this),amount*2*ALLOWED_TOKENS[token]);
        emit Deposit(msg.sender, amount);
    }

    function withdrawToTreasury(uint256 amount, address token) public {
        require(msg.sender == OWNER, "You are not the owner");
        IERC20(token).safeTransfer(REUNIT_TREASURY,amount);
        emit WithdrawToTreasury(token, amount);
    }

    function setLock(uint256 conf, uint256 lock_option) public {
        require(msg.sender == OWNER, "You are not the owner");
        if(conf == 1)       {   if(lock_option == 1)  {   SALE_OPEN     =   1;  } else {    SALE_OPEN   =   0; }    }
        else if(conf == 2)  {   if(lock_option == 1)  {   CLAIM_OPEN    =   1;  } else {    CLAIM_OPEN  =   0; }    }
        else { CLAIM_MULTIPLIER = lock_option; }
        emit UpdateLock(conf, lock_option);
    }

    function claimReuni() public {
        address user    =   msg.sender;
        require(CLAIM_OPEN  == 1, "The claim period is not open");
        require(PARTICIPANT_LIST[user] > 0, "You have nothing to claim");
        uint256 AUTHORIZED_AMOUNT;
        
        if(CLAIM_MULTIPLIER == 100) {
            AUTHORIZED_AMOUNT   =   PARTICIPANT_LIST[user]*REUNI_DECIMALS;
        } else {
            AUTHORIZED_AMOUNT   =   PARTICIPANT_LIST[user]*REUNI_DECIMALS/100*CLAIM_MULTIPLIER;
        }

        require(AMOUNT_WITHDRAWN[user] < AUTHORIZED_AMOUNT, "You have reached the maximum claimable amount");
        uint256 AMOUNT_TO_WITHDRAW  =   AUTHORIZED_AMOUNT-AMOUNT_WITHDRAWN[user];
        
        AMOUNT_WITHDRAWN[user]  +=   AMOUNT_TO_WITHDRAW;
        IERC20(REUNI_TOKEN).safeTransfer(user,AMOUNT_TO_WITHDRAW);
        
        emit Claim(user,AMOUNT_TO_WITHDRAW);
    }

    function setReuniToken(address token, uint256 decimals) public {
        require(msg.sender == OWNER, "You are not the owner");
        REUNI_TOKEN     =   token;
        REUNI_DECIMALS  =   decimals;
    }
}