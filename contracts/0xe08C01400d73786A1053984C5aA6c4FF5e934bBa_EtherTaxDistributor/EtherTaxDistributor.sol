/**
 *Submitted for verification at Etherscan.io on 2023-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EtherTaxDistributor
 * @dev A contract that automatically distributes received Ether to three predefined wallets.
 */
contract EtherTaxDistributor {
    address public owner;
    address payable public wallet1;
    address payable public wallet2;
    address payable public wallet3;
    bool public distributionEnabled;

    event FundsReceived(address sender, uint256 amount);
    event ManualWithdrawal(uint256 amountToWallet1, uint256 amountToWallet2, uint256 amountToWallet3);
    event AutomatedWithdrawal(uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(
        address payable _wallet1,
        address payable _wallet2,
        address payable _wallet3
    ) payable {
        // Ensure valid wallet addresses are provided
        require(_wallet1 != address(0) && _wallet2 != address(0) && _wallet3 != address(0), "Invalid wallet address");

        owner = msg.sender;
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        wallet3 = _wallet3;

        distributionEnabled = true;
    }

    /**
     * @dev Fallback function to receive Ether
     */
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    /**
     * @dev Modifier to restrict a function to be called only by the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    /**
     * @dev Withdraw any excess Ether from the contract
     */
    function withdrawExcessFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to withdraw excess funds.");
    }

    /**
     * @dev Set wallet addresses to distribute funds
     */
    function setWallets(address payable _newWallet1, address payable _newWallet2, address payable _newWallet3) public onlyOwner {
        require(_newWallet1!= address(0), "Invalid wallet1 address");
        require(_newWallet2!= address(0), "Invalid wallet2 address");
        require(_newWallet3!= address(0), "Invalid wallet3 address");
        wallet1 = _newWallet1;
        wallet2 = _newWallet2;
        wallet3 = _newWallet3;
    }

    function setWallet1(address payable _newWallet) public onlyOwner {
        require(_newWallet != address(0), "Invalid wallet address");
        wallet1 = _newWallet;
    }

    function setWallet2(address payable _newWallet) public onlyOwner {
        require(_newWallet != address(0), "Invalid wallet address");
        wallet2 = _newWallet;
    }

    function setWallet3(address payable _newWallet) public onlyOwner {
        require(_newWallet != address(0), "Invalid wallet address");
        wallet3 = _newWallet;
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    /**
     * @dev Manually trigger the distribution of funds to the predefined wallets
     */
    function manualWithdrawal() public {
        require(distributionEnabled, "Ether distribution is currently disabled");
        distributeFunds();
        emit ManualWithdrawal(address(this).balance, address(this).balance, address(this).balance);
    }

    /**
     * @dev Distribute funds to the predefined wallets
     */
    function distributeFunds() private {
        require(distributionEnabled, "Ether distribution is currently disabled");
        uint256 thisBalance = address(this).balance;

        uint256 amountToWallet1 = (thisBalance * 3685) / 10000;
        uint256 amountToWallet2 = (thisBalance * 3300) / 10000;
        uint256 amountToWallet3 = (thisBalance * 3015) / 10000;

        // Disable distribution before transferring Ether to avoid reentrancy attacks
        distributionEnabled = false;

        wallet1.transfer(amountToWallet1);
        wallet2.transfer(amountToWallet2);
        wallet3.transfer(amountToWallet3);

        // Enable distribution again for the next cycle
        distributionEnabled = true;

        emit ManualWithdrawal(amountToWallet1, amountToWallet2, amountToWallet3);
    }

    /**
     * @dev Change the contract owner
     * @param newOwner The new owner's address
     */
    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @dev Destroy the contract and send any remaining balance to the contract owner (multisig)
     */
    function destroyContract() public onlyOwner {
        selfdestruct(payable(owner));
    }
}