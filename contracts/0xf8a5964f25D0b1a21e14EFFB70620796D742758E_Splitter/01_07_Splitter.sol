pragma solidity ^0.8.4;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Splitter is PaymentSplitter{

    address[] wallets = 
    [
        0x38bDcA482446b779aD1c8713eB4486904790f9e5,
        0xd2b52CFa3c3183ed00BA0E23CBd3C856120448A8,
        0x85dBEC27Aa5185aA92e1155F7261048A81Ee4E8f,
        0x60c16AFE3c09C2cddA540350Eda83474Ec8F2f0C,
        0x120f6EBdE2B8582C569903AC76A8F150bBd0a6BD
    ];
        
    uint256[] sharesVAR = 
    [
        500,
        2000,
        6300,
        1000,
        200

    ];



    constructor() PaymentSplitter(wallets, sharesVAR) {}

}