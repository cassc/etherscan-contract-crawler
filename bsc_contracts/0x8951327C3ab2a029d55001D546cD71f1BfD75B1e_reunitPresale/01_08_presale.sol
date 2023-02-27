//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.1/contracts/utils/cryptography/ECDSA.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";

contract reunitPresale {

    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    address                         private     REUNIT_DAO;
    address                         public      OWNER;
    address                         public      REUNI_TOKEN;
    address                         public      REUNIT_TREASURY;   
    mapping(address => uint256)     public      ALLOWED_TOKENS; 
    mapping(address => uint256)     public      PARTICIPANT_LIST;
    mapping(address => bool)        public      BLACKLISTED;
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
        ALLOWED_TOKENS[0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56]      =   1e18;   // BUSD
        ALLOWED_TOKENS[0x55d398326f99059fF775485246999027B3197955]      =   1e18;   // BUSD-T
    }


    function isWhitelisted(bytes memory signature, address user) public view returns (bool) {
        bytes32 messageHash     =   keccak256(abi.encodePacked(user));
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

    function addToBlacklist(address user, bool value) public {
        require(msg.sender == OWNER, "You are not the owner");
        BLACKLISTED[user]   =   value;
    }

    function buyPresale(bytes memory signature, uint256 amount, address token) public {
        require(!BLACKLISTED[msg.sender], "You are blacklisted");
        require(PRESALE_OPEN == 1, "The presale is closed");
        require(isWhitelisted(signature, msg.sender), "You are not whitelisted");
        require(amount > 0, "The amount must be higher than zero");
        require((amount+DEPOSITS) <= MAXIMUM, "The amount exceed the maximum authorized");
        require((ALLOWED_TOKENS[token] == 1e6 || ALLOWED_TOKENS[token] == 1e18), "The token is not allowed");

        PARTICIPANT_LIST[msg.sender] += amount;
        DEPOSITS += amount;
        IERC20(token).safeTransferFrom(msg.sender,address(this),amount*ALLOWED_TOKENS[token]);
        emit Deposit(msg.sender, amount);
    }

    function withdrawToTreasury(uint256 amount, address token) public {
        require(msg.sender == OWNER, "You are not the owner");
        IERC20(token).safeTransfer(REUNIT_TREASURY,amount);
        emit WithdrawToTreasury(token, amount);
    }

    function setLock(uint256 conf, uint256 lock_option) public {
        require(msg.sender == OWNER, "You are not the owner");
        if(conf == 1)       {   if(lock_option == 1)  {   PRESALE_OPEN    =   1;  } else {    PRESALE_OPEN    =   0; }    }
        else if(conf == 2)  {   if(lock_option == 1)  {   CLAIM_OPEN      =   1;  } else {    CLAIM_OPEN      =   0; }    }
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