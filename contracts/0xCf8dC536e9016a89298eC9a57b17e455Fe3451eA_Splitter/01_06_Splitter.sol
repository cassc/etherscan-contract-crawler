pragma solidity ^0.8.4;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Splitter is PaymentSplitter{

    address[] wallets = 
    [
        0x55a63Fb9011DA75103EA040657F6b7a2dD2016BB, 
        0x454097895a1717FF2E0adEBeb815EcF81B02199E,
        0xD96e4656f8906b215b2CA71A785ACE94E1Fa278b,
        0x38bDcA482446b779aD1c8713eB4486904790f9e5,
        0x6a87b76bf5BEd57A7B55F7520f4a8Ed61B7be9e4,
        0xD13594e66f993D4a53575a858ac3718bA8245868
        
    ];
        
    uint256[] sharesVAR = 
    [
        350,
        125,
        200,
        500,
        1500,
        7325

    ];



    constructor() PaymentSplitter(wallets, sharesVAR) {}

}