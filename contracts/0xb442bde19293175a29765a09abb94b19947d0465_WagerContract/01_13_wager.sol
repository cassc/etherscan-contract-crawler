// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./SendToken.sol";

contract WagerContract {
    // State variables
    SENDToken public sendToken;   // Reference to the SEND token contract
    address public owner;         // Owner of the contract (presumably the deployer)
    address public ethWallet;     // Dedicated wallet for ETH
    address public sendWallet;    // Dedicated wallet for SEND tokens
    
    uint256 public maxEthWager = 1 ether;
    uint256 public maxSendWager = 300000 * 10**18;

    // Modifier to restrict certain functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Contract constructor initializes the state variables
    constructor(SENDToken _sendToken, address _ethWallet, address _sendWallet) {
        require(_ethWallet != address(0), "Invalid ETH wallet address");
        require(_sendWallet != address(0), "Invalid SEND wallet address");

        sendToken = _sendToken;
        owner = msg.sender;
        ethWallet = _ethWallet;
        sendWallet = _sendWallet;
    }

    // Function to allow users to wager with ETH
    function wagerWithETH() external payable {
        require(msg.value <= maxEthWager, "Exceeds max ETH wager");
        payable(ethWallet).transfer(msg.value);  // Transfer the wagered amount to the dedicated ETH wallet
    }

    // Function to allow users to wager with SEND tokens
    function wagerWithSEND(uint256 amount) external {
        require(amount <= maxSendWager, "Exceeds max SEND wager");
        require(sendToken.transferFrom(msg.sender, sendWallet, amount), "Transfer failed");  // Transfer the wagered amount to the dedicated SEND wallet
    }

    // Function for the owner to change the ETH wallet address
    function changeEthWallet(address _newEthWallet) external onlyOwner {
        require(_newEthWallet != address(0) && _newEthWallet != ethWallet, "Invalid address or same as current");
        ethWallet = _newEthWallet;
    }

    // Function for the owner to change the SEND wallet address
    function changeSENDWallet(address _newSendWallet) external onlyOwner {
        require(_newSendWallet != address(0) && _newSendWallet != sendWallet, "Invalid address or same as current");
        sendWallet = _newSendWallet;
    }

    // Function for the owner to change the max wager amount for ETH
    function changeMaxEthWager(uint256 _newMaxEthWager) external onlyOwner {
        maxEthWager = _newMaxEthWager;
    }

    // Function for the owner to change the max wager amount for SEND
    function changeMaxSendWager(uint256 _newMaxSendWager) external onlyOwner {
        maxSendWager = _newMaxSendWager;
    }
}