//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.1/contracts/utils/cryptography/ECDSA.sol";

interface manageToken {
    function balanceOf(address account)                                         external view returns (uint256);
    function allowance(address owner, address spender)                          external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount)    external returns (bool);
    function transfer(address recipient, uint256 amount)                        external returns (bool);
}

contract reunitPresale {

    receive() payable external {}
    using ECDSA for bytes32;

    address                         private     REUNIT_DAO;
    address                         public      OWNER;
    address                         public      REUNI_TOKEN;
    address                         public      REUNIT_TREASURY;   
    mapping(address => uint256)     public      ALLOWED_TOKENS; 
    mapping(address => uint256)     public      PARTICIPANT_LIST;
    mapping(address => uint256)     public      AMOUNT_WITHDRAWN;
    uint256                         public      MAXIMUM             =   1000000;
    uint256                         public      DEPOSITS            =   0;
    uint256                         public      PRESALE_OPEN        =   0;
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


    function isWhitelisted(bytes memory signature) public view returns (bool) {
        bytes32 messageHash     =   keccak256(abi.encodePacked(msg.sender));
        return REUNIT_DAO       ==  messageHash.toEthSignedMessageHash().recover(signature);
    }

    function updateTreasury(address reunitTreasury) public {
        require(msg.sender == OWNER, "You are not the owner");
        REUNIT_TREASURY =   reunitTreasury;   
    }

    function updateDAOSigner(address DAOSigner) public {
        require(msg.sender == OWNER, "You are not the owner");
        REUNIT_DAO  =   DAOSigner;   
    }

    function buyPresale(bytes memory signature, uint256 amount, address token) public {
        require(PRESALE_OPEN == 1, "The presale is closed");
        require(isWhitelisted(signature), "You are not whitelisted");
        require(amount > 0, "The amount must be higher than zero");
        require((amount+DEPOSITS) <= MAXIMUM, "The amount exceed the maximum authorized");
        require((ALLOWED_TOKENS[token] == 1e6 || ALLOWED_TOKENS[token] == 1e18), "The token is not allowed");
        require(manageToken(token).allowance(msg.sender,address(this)) >= amount*ALLOWED_TOKENS[token], "Please authorize this token to be deposited in this contract");
        require(manageToken(token).balanceOf(msg.sender) >= amount*ALLOWED_TOKENS[token], "It looks like you don't have the required balance");
        
        if( manageToken(token).transferFrom(msg.sender,address(this),amount*ALLOWED_TOKENS[token]) ) {
            PARTICIPANT_LIST[msg.sender] += amount;
            DEPOSITS += amount;
            emit Deposit(msg.sender, amount);
        } else {
            revert();
        }
    }

    function withdrawToTreasury(uint256 amount, address token) public {
        require(msg.sender == OWNER, "You are not the owner");
        manageToken(token).transfer(REUNIT_TREASURY,amount);
        emit WithdrawToTreasury(token, amount);
    }

    function setLock(uint256 conf, uint256 lock_option) public {
        require(msg.sender == OWNER, "You are not the owner");
        if(conf == 1)       {   if(lock_option == 1)  {   PRESALE_OPEN    =   1;  } else {    PRESALE_OPEN    =   0; }    }
        else if(conf == 2)  {   if(lock_option == 1)  {   CLAIM_OPEN      =   1;  } else {    CLAIM_OPEN      =   0; }    }
        else { CLAIM_MULTIPLIER = lock_option; }
        emit UpdateLock(conf, lock_option);
    }

    function claimReuni(address user) public {
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
        
        manageToken(REUNI_TOKEN).transfer(user,AMOUNT_TO_WITHDRAW);
        AMOUNT_WITHDRAWN[user]  +=   AMOUNT_TO_WITHDRAW;
        emit Claim(user,AMOUNT_TO_WITHDRAW);
    }

    function setReuniToken(address token, uint256 decimals) public {
        require(msg.sender == OWNER, "You are not the owner");
        REUNI_TOKEN     =   token;
        REUNI_DECIMALS  =   decimals;
    }
}